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

local drink_from_node = {
    -- value: thirst regen per second
    ['default:water_source'] = 0.5,
    ['default:water_flowing'] = 0.5,
}

local time_next_tick = tick_time

local thirst_level = {}

hb.register_hudbar('thirst', 0xffffff, "Thirst", {
    bar = 'thirsty_hudbars_bar.png',
    icon = 'thirsty_cup_100_16.png'
}, 20, 20, false)

minetest.register_on_joinplayer(function(player)
   hb.init_hudbar(player, 'thirst', 20, 20, false) 
   local name = player:get_player_name()
   thirst_level[name] = 20
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
            pos.y = math.floor(pos.y) + 0.5
            local node = minetest.get_node(pos)
            local drink_per_second = drink_from_node[node.name]
            if drink_per_second ~= nil and drink_per_second > 0 then
                thirst_level[name] = thirst_level[name] + drink_per_second * tick_time
                --print("Raising thirst by "..(drink_per_second*tick_time).." to "..thirst_level[name])
                -- Drinking from the ground won't give you more than max
                if thirst_level[name] > 20 then thirst_level[name] = 20 end
            else
                thirst_level[name] = thirst_level[name] - thirst_per_second * tick_time
                --print("Lowering thirst by "..(thirst_per_second*tick_time).." to "..thirst_level[name])
                if thirst_level[name] < 0 then thirst_level[name] = 0 end
            end
            hb.change_hudbar(player, 'thirst', math.ceil(thirst_level[name]), 20)
        end
    end
end)
