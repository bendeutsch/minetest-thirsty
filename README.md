Thirsty [thirsty]
=================

A Minetest mod that adds a "thirst" mechanic.

Version: 0.1.0

License: LGPL 2.1 or later

Report bugs or request help on the forum topic.

Description
-----------

This is a mod for MineTest. It adds a thirst mechanic to the
game, similar to many hunger mods (but independent of them).
Players will slowly get thirstier over time, and will need to
drink or suffer damage.

The point of this mod is not to make the game more realistic,
or harder. The point is to have another mechanic that rewards
preparation and infrastructure. Players will now have an incentive
to build their base next to water (or add some water to their base),
and/or take some water with them when mining or travelling.

Future plans
------------

**Tier 0**: stand in water (running or standing) to slowly drink.
You may not move during drinking (or you could cross an ocean without
getting thirsty).

**Tier 1**: use a cup (e.g. from `vessels`) on water to instantly fill
your thirst bar.

**Tier 2**: craftable water skin: holds three full thirst bars worth of
water.

**Tier 3**: placeable drinking fountain / wash basin node: instantly
fills your thirst bar when used.

**Tier 4+**: placeable fountain node(s) to fill the thirst bars of all
players within range. Placing more nodes increases the range.

**Tier 5**: craftable trinkets/gadgets/amulets that constantly keep your
thirst bar filled when in your inventory, solving your thirst problem
once and for all.

Dependencies
------------
* hudbars: https://forum.minetest.net/viewtopic.php?f=11&t=11153 (preliminary, for easy HUD definitions)

Installation
------------

Unzip the archive, rename the folder to to `thirsty` and
place it in minetest/mods/

(  Linux: If you have a linux system-wide installation place
    it in ~/.minetest/mods/.  )

(  If you only want this to be used in a single world, place
    the folder in worldmods/ in your worlddirectory.  )

For further information or help see:
http://wiki.minetest.com/wiki/Installing_Mods
