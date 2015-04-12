--[[

Thirsty mod [thirsty]
==========================

A mod that adds a "thirst" mechanic, similar to hunger.

Copyright (C) 2015 Ben Deutsch <ben@bendeutsch.de>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
USA

]]

-- the main module variable
thirsty = {

    -- Configuration variables
    tick_time = 0.5,
    thirst_per_second = 1.0 / 20.0,
    damage_per_second = 1.0 / 10.0, -- when out of thirst bar
    stand_still_for_drink = 1.0,
    stand_still_for_afk = 120.0, -- 2 Minutes

    drink_from_node = {
        -- value: thirst regen per second
        ['default:water_source'] = 0.5,
        ['default:water_flowing'] = 0.5,
    },

    -- the players' values
    players = {
        --[[
        name = {
            thirst = 20,
            last_pos = '-10:3',
            time_in_pos = 0.0,
            pending_dmg = 0.0,
        }
        --]]
    },

    stash_filename = 'thirsty.mt',

    -- general settings
    time_next_tick = 0.0,
}

thirsty.time_next_tick = thirsty.tick_time

hb.register_hudbar('thirst', 0xffffff, "Thirst", {
    bar = 'thirsty_hudbars_bar.png',
    icon = 'thirsty_cup_100_16.png'
}, 20, 20, false)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    -- default entry for new players
    if not thirsty.players[name] then
        local pos = player:getpos()
        thirsty.players[name] = {
            thirst = 20,
            last_pos = math.floor(pos.x) .. ':' .. math.floor(pos.z),
            time_in_pos = 0.0,
            pending_dmg = 0.0,
        }
    end
    hb.init_hudbar(player, 'thirst', thirsty.players[name].thirst, 20, false)
end)

minetest.register_globalstep(function(dtime)
    -- get thirsty
    thirsty.time_next_tick = thirsty.time_next_tick - dtime
    while thirsty.time_next_tick < 0.0 do
        -- time for thirst
        thirsty.time_next_tick = thirsty.time_next_tick + thirsty.tick_time
        for _,player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local pos  = player:getpos()
            local pl = thirsty.players[name]

            -- how long have we been standing "here"?
            -- (the node coordinates in X and Z should be enough)
            local pos_hash = math.floor(pos.x) .. ':' .. math.floor(pos.z)
            if pl.last_pos == pos_hash then
                pl.time_in_pos = pl.time_in_pos + thirsty.tick_time
            else
                -- you moved!
                pl.last_pos = pos_hash
                pl.time_in_pos = 0.0
            end

            pos.y = pos.y + 0.1
            local node = minetest.get_node(pos)
            local drink_per_second = thirsty.drink_from_node[node.name]
            if drink_per_second ~= nil and drink_per_second > 0 and pl.time_in_pos > thirsty.stand_still_for_drink then
                pl.thirst = pl.thirst + drink_per_second * thirsty.tick_time
                -- Drinking from the ground won't give you more than max
                if pl.thirst > 20 then pl.thirst = 20 end
                --print("Raising thirst by "..(drink_per_second*thirsty.tick_time).." to "..pl.thirst)
            else
                if pl.time_in_pos < thirsty.stand_still_for_afk then
                    -- only get thirsty if not AFK
                    pl.thirst = pl.thirst - thirsty.thirst_per_second * thirsty.tick_time
                    if pl.thirst < 0 then pl.thirst = 0 end
                    --print("Lowering thirst by "..(thirsty.thirst_per_second*thirsty.tick_time).." to "..pl.thirst)
                end
            end
            -- should we only update the hud on an actual change?
            hb.change_hudbar(player, 'thirst', math.ceil(pl.thirst), 20)

            -- damage, if enabled
            if minetest.setting_getbool("enable_damage") then
                -- maybe not the best way to do this, but it does mean
                -- we can do anything with one tick loop
                if pl.thirst <= 0.0 then
                    pl.pending_dmg = pl.pending_dmg + thirsty.damage_per_second * thirsty.tick_time
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
        end
    end
end)

--[[

Stash: persist the thirst values in a file in the world directory.

If this is missing or corrupted, then no worries: nobody's thirsty ;-)

--]]

function thirsty.read_stash()
    local filename = minetest.get_worldpath() .. "/" .. thirsty.stash_filename
    local file, err = io.open(filename, "r")
    if not file then
        -- no problem, it's just not there
        -- TODO: or parse err?
        return
    end
    local str       = file:read()
    local contents  = minetest.deserialize(str)
    if contents then 
        if contents.players then
            thirsty.players = contents.players
        end
    end
    file:close()
end

function thirsty.write_stash()
    local filename = minetest.get_worldpath() .. "/" .. thirsty.stash_filename
    local file, err = io.open(filename, "w")
    if not file then
        minetest.log("error", "Thirsty: could not write " .. thirsty.stash_filename .. ": " ..err)
        return
    end
    local str = minetest.serialize({
        -- TODO: just the 'thirst' values
        players = thirsty.players
    })
    file:write(str)
    file:close()
end

-- read on startup
thirsty.read_stash()
-- write on shutdown
minetest.register_on_shutdown(thirsty.write_stash)
