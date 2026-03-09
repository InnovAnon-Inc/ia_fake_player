-- ia_dunce/storage.lua

--- Internal: Logic for putting items into a container
function ia_dunce._process_put(self, vil_inv, node_inv, pos, op)
    minetest.log('ia_dunce._process_put()')
    local size = vil_inv:get_size("main")
    for i = 1, size do
        local stack = vil_inv:get_stack("main", i)
        -- op.put_func allows us to filter (e.g., "only put coal")
        if not stack:is_empty() and op.put_func(self, stack, op.data) then
            local target_index = op.data and op.data.target_index
            local leftover
            
            if target_index then
                -- Precise slot placement (Furnace input, etc.)
                local to_put = stack:take_item(op.data.target_count or 1)
                node_inv:set_stack(op.list, target_index, to_put)
                leftover = stack
                ia_dunce._trigger_node_event(pos, op.list, target_index, to_put, self.fake_player, "put")
            else
                -- General list addition (Chest dumping)
                leftover = node_inv:add_item(op.list, stack)
                ia_dunce._trigger_node_event(pos, op.list, i, stack, self.fake_player, "put")
            end
            
            vil_inv:set_stack("main", i, leftover)
        end
    end
end

--- Internal: Logic for taking items from a container
function ia_dunce._process_take(self, vil_inv, node_inv, pos, op)
    minetest.log('ia_dunce._process_take()')
    local size = node_inv:get_size(op.list)
    for i = 1, size do
        local stack = node_inv:get_stack(op.list, i)
        if not stack:is_empty() and op.take_func(self, stack, op.data) then
            local leftover = vil_inv:add_item("main", stack)
            node_inv:set_stack(op.list, i, leftover)
            ia_dunce._trigger_node_event(pos, op.list, i, stack, self.fake_player, "take")
        end
    end
end

--- Internal: Triggers node reactions (starts furnaces, updates chest visuals)
function ia_dunce._trigger_node_event(pos, listname, index, stack, player, event_type)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    local handler = def and def["on_metadata_inventory_" .. event_type]
    
    if handler then
        handler(pos, listname, index, stack, player)
    end
end
