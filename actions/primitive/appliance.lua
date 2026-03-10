-- ia_fake_player/actions/primitive/appliance.lua

--- Internal: Triggers the node's reaction to inventory changes.
-- Ensures machines actually start smelting/crafting.
local function trigger_node_event(pos, listname, index, stack, player, event_type)
	minetest.log('ia_fake_player.actions.primitive.trigger_node_event()')
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local handler = def and def["on_metadata_inventory_" .. event_type]
	
	if handler then
		handler(pos, listname, index, stack, player)
	end
end

--- The Universal Appliance Handler
-- Ported from working_villages with improved validation and cleanup.
function ia_fake_player.actions.primitive.manipulate_appliance(self, pos, operations)
	minetest.log('ia_fake_player.actions.primitive.manipulate_appliance()')
	local node_meta = minetest.get_meta(pos)
	local node_inv = node_meta:get_inventory()
	local vil_inv = self:get_inventory()
	
	if not node_inv then return end

	for _, op in ipairs(operations) do
		-- Handle 'noop' (delays/waiting)
		if op.noop then
			-- we don't yield here; we return a 'busy' status 
			-- or let the brain handle the timer. For now, we'll skip.
		
		elseif op.is_put then
			-- Villager -> Appliance
			ia_fake_player.actions.primitive._process_put(self, vil_inv, node_inv, pos, op)
			
		elseif op.is_take then
			-- Appliance -> Villager
			ia_fake_player.actions.primitive._process_take(self, vil_inv, node_inv, pos, op)
		end
	end
end

--- Internal: Logic for putting items into a machine
function ia_fake_player.actions.primitive._process_put(self, vil_inv, node_inv, pos, op)
	minetest.log('ia_fake_player.actions.primitive._process_put()')
	local size = vil_inv:get_size("main")
	for i = 1, size do
		local stack = vil_inv:get_stack("main", i)
		if not stack:is_empty() and op.put_func(self, stack, op.data) then
			
			local target_index = op.data and op.data.target_index
			local leftover
			
			if target_index then
				-- Specific slot (Crafting/Furnace source)
				local to_put = stack:take_item(op.data.target_count or 1)
				node_inv:set_stack(op.list, target_index, to_put)
				leftover = stack
				trigger_node_event(pos, op.list, target_index, to_put, self, "put")
			else
				-- General list (Fuel/Input)
				leftover = node_inv:add_item(op.list, stack)
				trigger_node_event(pos, op.list, i, stack, self, "put")
			end
			
			vil_inv:set_stack("main", i, leftover)
		end
	end
end

--- Internal: Logic for taking items from a machine
function ia_fake_player.actions.primitive._process_take(self, vil_inv, node_inv, pos, op)
	minetest.log('ia_fake_player.actions.primitive._process_take()')
	local size = node_inv:get_size(op.list)
	for i = 1, size do
		local stack = node_inv:get_stack(op.list, i)
		if not stack:is_empty() and op.take_func(self, stack, op.data) then
			local leftover = vil_inv:add_item("main", stack)
			node_inv:set_stack(op.list, i, leftover)
			trigger_node_event(pos, op.list, i, stack, self, "take")
		end
	end
end

----- Internal: Logic for putting items into a container
--function ia_fake_player.actions.primitive._process_put(self, vil_inv, node_inv, pos, op)
--    minetest.log('ia_fake_player.actions.primitive._process_put()')
--    local size = vil_inv:get_size("main")
--    for i = 1, size do
--        local stack = vil_inv:get_stack("main", i)
--        -- op.put_func allows us to filter (e.g., "only put coal")
--        if not stack:is_empty() and op.put_func(self, stack, op.data) then
--            local target_index = op.data and op.data.target_index
--            local leftover
--            
--            if target_index then
--                -- Precise slot placement (Furnace input, etc.)
--                local to_put = stack:take_item(op.data.target_count or 1)
--                node_inv:set_stack(op.list, target_index, to_put)
--                leftover = stack
--                ia_fake_player.actions.primitive._trigger_node_event(pos, op.list, target_index, to_put, self.fake_player, "put")
--            else
--                -- General list addition (Chest dumping)
--                leftover = node_inv:add_item(op.list, stack)
--                ia_fake_player.actions.primitive._trigger_node_event(pos, op.list, i, stack, self.fake_player, "put")
--            end
--            
--            vil_inv:set_stack("main", i, leftover)
--        end
--    end
--end
--
----- Internal: Logic for taking items from a container
--function ia_fake_player.actions.primitive._process_take(self, vil_inv, node_inv, pos, op)
--    minetest.log('ia_fake_player.actions.primitive._process_take()')
--    local size = node_inv:get_size(op.list)
--    for i = 1, size do
--        local stack = node_inv:get_stack(op.list, i)
--        if not stack:is_empty() and op.take_func(self, stack, op.data) then
--            local leftover = vil_inv:add_item("main", stack)
--            node_inv:set_stack(op.list, i, leftover)
--            ia_fake_player.actions.primitive._trigger_node_event(pos, op.list, i, stack, self.fake_player, "take")
--        end
--    end
--end
--
----- Internal: Triggers node reactions (starts furnaces, updates chest visuals)
--function ia_fake_player.actions.primitive._trigger_node_event(pos, listname, index, stack, player, event_type)
--    local node = minetest.get_node(pos)
--    local def = minetest.registered_nodes[node.name]
--    local handler = def and def["on_metadata_inventory_" .. event_type]
--    
--    if handler then
--        handler(pos, listname, index, stack, player)
--    end
--end
