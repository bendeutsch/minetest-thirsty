--[[

Core functions for Thirsty.

See init.lua for license.

]]

function thirsty.on_joinplayer(player)
    local name = player:get_player_name()
    -- default entry for new players
    if not thirsty.players[name] then
        local pos = player:getpos()
        thirsty.players[name] = {
            hydro = 20,
            last_pos = math.floor(pos.x) .. ':' .. math.floor(pos.z),
            time_in_pos = 0.0,
            pending_dmg = 0.0,
            thirst_factor = 1.0,
        }
    end
    thirsty.hud_init(player)
end

function thirsty.on_dieplayer(player)
    local name = player:get_player_name()
    local pl   = thirsty.players[name]
    -- reset after death
    pl.hydro = 20
    pl.pending_dmg = 0.0
    pl.thirst_factor = 1.0
end

--[[

Getters, setters and such

]]

-- internal version, for speed
function thirsty._drink(pl, value, max)
    -- test whether we're not *above* max;
    -- this function should not remove any overhydration 
    if pl.hydro < max then
        pl.hydro = math.min(pl.hydro + value, max)
        --print("Drinking by "..value.." to "..pl.hydro)
        return true
    end
    return false
end

function thirsty.drink(player, value, max)
    -- if max is not specified, assume 20
    if not max then
        max = 20
    end
    local name = player:get_player_name()
    local pl = thirsty.players[name]
    return thirsty._drink(pl, value, max)
end

function thirsty.get_hydro(player)
    local name = player:get_player_name()
    local pl = thirsty.players[name]
    return pl.hydro
end

function thirsty.set_thirst_factor(player, factor)
    local name = player:get_player_name()
    local pl = thirsty.players[name]
    pl.thirst_factor = factor
end

function thirsty.get_thirst_factor(player)
    local name = player:get_player_name()
    local pl = thirsty.players[name]
    return pl.thirst_factor
end

--[[

Main Loop (Tier 0)

]]

function thirsty.main_loop(dtime)
    -- get thirsty
    thirsty.time_next_tick = thirsty.time_next_tick - dtime
    while thirsty.time_next_tick < 0.0 do
        -- time for thirst
        thirsty.time_next_tick = thirsty.time_next_tick + thirsty.config.tick_time
        for _,player in ipairs(minetest.get_connected_players()) do

            if player:get_hp() <= 0 then
                -- dead players don't get thirsty, or full for that matter :-P
                break
            end

            local name = player:get_player_name()
            local pos  = player:getpos()
            local pl = thirsty.players[name]

            -- how long have we been standing "here"?
            -- (the node coordinates in X and Z should be enough)
            local pos_hash = math.floor(pos.x) .. ':' .. math.floor(pos.z)
            if pl.last_pos == pos_hash then
                pl.time_in_pos = pl.time_in_pos + thirsty.config.tick_time
            else
                -- you moved!
                pl.last_pos = pos_hash
                pl.time_in_pos = 0.0
            end
            local pl_standing = pl.time_in_pos > thirsty.config.stand_still_for_drink
            local pl_afk      = pl.time_in_pos > thirsty.config.stand_still_for_afk
            --print("Standing: " .. (pl_standing and 'true' or 'false' ) .. ", AFK: " .. (pl_afk and 'true' or 'false'))

            pos.y = pos.y + 0.1
            local node = minetest.get_node(pos)
            local drink_per_second = thirsty.config.regen_from_node[node.name] or 0

            -- fountaining (uses pos, slight changes ok)
            for k, fountain in pairs(thirsty.fountains) do
                local dx = fountain.pos.x - pos.x
                local dy = fountain.pos.y - pos.y
                local dz = fountain.pos.z - pos.z
                local dist2 = dx * dx + dy * dy + dz * dz
                local fdist = fountain.level * thirsty.config.fountain_distance_per_level -- max 100 nodes radius
                --print (string.format("Distance from %s (%d): %f out of %f", k, fountain.level, math.sqrt(dist2), fdist ))
                if dist2 < fdist * fdist then
                    -- in range, drink as if standing (still) in water
                    drink_per_second = math.max(thirsty.config.regen_from_fountain or 0, drink_per_second)
                    pl_standing = true
                    break -- no need to check the other fountains
                end
            end

            -- amulets
            -- TODO: I *guess* we need to optimize this, but I haven't
            --       measured it yet. No premature optimizations!
            local pl_inv = player:get_inventory()
            local extractor_max = 0.0
            local injector_max = 0.0
            local container_not_full = nil
            local container_not_empty = nil
            local inv_main = player:get_inventory():get_list('main')
            for i, itemstack in ipairs(inv_main) do
                local name = itemstack:get_name()
                local injector_this = thirsty.config.injection_for_item[name]
                if injector_this and injector_this > injector_max then
                    injector_max = injector_this
                end
                local extractor_this = thirsty.config.extraction_for_item[name]
                if extractor_this and extractor_this > extractor_max then
                    extractor_max = extractor_this
                end
                if thirsty.config.container_capacity[name] then
                    local wear = itemstack:get_wear()
                    -- can be both!
                    if wear == 0 or wear > 1 then
                        container_not_full = { i, itemstack }
                    end
                    if wear > 0 and wear < 65534 then
                        container_not_empty = { i, itemstack }
                    end
                end
            end
            if extractor_max > 0.0 and container_not_full then
                local i = container_not_full[1]
                local itemstack = container_not_full[2]
                local capacity = thirsty.config.container_capacity[itemstack:get_name()]
                local wear = itemstack:get_wear()
                if wear == 0 then wear = 65535.0 end
                local drink = extractor_max * thirsty.config.tick_time
                local drinkwear = drink / capacity * 65535.0
                wear = wear - drinkwear
                if wear < 1 then wear = 1 end
                itemstack:set_wear(wear)
                player:get_inventory():set_stack("main", i, itemstack)
            end
            if injector_max > 0.0 and container_not_empty then
                local i = container_not_empty[1]
                local itemstack = container_not_empty[2]
                local capacity = thirsty.config.container_capacity[itemstack:get_name()]
                local wear = itemstack:get_wear()
                if wear == 0 then wear = 65535.0 end
                local drink = injector_max * thirsty.config.tick_time
                local drink_missing = 20 - pl.hydro
                drink = math.max(math.min(drink, drink_missing), 0)
                local drinkwear = drink / capacity * 65535.0
                wear = wear + drinkwear
                if wear > 65534 then wear = 65534 end
                itemstack:set_wear(wear)
                thirsty._drink(pl, drink, 20)
                player:get_inventory():set_stack("main", i, itemstack)
            end


            if drink_per_second > 0 and pl_standing then
                -- Drinking from the ground won't give you more than max
                thirsty._drink(pl, drink_per_second * thirsty.config.tick_time, 20)
                --print("Raising hydration by "..(drink_per_second*thirsty.config.tick_time).." to "..pl.hydro)
            else
                if not pl_afk then
                    -- only get thirsty if not AFK
                    local amount = thirsty.config.thirst_per_second * thirsty.config.tick_time * pl.thirst_factor
                    pl.hydro = pl.hydro - amount
                    if pl.hydro < 0 then pl.hydro = 0 end
                    --print("Lowering hydration by "..amount.." to "..pl.hydro)
                end
            end


            -- should we only update the hud on an actual change?
            thirsty.hud_update(player, pl.hydro)

            -- damage, if enabled
            if minetest.setting_getbool("enable_damage") then
                -- maybe not the best way to do this, but it does mean
                -- we can do anything with one tick loop
                if pl.hydro <= 0.0 and not pl_afk then
                    pl.pending_dmg = pl.pending_dmg + thirsty.config.damage_per_second * thirsty.config.tick_time
                    --print("Pending damage at " .. pl.pending_dmg)
                    if pl.pending_dmg > 1.0 then
                        local dmg = math.floor(pl.pending_dmg)
                        pl.pending_dmg = pl.pending_dmg - dmg
                        player:set_hp( player:get_hp() - dmg )
                    end
                else
                    -- forget any pending damage when not thirsty
                    pl.pending_dmg = 0.0
                end
            end
        end -- for players

        -- check fountains for expiration
        for k, fountain in pairs(thirsty.fountains) do
            fountain.time_until_check = fountain.time_until_check - thirsty.config.tick_time
            if fountain.time_until_check <= 0 then
                -- remove fountain, the abm will set it again
                --print("Removing fountain at " .. k)
                thirsty.fountains[k] = nil
            end
        end

    end
end

--[[

Stash: persist the hydration values in a file in the world directory.

If this is missing or corrupted, then no worries: nobody's thirsty ;-)

]]

function thirsty.read_stash()
    local filename = minetest.get_worldpath() .. "/" .. thirsty.config.stash_filename
    local file, err = io.open(filename, "r")
    if not file then
        -- no problem, it's just not there
        -- TODO: or parse err?
        return
    end
    thirsty.players = {}
    for line in file:lines() do
        if string.match(line, '^%-%-') then
            -- comment, ignore
        elseif string.match(line, '^P [%d.]+ [%d.]+ .+') then
            -- player line
            -- is matching again really the best solution?
            local hydro, dmg, name = string.match(line, '^P ([%d.]+) ([%d.]+) (.+)')
            thirsty.players[name] = {
                hydro = tonumber(hydro),
                last_pos = '0:0', -- not true, but no matter
                time_in_pos = 0.0,
                pending_dmg = tonumber(dmg),
                thirst_factor = 1.0,
            }
        end
    end
    file:close()
end

function thirsty.write_stash()
    local filename = minetest.get_worldpath() .. "/" .. thirsty.config.stash_filename
    local file, err = io.open(filename, "w")
    if not file then
        minetest.log("error", "Thirsty: could not write " .. thirsty.config.stash_filename .. ": " ..err)
        return
    end
    file:write('-- Stash file for Minetest mod [thirsty] --\n')
    -- write players:
    -- P <hydro> <pending_dmg> <name>
    file:write('-- Player format: "P <hydro> <pending damage> <name>"\n')
    for name, data in pairs(thirsty.players) do
        file:write("P " .. data.hydro .. " " .. data.pending_dmg .. " " .. name .. "\n")
    end
    file:close()
end

--[[

General handler

Most tools, nodes and craftitems use the same code, so here it is:

]]

function thirsty.drink_handler(player, itemstack, node)
    local pl = thirsty.players[player:get_player_name()]
    local old_hydro = pl.hydro

    -- selectors, always true, to make the following code easier
    local item_name = itemstack and itemstack:get_name() or ':'
    local node_name = node      and node.name            or ':'

    if thirsty.config.node_drinkable[node_name] then
        -- we found something to drink!
        local cont_level = thirsty.config.drink_from_container[item_name] or 0
        local node_level = thirsty.config.drink_from_node[node_name] or 0
        -- drink until level
        local level = math.max(cont_level, node_level)
        --print("Drinking to level " .. level)
        if pl.hydro < level then
            pl.hydro = level
        end

        -- fill container, if applicable
        if thirsty.config.container_capacity[item_name] then
            --print("Filling a " .. item_name .. " to " .. thirsty.config.container_capacity[item_name])
            itemstack:set_wear(1) -- "looks full"
        end

    elseif thirsty.config.container_capacity[item_name] then
        -- drinking from a container
        if itemstack:get_wear() ~= 0 then
            local capacity = thirsty.config.container_capacity[item_name]
            local hydro_missing = 20 - pl.hydro;
            if hydro_missing > 0 then
                local wear_missing = hydro_missing / capacity * 65535.0;
                local wear         = itemstack:get_wear()
                local new_wear     = math.ceil(math.max(wear + wear_missing, 1))
                if (new_wear > 65534) then
                    wear_missing = 65534 - wear
                    new_wear = 65534
                end
                itemstack:set_wear(new_wear)
                if wear_missing > 0 then -- rounding glitches?
                    thirsty._drink(pl, wear_missing * capacity / 65535.0, 20)
                end
            end
        end
    end

    -- update HUD if value changed
    if pl.hydro ~= old_hydro then
        thirsty.hud_update(player, pl.hydro)
    end
end

--[[

Adapters for drink_handler to on_use and on_rightclick slots.
These close over the next handler to call in a chain, if desired.

]]

function thirsty.on_use( old_on_use )
    return function(itemstack, player, pointed_thing)
        local node = nil
        if pointed_thing and pointed_thing.type == 'node' then
            node = minetest.get_node(pointed_thing.under)
        end

        thirsty.drink_handler(player, itemstack, node)

        -- call original on_use, if provided
        if old_on_use ~= nil then
            return old_on_use(itemstack, player, pointed_thing)
        else
            return itemstack
        end
    end
end

function thirsty.on_rightclick( old_on_rightclick )
    return function(pos, node, player, itemstack, pointed_thing)

        thirsty.drink_handler(player, itemstack, node)

        -- call original on_rightclick, if provided
        if old_on_rightclick ~= nil then
            return old_on_rightclick(pos, node, player, itemstack, pointed_thing)
        else
            return itemstack
        end
    end
end

--[[

Adapter to add "drink_handler" to any item (node, tool, craftitem).

]]

function thirsty.augment_item_for_drinking( itemname, level )
    local new_definition = {}
    -- we need to be able to point at the water
    new_definition.liquids_pointable = true
    -- call closure generator with original on_use handler
    new_definition.on_use = thirsty.on_use(
        minetest.registered_items[itemname].on_use
    )
    -- overwrite the node definition with almost the original
    minetest.override_item(itemname, new_definition)

    -- add configuration settings
    thirsty.config.drink_from_container[itemname] = level
end

function thirsty.fountain_abm(pos, node)
    local fountain_count = 0
    local water_count = 0
    local total_count = 0
    for y = 0, thirsty.config.fountain_height do
        for x = -y, y do
            for z = -y, y do
                local n = minetest.get_node({
                    x = pos.x + x,
                    y = pos.y - y + 1, -- start one *above* the fountain
                    z = pos.z + z
                })
                if n then
                    --print(string.format("%s at %d:%d:%d", n.name, pos.x+x, pos.y-y+1, pos.z+z))
                    total_count = total_count + 1
                    local type = thirsty.config.fountain_type[n.name] or ''
                    if type == 'f' then
                        fountain_count = fountain_count + 1
                    elseif type == 'w' then
                        water_count = water_count + 1
                    end
                end
            end
        end
    end
    local level = math.min(thirsty.config.fountain_max_level, math.min(fountain_count, water_count))
    --print(string.format("Fountain (%d): %d + %d / %d", level, fountain_count, water_count, total_count))
    thirsty.fountains[string.format("%d:%d:%d", pos.x, pos.y, pos.z)] = {
        pos = { x=pos.x, y=pos.y, z=pos.z },
        level = level,
        -- time until check is 20 seconds, or twice the average
        -- time until the abm ticks again. Should be enough.
        time_until_check = 20,
    }
end
