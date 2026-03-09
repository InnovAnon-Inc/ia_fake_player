-- ia_fake_player/actions/simple/craft.lua

--- Helper to turn a flat recipe list into a count table.
function ia_fake_player.actions.simple.get_recipe_requirements(recipe_items)
    local reqs = {}
    for _, item in ipairs(recipe_items) do
        reqs[item] = (reqs[item] or 0) + 1
    end
    return reqs
end

--- Checks if all numeric requirements are met.
-- @param requirements Table like { ["default:stone"] = 8 }
function ia_fake_player.actions.simple.has_required_items(self, requirements)
	minetest.log('ia_fake_player.actions.simple.has_required_items()')
    for item_name, amount in pairs(requirements) do
        if type(amount) == "number" then
            if ia_fake_player.actions.simple.get_item_count(self, item_name) < amount then
                return false
            end
        end
    end
    return true
end

--- High-level predicate: Do we have the item OR can we craft it immediately?
-- @param self The Dunce entity.
-- @param item_name The name of the desired item.
-- @return boolean.
function ia_fake_player.actions.simple.can_obtain_item(self, item_name)
    -- 1. Do we already have it?
    if ia_fake_player.actions.simple.has_item(self, item_name) then
        return true
    end

    -- 2. Can we craft it in one step?
    local recipe = minetest.get_craft_recipe(item_name)
    if recipe and recipe.items then
        local reqs = ia_fake_player.actions.simple.get_recipe_requirements(recipe.items)
        if ia_fake_player.actions.simple.has_required_items(self, reqs) then
            return true
        end
    end

    return false
end

--- Attempts to craft an item using standard recipes.
-- @param self The Dunce entity.
-- @param output_name The name of the item to craft.
-- @return boolean, string (Success status and message).
function ia_fake_player.actions.simple.craft_item(self, output_name)
    minetest.log('ia_fake_player.actions.simple.craft_item(' .. output_name .. ')')
    
    -- 1. Get recipe from engine
    local recipe = minetest.get_craft_recipe(output_name)
    if not recipe or not recipe.items then
        return false, "no_recipe"
    end

    -- 2. Verify we have the items (Inventory check)
    if not ia_fake_player.actions.simple.has_required_items(self, ia_fake_player.actions.simple.get_recipe_requirements(recipe.items)) then
        return false, "missing_ingredients"
    end

    -- 3. Execute: This is "magic" crafting (simulating a player using the 3x3 grid)
    -- We remove the ingredients and add the result.
    local inv = self:get_inventory()
    
    -- Remove ingredients
    for _, item_name in pairs(recipe.items) do
        inv:remove_item("main", ItemStack(item_name))
    end
    
    -- Add result
    local result_stack = ItemStack(recipe.output)
    local leftover = inv:add_item("main", result_stack)
    
    if not leftover:is_empty() then
        -- Edge case: inventory filled up during craft (e.g., recursive containers)
        minetest.add_item(self:get_pos(), leftover)
    end

    -- Feedback
    ia_fake_player.actions.simple.set_animation(self, "MINE", 20, false)
    minetest.sound_play("default_place_node", {pos = self:get_pos(), gain = 0.5})
    
    return true
end


