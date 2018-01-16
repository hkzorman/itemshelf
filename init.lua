-- Item shelf for generic objects
-- Inventory overlay and blast code taken from vessels mod in MTG
-- All other code by Zorman2000

local shelf_formspec =
		"size[8,7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;main;1.5,0.25;2,2;]"..
		"list[current_player;main;0,2.75;8,1;]"..
		"list[current_player;main;0,4;8,3;8]"..
		"listring[context;main]"..
		"listring[current_player;main]"


local function get_shelf_formspec(inv)
	local formspec = shelf_formspec
	-- No overlays
	-- local invlist = inv and inv:get_list("main")
	-- -- Inventory slots overlay
	-- local vx, vy = 1.5, 0.25
	-- for i = 1, 4 do
	-- 	if i == 3 then
	-- 		vx = 1.5
	-- 		vy = vy + 1
	-- 	end
	-- 	if not invlist or invlist[i]:is_empty() then
	-- 		formspec = formspec ..
	-- 			"image[" .. vx .. "," .. vy .. ";1,1;vinyl_disc_overlay.png]"
	-- 	end
	-- 	vx = vx + 1
	-- end
	return formspec
end

local function update_disc_shelf(pos)
	-- Remove all objects
	local objs = minetest.get_objects_inside_radius(pos, 0.7)
	for _,obj in pairs(objs) do
		obj:remove()
	end

	local node = minetest.get_node(pos)
	local node_dir = minetest.facedir_to_dir(node.param2)
	--local disc_dir = minetest.facedir_to_dir(node.param2 + 1 % 3)
	-- Entities look in the same direction
	local obj_dir = minetest.facedir_to_dir(node.param2 + 1 % 3)
	-- Calculate initial position for entities
	local start_pos = {
		x=pos.x - (0.25 * obj_dir.x) - (node_dir.x * 0.25),
		y=pos.y + 0.25,
		z=pos.z - (0.25 * obj_dir.z) - (node_dir.z * 0.25)}

	-- Calculate amount of objects in the inventory
	local inv = minetest.get_meta(pos):get_inventory()
	local list = inv:get_list("main")
	local obj_count = 0
	for _,itemstack in pairs(list) do
		if not itemstack:is_empty() then
			obj_count = obj_count + 1
		end
	end
	-- Update inventory images
	--minetest.get_meta(pos):set_string("formspec", get_disc_shelf_formspec(inv))
	--minetest.log("Found "..dump(max_disc_count).." disc stacks on inventory")
	if obj_count > 0 then
		--minetest.log("Adding "..dump(math.floor(max_disc_count / 2)).." disc entities")
		-- Correct z if objects are being placed on a 90 degrees angle vs the node.
		--if disc_dir.z == 0 and disc_dir.x == 0 then
		--	disc_dir.z = 1
		--end
		for i = 1, obj_count do
			local overhead = i
			-- minetest.log("I: "..dump(i))
			-- minetest.log("Start pos.x: "..dump(start_pos.x)..", disc_dir.x: "..dump(disc_dir.x)..", i: "..dump(i))
			-- minetest.log("Start pos.z: "..dump(start_pos.z)..", disc_dir.z: "..dump(disc_dir.z)..", i: "..dump(i))
			if i > 2 then
				start_pos.y = start_pos.y - 0.65
				overhead = i - 2
			end
			local obj_pos = {
					x=start_pos.x + (0.33 * overhead * obj_dir.x),
					y=start_pos.y,
					z=start_pos.z + (0.33 * overhead * obj_dir.z)
				}
			--minetest.log("Adding disc entity at "..minetest.pos_to_string(disc_pos))
			local ent = minetest.add_entity(obj_pos, "gramophone:item")
			--ent:set_yaw(minetest.dir_to_yaw(minetest.facedir_to_dir(node.param2 + 1 % 3)))
		end
	end

end


-- Disc shelf
minetest.register_node("gramophone:cupboard", {
	description = "Cupboard",
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.4375, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
			{-0.5, -0.5, -0.5, -0.4375, 0.5, 0.5}, -- NodeBox2
			{0.4375, -0.5, -0.5, 0.5, 0.5, 0.5}, -- NodeBox3
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, -- NodeBox4
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.4375}, -- NodeBox5
			{-0.5, -0.0625, -0.5, 0.5, 0, 0.5}, -- NodeBox6
		}
	},
	groups = {cracky = 2},
	on_construct = function(pos)
		-- Initialize inventory
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
    	inv:set_size("main", 4)
    	-- Initialize formspec
    	meta:set_string("formspec", shelf_formspec)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.get_item_group(stack:get_name(), "music_disc") ~= 0 then
			return stack:get_count()
		end
		return 0
	end,
	on_metadata_inventory_put = update_disc_shelf,
	on_metadata_inventory_take = update_disc_shelf,
	on_dig = function(pos, node, digger)
		-- Clear any object disc
		local objs = minetest.get_objects_inside_radius(pos, 0.7)
		for _,obj in pairs(objs) do
			obj:remove()
		end
		-- Pop-up disc if existing
		local meta = minetest.get_meta(pos)
		local list = meta:get_inventory():get_list("main")
		for _,item in pairs(list) do
			local drop_pos = {
				x=math.random(pos.x - 0.5, pos.x + 0.5),
				y=pos.y,
				z=math.random(pos.z - 0.5, pos.z + 0.5)}
			minetest.add_item(pos, item:get_name())
		end
		-- Remove node
		minetest.remove_node(pos)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "vessels", drops)
		drops[#drops + 1] = "gramophone:cupboard"
		minetest.remove_node(pos)
		return drops
	end
})


-- Entity for shelf
minetest.register_entity("gramophone:item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = 0.25, y = 0.25},
	collisionbox = {0,0,0, 0,0,0},
	physical = false,
	--textures = {"vinyl_disc.png"},
	wield_item = "gramophone:vinyl_disc2"
})

