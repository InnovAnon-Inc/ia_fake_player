-- ia_dunce/recipes.lua

--local recipes = {}

--- Converts a 2D/3D recipe table into a flat list of appliance operations.
-- @param recipe_grid The nested table of items.
-- @param list_name The inventory list to target (e.g., "craft" or "rec").
-- @param put_func The function that validates if the Dunce has the item.
-- @return table A list of operations for manipulate_appliance.
function ia_dunce.build_crafting_ops(recipe_grid, list_name, put_func)
	minetest.log('ia_dunce.crafting_ops()')
    local ops = {}
    
    -- We use ipairs to ensure we follow the table order exactly.
    for y, row in ipairs(recipe_grid) do
        for x, item_name in ipairs(row) do
            -- Calculate 1D index for the 3x3 grid (Luanti/Minetest standard)
            -- Most grids are Row-Major: (y-1) * width + x
            local slot_index = (y - 1) * 3 + x
            
            if item_name and item_name ~= "" then
                table.insert(ops, {
                    list = list_name,
                    is_put = true,
                    put_func = put_func,
                    no_yield = true, -- Don't pause between placing ingredients
                    data = {
                        item = item_name,
                        target_index = slot_index,
                        target_count = 1
                    }
                })
            end
        end
    end
    
    return ops
end

--- Specialized helper for the "Crafting Bench" style mods (Put -> Wait -> Take).
function ia_dunce.build_complex_craft_sequence(self, pos, recipe, config)
	minetest.log('ia_dunce.build_complex_craft_sequence()')
    local ops = ia_dunce.build_crafting_ops(recipe, config.grid_list, config.put_logic)
    
    -- Add the 'Processing' steps
    table.insert(ops, { noop = config.duration or 20 })
    
    -- Add the 'Result' retrieval
    table.insert(ops, {
        list = config.output_list or "dst",
        is_take = true,
        take_func = config.take_logic
    })
    
    -- Add the 'Cleanup' (Taking back unused items/containers)
    table.insert(ops, {
        list = config.grid_list,
        is_take = true,
        take_func = config.take_logic
    })
    
    return ops
end
