--[[

Thirsty mod [thirsty]
==========================

A mod that adds a "thirst" mechanic, similar to hunger.

Copyright (C) 2015 Ben Deutsch <ben@bendeutsch.de>

License
-------

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

Terminology: "Thirst" vs. "hydration"
-------------------------------------

"Thirst" is the absence of "hydration" (a term suggested by
everamzah on the Minetest forums, thanks!). The overall mechanic
is still called "thirst", but the visible bar is that of
"hydration", filled with "hydro points".

]]


moditems = {}  -- declare a var, somewhere at beginning but below intlib.lua call.

if core.get_modpath("mcl_core") and mcl_core then -- means MineClone 2 is loaded, this is its core mod
   moditems.GROUP_WOOD = "group:wood"  -- MCL version of group wood
   moditems.IRON_ITEM = "mcl_core:iron_ingot"   -- MCL version of iron ingot
   moditems.COPPER_ITEM = "mcl_core:gold_ingot"   -- MCL version of bronze ingot
   moditems.STONE_ITEM = "mcl_core:stone"  -- MCL version of stone
   moditems.WATERBUCKET_ITEM = "mcl_buckets:bucket_water"  -- MCL version of water buckets
   moditems.MESECRYSTAL_ITEM = "mesecons:redstone" -- MCL version of mese mese crystal
   moditems.DIAMOND_ITEM = "mcl_core:diamond"  -- MCL version of diamond

	 moditems.WATER_SRC = "mcl_core:water_source"
   moditems.WATER_FLOW = "mcl_core:water_flowing"
   moditems.RIVER_WATER_SRC = "mclx_core:river_water_source"
   moditems.RIVER_WATER_FLOW = "mclx_core:river_water_flowing"

else         -- fallback, assume default (MineTest Game) is loaded, otherwise it will error anyway here.
   moditems.GROUP_WOOD = "group:wood" -- group wood in stock MT
   moditems.IRON_ITEM = "default:steel_ingot"    -- iron ingot in stock MT
   moditems.COPPER_ITEM = "default:copper_ingot"   -- bronze ingot in stock MT
   moditems.STONE_ITEM = "default:stone"  -- stone in stock MT
   moditems.WATERBUCKET_ITEM = "bucket:bucket_water"  -- water buckets in stock MT
   moditems.MESECRYSTAL_ITEM = "default:mese_crystal" -- mese crystal in stock MT
   moditems.DIAMOND_ITEM = "default:diamond"  -- diamond in stock MT
	 
   moditems.WATER_SRC = "default:water_source"
   moditems.WATER_FLOW = "default:water_flowing"
   moditems.RIVER_WATER_SRC = "default:river_water_source"
   moditems.RIVER_WATER_FLOW = "default:river_water_flowing"

end








-- the main module variable
thirsty = {

    -- Configuration variables
    config = {
        -- configuration in thirsty.default.conf
    },

    -- the players' values
    players = {
        --[[
        name = {
            last_pos = '-10:3',
            time_in_pos = 0.0,
            pending_dmg = 0.0,
            thirst_factor = 1.0,
        }
        ]]
    },

    -- water fountains
    fountains = {
        --[[
        x:y:z = {
            pos = { x=x, y=y, z=z },
            level = 4,
            time_until_check = 20,
            -- something about times
        }
        ]]
    },

    -- general settings
    time_next_tick = 0.0,
}
local M = thirsty

dofile(minetest.get_modpath('thirsty')..'/configuration.lua')
local C = M.config

dofile(minetest.get_modpath('thirsty')..'/persistent_player_attributes.lua')
local PPA = M.persistent_player_attributes

thirsty.time_next_tick = thirsty.config.tick_time

dofile(minetest.get_modpath('thirsty')..'/hud.lua')
dofile(minetest.get_modpath('thirsty')..'/functions.lua')

minetest.register_on_joinplayer(thirsty.on_joinplayer)
minetest.register_on_dieplayer(thirsty.on_dieplayer)
minetest.register_globalstep(thirsty.main_loop)

dofile(minetest.get_modpath('thirsty')..'/components.lua')

