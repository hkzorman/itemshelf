Itemshelf
=========

The item shelf mod is a simple mod that adds to shelves that can hold up to 4 or 6 items. This small limitation is due to the fact that shelves show the items they are holding using entities. The entities are purely static and consume 0 CPU (like the ones in itemframes for example), but still the limitation is to avoid lag.

There are no crafting recipes at the moment. To get an item shelf, play on `creative` or use:
`/giveme itemshelf:small_shelf` or `/giveme itemshelf:large_shelf`. Both shelves are of the same size, however they can hold 4 or 6 items respectively. 

Developers
----------
Developers using this mod can register a particular node to use the item shelf functionality. To do that, the following function is used:
```lua
itemshelf.register_shelf(name, def)
```
where `name` is the name of the node (`itemshelf:` will be the prefix) and `def` is a Lua table defining the following:
  - `description`: shown in inventory
  - `textures` (if drawtype is nodebox)
  - `nodebox` (like default minetest.register_node def). Do not use with `mesh`.
  - `mesh` (like default minetest.register_node def). Do not use with `nodebox`.
  - `item capacity` (how many items will fit into the shelf, use even numbers, max 16)
  - `shown_items` (how many items to show, will always show first (shown_items/2) items of each row, max 6)

License
-------
All code is copyright (C) 2018 Hector Franqui (zorman2000), licensed under the MIT license. See `LICENSE` for details.

Roadmap
-------
  - Add shelves in all varieties of woods
  - Add crafting recipe
  - Add sounds when placing items
  - Allow shelves to contain only specific items
  - Allow overlays if shelf holds specific items 