-- Item shelf for generic objects
-- Inventory overlay and blast code taken from vessels mod in MTG
-- All other code by Zorman2000

local function get_shelf_formspec(inv_size)
	return "size[8,7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..

		"list[context;main;"..(math.abs((inv_size / 2) - 8) / 2)..",0.25;"..(inv_size / 2)..",2;]"..
		"list[current_player;main;0,2.75;8,1;]"..
		"list[current_player;main;0,4;8,3;8]"..
		"listring[context;main]"..
		"listring[current_player;main]"
end

local temp_texture
local temp_size

local function get_obj_dir(param2)
	return ((param2 + 1) % 4)
end

local function update_shelf(pos)
	-- Remove all objects
	local objs = minetest.get_objects_inside_radius(pos, 0.75)
	for _,obj in pairs(objs) do
		obj:remove()
	end

	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	-- Calculate directions
	local node_dir = minetest.facedir_to_dir(((node.param2 + 2) % 4))
	local obj_dir = minetest.facedir_to_dir(get_obj_dir(node.param2))
	-- Get maximum number of shown items (4 or 6)
	local max_shown_items = minetest.get_item_group(node.name, "itemshelf_shown_items")
	-- Get custom displacement properties
	local depth_displacement = meta:get_float("itemshelf:depth_displacement")
	local vertical_displacement = meta:get_float("itemshelf:vertical_displacement")
	if depth_displacement == 0 then
		depth_displacement = 0.25
	end
	if vertical_displacement == 0 then
		vertical_displacement = 0.2375
	end
	minetest.log("displacements: "..dump(depth_displacement)..", "..dump(vertical_displacement))
	-- Calculate the horizontal displacement. This one is hardcoded so that either 4 or 6
	-- items are properly displayed.
	local horizontal_displacement = 0.715
	if max_shown_items == 6 then
		horizontal_displacement = 0.555
	end

	-- Calculate initial position for entities
	-- local start_pos = {
	-- 	x=pos.x - (0.25 * obj_dir.x) - (node_dir.x * 0.25),
	-- 	y=pos.y + 0.25,
	-- 	z=pos.z - (0.25 * obj_dir.z) - (node_dir.z * 0.25)
	-- }
	-- How the below works: Following is a top view of a node
	--                              | +z (N) 0
	--                              |
	-- 					------------------------
	-- 					|           |          |
	-- 					|           |          |
	-- 					|           |          |
	--     -x (W) 3     |           | (0,0)    |      +x (E) 1
	--     -------------|-----------+----------|--------------
	-- 					|           |          |
	-- 					|           |          |
	-- 					|           |          |
	-- 					|           |          |
	-- 					------------------------
	-- 				                |
	-- 								| -z (S) 2

	-- From the picture above, your front could be at either -z, -z, x or z.
	-- To get the entity closer to the front, you need to add a certain amount
	-- (e.g. 0.25) to the x and z coordinates, and then multiply these by the
	-- the node direction (which is a vector pointing outwards of the node face).
	-- Therefore, start_pos is:
	local start_pos = {
		x=pos.x - (obj_dir.x * horizontal_displacement) + (node_dir.x * depth_displacement),
		y=pos.y + vertical_displacement,
		z=pos.z - (obj_dir.z * horizontal_displacement) + (node_dir.z * depth_displacement)
	}

	-- Calculate amount of objects in the inventory
	local inv = minetest.get_meta(pos):get_inventory()
	local list = inv:get_list("main")
	local obj_count = 0
	for key, itemstack in pairs(list) do
		if not itemstack:is_empty() then
			obj_count = obj_count + 1
		end
	end
	minetest.log("Found "..dump(obj_count).." items on shelf inventory")
	if obj_count > 0 then
		local shown_items = math.min(#list, max_shown_items)
		for i = 1, shown_items do
			local offset = i
			if i > (shown_items / 2) then
				offset = i - (shown_items / 2)
			end
			if i == ((shown_items / 2) + 1) then
				start_pos.y = start_pos.y - 0.5125
			end
			local item_displacement = 0.475
			if shown_items == 6 then
				item_displacement = 0.2775
			end
			local obj_pos = {
				x=start_pos.x + (item_displacement * offset * obj_dir.x), --- (node_dir.z * overhead * 0.25),
				y=start_pos.y,
				z=start_pos.z + (item_displacement * offset * obj_dir.z) --- (node_dir.x * overhead * 0.25)
			}

			if not list[i]:is_empty() then
				minetest.log("Adding item entity at "..minetest.pos_to_string(obj_pos))
				temp_texture = list[i]:get_name()
				temp_size = 0.8/max_shown_items
				--minetest.log("Size: "..dump(temp_size))
				local ent = minetest.add_entity(obj_pos, "itemshelf:item")
				ent:set_properties({
					wield_item = temp_texture,
					visual_size = {x = 0.8/max_shown_items, y = 0.8/max_shown_items}
				})
				ent:set_yaw(minetest.dir_to_yaw(minetest.facedir_to_dir(node.param2)))
			end
		end
	end

end

itemshelf = {}

-- Definable properties:
--   - description
--   - textures (if drawtype is nodebox)
--   - nodebox (like default minetest.register_node def)
--   - mesh (like default minetest.register_node def)
--   - item capacity (how many items will fit into the shelf, use even numbers, max 16)
--   - shown_items (how many items to show, will always show first (shown_items/2) items of each row, max 6)
--   - `half-depth`: if set to true, will use different nodebox. Do not use with `depth_offset`
--   - `vertical_offset`: starting position vertical displacement from the center of the node 
--   - `depth_offset`: starting position depth displacement from the center of the node
function itemshelf.register_shelf(name, def)
	-- Determine drawtype
	local drawtype = "nodebox"
	if def.mesh then
		drawtype = "mesh"
	end

	minetest.register_node("itemshelf:"..name, {
		description = def.description,
		tiles = def.textures,
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = drawtype,
		node_box = def.nodebox,
		mesh = def.mesh,
		groups = {choppy = 2, itemshelf = 1, itemshelf_shown_items = def.shown_items or 4},
		on_construct = function(pos)
			-- Initialize inventory
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
	    	inv:set_size("main", def.capacity or 4)
	    	-- Initialize formspec
	    	meta:set_string("formspec", get_shelf_formspec(def.capacity or 4))
	    	-- If given half_depth, initialize the displacement
	    	if def.half_depth == true then
	    		meta:set_float("itemshelf:depth_displacement", -0.1475)
	    	end
	    	-- Initialize custom displacements if defined
	    	if def.vertical_offset then
	    		meta:set_float("itemshelf:vertical_displacement", def.vertical_offset)
	    	end
	    	if def.depth_offset then
	    		meta:set_float("itemshelf:depth_displacement", def.depth_offset)
	    	end
		end,
		-- allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		-- 	if minetest.get_item_group(stack:get_name(), "music_disc") ~= 0 then
		-- 		return stack:get_count()
		-- 	end
		-- 	return 0
		-- end,
		on_metadata_inventory_put = update_shelf,
		on_metadata_inventory_take = update_shelf,
		on_dig = function(pos, node, digger)
			-- Clear any object disc
			local objs = minetest.get_objects_inside_radius(pos, 0.7)
			for _,obj in pairs(objs) do
				obj:remove()
			end
			-- Pop-up items
			minetest.add_item(pos, node.name)
			local meta = minetest.get_meta(pos)
			local list = meta:get_inventory():get_list("main")
			for _,item in pairs(list) do
				local drop_pos = {
					x=math.random(pos.x - 0.5, pos.x + 0.5),
					y=pos.y,
					z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
			-- Remove node
			minetest.remove_node(pos)
		end,
		on_blast = function(pos)
			minetest.add_item(pos, minetest.get_node(pos).name)
			local meta = minetest.get_meta(pos)
			local list = meta:get_inventory():get_list("main")
			for _,item in pairs(list) do
				local drop_pos = {
					x=math.random(pos.x - 0.5, pos.x + 0.5),
					y=pos.y,
					z=math.random(pos.z - 0.5, pos.z + 0.5)}
				minetest.add_item(pos, item:to_string())
			end
			-- Remove node
			minetest.remove_node(pos)
			return nil
		end,
		-- Screwdriver support
		on_rotate = function(pos, node, user, mode, new_param2) --{name = node.name, param1 = node.param1, param2 = node.param2}, user, mode, new_param2)
			-- Rotate
			node.param2 = new_param2
			minetest.swap_node(pos, node)
			update_shelf(pos)
			-- Disable rotation by screwdriver
			return false
		end,
	})
end

-- Entity for shelf
minetest.register_entity("itemshelf:item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = 0.20, y = 0.20},
	collisionbox = {0,0,0, 0,0,0},
	physical = false,
	on_activate = function(self, staticdata)
		-- Staticdata
		local data = {}
		if staticdata ~= nil and staticdata ~= "" then
			local cols = string.split(staticdata, "|")
			data["itemstring"] = cols[1]
			data["visualsize"] = tonumber(cols[2])
		end

		-- Texture
		if temp_texture ~= nil then
			-- Set texture from temp
			self.itemstring = temp_texture
			temp_texture = nil
		elseif staticdata ~= nil and staticdata ~= "" then
			-- Set texture from static data
			self.itemstring = data.itemstring
		end
		-- Set texture if available
		if self.itemstring ~= nil then
			self.wield_item = self.itemstring
		end
		
		-- Visual size
		if temp_size ~= nil then
			self.visualsize = temp_size
			temp_size = nil
		elseif staticdata ~= nil and staticdata ~= "" then
			self.visualsize = data.visualsize
		end
		-- Set visual size if available
		if self.visualsize ~= nil then
			self.visual_size = {x=self.visualsize, y=self.visualsize}
		end

		-- Set object properties
		self.object:set_properties(self)
		
	end,
	get_staticdata = function(self)
		local result = ""
		if self.itemstring ~= nil then
			result = self.itemstring.."|"
		end
		if self.visualsize ~= nil then
			result = result..self.visualsize
		end
		return result
	end,
})
