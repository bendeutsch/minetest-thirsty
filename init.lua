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

-- Configuration variables
local tick_time = 0.5
local thirst_per_second = 1.0 / 20.0
local stand_still_for_drink = 1.0
local stand_still_for_afk = 120.0 -- 2 Minutes

local drink_from_node = {
    -- value: thirst regen per second
    ['default:water_source'] = 0.5,
    ['default:water_flowing'] = 0.5,
}

local time_next_tick = tick_time

local thirst_level = {}

-- to detect "standing still" for drinking, and also AFK detection
local player_info = {}

hb.register_hudbar('thirst', 0xffffff, "Thirst", {
    bar = 'thirsty_hudbars_bar.png',
    icon = 'thirsty_cup_100_16.png'
}, 20, 20, false)

minetest.register_on_joinplayer(function(player)
    hb.init_hudbar(player, 'thirst', 20, 20, false)
    local name = player:get_player_name()
    thirst_level[name] = 20
    local pos = player:getpos()

    player_info[name] = {
        last_pos = math.floor(pos.x) .. ':' .. math.floor(pos.z),
        time_in_pos = 0.0,
    }
end)

minetest.register_globalstep(function(dtime)
    -- get thirsty
    time_next_tick = time_next_tick - dtime
    while time_next_tick < 0.0 do
        -- time for thirst
        time_next_tick = time_next_tick + tick_time
        for _,player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
            local pos  = player:getpos()
            local p_info = player_info[name]

            -- how long have we been standing "here"?
            -- (the node coordinates in X and Z should be enough)
            local pos_hash = math.floor(pos.x) .. ':' .. math.floor(pos.z)
            local last_pos = p_info.last_pos
            if last_pos == pos_hash then
                p_info.time_in_pos = p_info.time_in_pos + tick_time
            else
                -- you moved!
                p_info.last_pos = pos_hash
                p_info.time_in_pos = 0.0
            end

            pos.y = pos.y + 0.1
            local node = minetest.get_node(pos)
            local drink_per_second = drink_from_node[node.name]
            if drink_per_second ~= nil and drink_per_second > 0 and p_info.time_in_pos > stand_still_for_drink then
                thirst_level[name] = thirst_level[name] + drink_per_second * tick_time
                --print("Raising thirst by "..(drink_per_second*tick_time).." to "..thirst_level[name])
                -- Drinking from the ground won't give you more than max
                if thirst_level[name] > 20 then thirst_level[name] = 20 end
            else
                if p_info.time_in_pos < stand_still_for_afk then
                    -- if afk, skip just about everything

                    thirst_level[name] = thirst_level[name] - thirst_per_second * tick_time
                    --print("Lowering thirst by "..(thirst_per_second*tick_time).." to "..thirst_level[name])
                    if thirst_level[name] < 0 then thirst_level[name] = 0 end
                end
            end
            -- should we only update the hud on an actual change?
            hb.change_hudbar(player, 'thirst', math.ceil(thirst_level[name]), 20)
        end
    end
end)
