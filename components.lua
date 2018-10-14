--[[

Default components for Thirsty.

These are nodes and items that "implement" the functionality
from functions.lua

See init.lua for license.

]]


local thristyitems = {}  -- declare a var, somewhere at beginning but below intlib.lua call.

if core.get_modpath("mcl_core") and mcl_core then -- means MineClone 2 is loaded, this is its core mod
   thristyitems.GROUP_WOOD = "group:wood"  -- MCL version of group wood
   thristyitems.IRON_ITEM = "mcl_core:iron_ingot"   -- MCL version of iron ingot
   thristyitems.COPPER_ITEM = "mcl_core:gold_ingot"   -- MCL version of bronze ingot
   thristyitems.STONE_ITEM = "mcl_core:stone"  -- MCL version of stone
   thristyitems.WATERBUCKET_ITEM = "mcl_buckets:bucket_water"  -- MCL version of water buckets
   thristyitems.MESECRYSTAL_ITEM = "mesecons:redstone" -- MCL version of mese mese crystal
   thristyitems.DIAMOND_ITEM = "mcl_core:diamond"  -- MCL version of diamond
	 
	 -- override default consumption of few MCL specific items to make drinking possible.
	 
	 minetest.override_item("mcl_potions:potion_river_water", { on_secondary_use = thirsty.on_use(nil) } )
	 
	 minetest.override_item("mcl_potions:potion_water", { on_secondary_use = thirsty.on_use(nil) } )
	 
else    -- fallback, assume default (MineTest Game) is loaded, otherwise it will error anyway here.
   thristyitems.GROUP_WOOD = "group:wood" -- group wood in stock MT
   thristyitems.IRON_ITEM = "default:steel_ingot"    -- iron ingot in stock MT
   thristyitems.COPPER_ITEM = "default:copper_ingot"   -- bronze ingot in stock MT
   thristyitems.STONE_ITEM = "default:stone"  -- stone in stock MT
   thristyitems.WATERBUCKET_ITEM = "bucket:bucket_water"  -- water buckets in stock MT
   thristyitems.MESECRYSTAL_ITEM = "default:mese_crystal" -- mese crystal in stock MT
   thristyitems.DIAMOND_ITEM = "default:diamond"  -- diamond in stock MT
end

--[[

Drinking containers (Tier 1)

Defines a simple wooden bowl which can be used on water to fill
your hydration.

Optionally also augments the nodes from vessels to enable drinking
on use.

]]

if minetest.get_modpath("vessels") and thirsty.config.register_vessels then
    -- add "drinking" to vessels
    thirsty.augment_item_for_drinking('vessels:drinking_glass', 22)
    thirsty.augment_item_for_drinking('vessels:glass_bottle', 24)
    thirsty.augment_item_for_drinking('vessels:steel_bottle', 26)
end

if minetest.get_modpath("default") and thirsty.config.register_bowl then
    -- our own simple wooden bowl
    minetest.register_craftitem('thirsty:wooden_bowl', {
        description = "Wooden bowl",
        inventory_image = "thirsty_bowl_16.png",
        liquids_pointable = true,
        on_use = thirsty.on_use(nil),
    })

    minetest.register_craft({
        output = "thirsty:wooden_bowl",
        recipe = {
            {thristyitems.GROUP_WOOD, "", thristyitems.GROUP_WOOD },
            {"", thristyitems.GROUP_WOOD, "" }
        }
    })
   -- register thirsty version of bowl full of water, this is coverted back to normal after drinking
   minetest.register_craftitem('thirsty:wooden_bowl_water', {
        description = "Wooden bowl with water",
        inventory_image = "thirsty_bowl_16_water.png",
        liquids_pointable = true,
        on_use = thirsty.on_use(nil),
    })

-- if running mineclone2, use own bowl instead.
elseif minetest.get_modpath("mcl_core") and thirsty.config.register_bowl then
    minetest.override_item("mcl_core:bowl", { liquids_pointable = true, on_use = thirsty.on_use(nil)} )

    -- allow to fill bowl with water, this is coverted back to normal after drinking
    minetest.register_craftitem('thirsty:mcl_bowl_water', {
        description = "Bowl with water",
        inventory_image = "mcl_bowl_water.png",
        on_use = thirsty.on_use(nil),
    })

end

--[[

Hydro containers (Tier 2)

Defines canteens (currently two types, with different capacities),
tools which store hydro. They use wear to show their content
level in their durability bar; they do not disappear when used up.

Wear corresponds to hydro level as follows:
- a wear of 0     shows no durability bar       -> empty (initial state)
- a wear of 1     shows a full durability bar   -> full
- a wear of 65535 shows an empty durability bar -> empty

]]

if ( minetest.get_modpath("default") or minetest.get_modpath("mcl_core") ) and thirsty.config.register_canteens then

    minetest.register_tool('thirsty:steel_canteen', {
        description = 'Steel canteen',
        inventory_image = "thirsty_steel_canteen_16.png",
        liquids_pointable = true,
        stack_max = 1,
        on_use = thirsty.on_use(nil),
    })

    minetest.register_tool('thirsty:bronze_canteen', {
        description = 'Bronze canteen',
        inventory_image = "thirsty_bronze_canteen_16.png",
        liquids_pointable = true,
        stack_max = 1,
        on_use = thirsty.on_use(nil),
    })

    minetest.register_craft({
        output = "thirsty:steel_canteen",
        recipe = {
            { thristyitems.GROUP_WOOD, ""},
            { thristyitems.IRON_ITEM, thristyitems.IRON_ITEM },
            { thristyitems.IRON_ITEM, thristyitems.IRON_ITEM }
        }
    })
    minetest.register_craft({
        output = "thirsty:bronze_canteen",
        recipe = {
            { thristyitems.GROUP_WOOD, ""},
            { thristyitems.COPPER_ITEM, thristyitems.COPPER_ITEM },
            { thristyitems.COPPER_ITEM, thristyitems.COPPER_ITEM }
        }
    })

end

--[[

Tier 3

]]


if (minetest.get_modpath("default") and minetest.get_modpath("bucket")) or (minetest.get_modpath("mcl_core") and  minetest.get_modpath("mcl_buckets")) and thirsty.config.register_drinking_fountain then

    if minetest.get_modpath("mcl_core") then
      -- customized look for Mineclone2
      tiles_fountain = {
      -- top, bottom, right, left, front, back. MCL version
      'thirsty_drinkfount_top_mcl.png',
      'thirsty_drinkfount_bottom_mcl.png',
      'thirsty_drinkfount_side_mcl.png',
      'thirsty_drinkfount_side_mcl.png',
      'thirsty_drinkfount_side_mcl.png',
      'thirsty_drinkfount_side_mcl.png',
       }
    else
      tiles_fountain = {
      -- top, bottom, right, left, front, back
      'thirsty_drinkfount_top.png',
      'thirsty_drinkfount_bottom.png',
      'thirsty_drinkfount_side.png',
      'thirsty_drinkfount_side.png',
      'thirsty_drinkfount_side.png',
      'thirsty_drinkfount_side.png',
      }
		end

    minetest.register_node('thirsty:drinking_fountain', {
        description = 'Drinking fountain',
        drawtype = 'nodebox',
        tiles = tiles_fountain,
        paramtype = 'light',
        groups = { cracky = 2 },
        node_box = {
            type = "fixed",
            fixed = {
                { -3/16, -8/16, -3/16, 3/16, 3/16, 3/16 },
                { -8/16, 3/16, -8/16, 8/16, 6/16, 8/16 },
                { -8/16, 6/16, -8/16, 8/16, 8/16, -6/16 },
                { -8/16, 6/16, 6/16, 8/16, 8/16, 8/16 },
                { -8/16, 6/16, -6/16, -6/16, 8/16, 6/16 },
                { 6/16, 6/16, -6/16, 8/16, 8/16, 6/16 },
            },
        },
        selection_box = {
            type = "regular",
        },
        collision_box = {
            type = "regular",
        },
        on_rightclick = thirsty.on_rightclick(nil),
    })

    minetest.register_craft({
        output = "thirsty:drinking_fountain",
        recipe = {
            { thristyitems.STONE_ITEM, thristyitems.WATERBUCKET_ITEM, thristyitems.STONE_ITEM },
            { "", thristyitems.STONE_ITEM, ""},
            { "", thristyitems.STONE_ITEM, ""}
        }
    })

end

--[[

Tier 4+: the water fountains, plus extenders

]]

if (minetest.get_modpath("default") and minetest.get_modpath("bucket")) or (minetest.get_modpath("mcl_core") and  minetest.get_modpath("mcl_buckets")) and thirsty.config.register_fountains then

    if minetest.get_modpath("mcl_core") then
      tiles_fountain_module = {
      -- top, bottom, right, left, front, back. MCL version
      'thirsty_waterfountain_top_mcl.png',
      'thirsty_waterfountain_top_mcl.png',
      'thirsty_waterfountain_top_mcl.png',
      'thirsty_waterfountain_top_mcl.png',
      'thirsty_waterfountain_top_mcl.png',
      'thirsty_waterfountain_top_mcl.png',
       }

      tiles_fountain_module_ext = {
      'thirsty_waterextender_side_mcl.png',
      'thirsty_waterextender_side_mcl.png',
      'thirsty_waterextender_side2_mcl.png',
      'thirsty_waterextender_side2_mcl.png',
      'thirsty_waterextender_top_mcl.png',
      'thirsty_waterextender_top_mcl.png',
      }


      tiles_fountain_module_ext_2 = {
      'thirsty_waterextender_side3_mcl.png',
      'thirsty_waterextender_side3_mcl.png',
      'thirsty_waterextender_top_mcl.png',
      'thirsty_waterextender_top_mcl.png',
      'thirsty_waterextender_side2_mcl.png',
      'thirsty_waterextender_side2_mcl.png',
      }


      tiles_fountain_module_ext_split = {
      'thirsty_waterextender_top2_mcl.png',
      'thirsty_waterextender_top2_mcl.png',
      'thirsty_waterextender_top2_mcl.png',
      'thirsty_waterextender_top2_mcl.png',
      'thirsty_waterextender_top2_mcl.png',
      'thirsty_waterextender_top2_mcl.png',
      }


    else
      tiles_fountain_module = {
      -- top, bottom, right, left, front, back
      'thirsty_waterfountain_top.png',
      'thirsty_waterfountain_top.png',
      'thirsty_waterfountain_side.png',
      'thirsty_waterfountain_side.png',
      'thirsty_waterfountain_side.png',
      'thirsty_waterfountain_side.png',
      }

      tiles_fountain_module_ext = {
      'thirsty_waterextender_side.png',
      'thirsty_waterextender_side.png',--
      'thirsty_waterextender_side2.png',
      'thirsty_waterextender_side2.png',
      'thirsty_waterextender_top.png',
      'thirsty_waterextender_top.png',
      }

      tiles_fountain_module_ext_2 = {
      'thirsty_waterextender_side3.png',
      'thirsty_waterextender_side3.png',
      'thirsty_waterextender_top.png',
      'thirsty_waterextender_top.png',
      'thirsty_waterextender_side2.png',
      'thirsty_waterextender_side2.png',
      }

      tiles_fountain_module_ext_split = {
      'thirsty_waterextender_top2.png',
      'thirsty_waterextender_top2.png',
      'thirsty_waterextender_top2.png',
      'thirsty_waterextender_top2.png',
      'thirsty_waterextender_top2.png',
      'thirsty_waterextender_top2.png',
      }

    end

    minetest.register_node('thirsty:water_fountain', {
        description = 'Water pump',
        tiles = tiles_fountain_module,
        paramtype = 'light',
        groups = { cracky = 2 },
    })

    minetest.register_node('thirsty:water_extender', {
        description = 'Water pipe',
        tiles = tiles_fountain_module_ext,
        paramtype = 'light',
        groups = { cracky = 2 },
    })

    minetest.register_node('thirsty:water_extender_2', {
        description = 'Water pipe',
        tiles = tiles_fountain_module_ext_2,
        paramtype = 'light',
        groups = { cracky = 2 },

    })

    minetest.register_node('thirsty:water_extender_split', {
        description = 'Water pipe split',
        tiles = tiles_fountain_module_ext_split,
        paramtype = 'light',
        groups = { cracky = 2 },
    })


    minetest.register_craft({
        output = "thirsty:water_fountain",
        recipe = {
            { thristyitems.COPPER_ITEM, "", thristyitems.COPPER_ITEM },
            { "", thristyitems.MESECRYSTAL_ITEM, ""},
            { thristyitems.COPPER_ITEM, "", thristyitems.COPPER_ITEM }
        }
    })
    minetest.register_craft({
        output = "thirsty:water_extender",
        recipe = {
            { thristyitems.COPPER_ITEM, "", "" },
            { "", "", "" },
            { "", "", thristyitems.COPPER_ITEM }
        }
    })

    minetest.register_craft({
        output = "thirsty:water_extender_2",
        recipe = {
            { "", "", thristyitems.COPPER_ITEM },
            { "", "", "" },
            { thristyitems.COPPER_ITEM, "", "" }
        }
    })

    minetest.register_craft({
        output = "thirsty:water_extender_split",
        recipe = {
            { "", thristyitems.COPPER_ITEM, "" },
            { thristyitems.COPPER_ITEM, "", thristyitems.COPPER_ITEM },
            { "", thristyitems.COPPER_ITEM, "" }
        }
    })

    minetest.register_abm({
        nodenames = {'thirsty:water_fountain'},
        interval = 2,
        chance = 5,
        action = thirsty.fountain_abm,
    })

end

--[[

Tier 5

These amulets don't do much; the actual code is above, where
they are searched for in player's inventories

]]

if ( minetest.get_modpath("default") or minetest.get_modpath("mcl_core") ) and minetest.get_modpath("bucket") and  thirsty.config.register_amulets then

    minetest.register_craftitem('thirsty:injector', {
        description = 'Water injector',
        inventory_image = 'thirsty_injector.png',
    })
    minetest.register_craft({
        output = "thirsty:injector",
        recipe = {
            { thristyitems.DIAMOND_ITEM, thristyitems.MESECRYSTAL_ITEM, thristyitems.DIAMOND_ITEM },
            { thristyitems.MESECRYSTAL_ITEM, thristyitems.WATERBUCKET_ITEM, thristyitems.MESECRYSTAL_ITEM },
            { thristyitems.DIAMOND_ITEM, thristyitems.MESECRYSTAL_ITEM, thristyitems.DIAMOND_ITEM }
        }
    })

    minetest.register_craftitem('thirsty:extractor', {
        description = 'Water extractor',
        inventory_image = 'thirsty_extractor.png',
    })
    minetest.register_craft({
        output = "thirsty:extractor",
        recipe = {
            { thristyitems.MESECRYSTAL_ITEM, thristyitems.DIAMOND_ITEM, thristyitems.MESECRYSTAL_ITEM },
            { thristyitems.DIAMOND_ITEM, thristyitems.WATERBUCKET_ITEM, thristyitems.DIAMOND_ITEM },
            { thristyitems.MESECRYSTAL_ITEM, thristyitems.DIAMOND_ITEM, thristyitems.MESECRYSTAL_ITEM }
        }
    })

end
