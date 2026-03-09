-- ia_fake_player/actions/simple/inventory.lua



--- Checks if the Dunce is carrying a specific item (wielded or in main).
-- @param self The fake player object.
-- @param condition function(name) or string.
-- @return boolean.
function ia_fake_player.actions.simple.has_item(self, condition)
	minetest.log('ia_fake_player.actions.simple.has_item()')
    local wield_name = self:get_wielded_item():get_name()
    local predicate = type(condition) == "string" 
        and function(n) return n == condition end 
        or condition

    if predicate(wield_name) then return true end

    local inv = self:get_inventory()
    for _, stack in ipairs(inv:get_list("main")) do
        if not stack:is_empty() and predicate(stack:get_name()) then
            return true
        end
    end
    
    return false
end

--- Basic wrapper to add an item to the Dunce's main bags.
-- @return ItemStack (Leftovers).
function ia_fake_player.actions.simple.add_to_inventory(self, stack)
	minetest.log('ia_fake_player.actions.simple.add_to_inventory()')
    return self:get_inventory():add_item("main", stack)
end

--- Checks if the Dunce has room for at least one of this item.
function ia_fake_player.actions.simple.has_room_for(self, item_name)
	minetest.log('ia_fake_player.actions.simple.has_room_for()')
    --local inv = self:get_inventory()
    local inv = self:get_inventory()
    assert(inv ~= nil)
    local stack = ItemStack(item_name)
    -- check if it can be added to the 'main' list
    return inv:room_for_item("main", stack)
end













--- Internal Helper: Retrieves the inventory object for the fake player.

--- Returns the total count of a specific item in the Dunce's inventory.
-- @param self The Dunce entity.
-- @param item_name The name of the item to count.
-- @return number Total count.
function ia_fake_player.actions.simple.get_item_count(self, item_name)
	minetest.log('ia_fake_player.actions.simple.get_item_count()')
    local inv = self:get_inventory()
    local count = 0
    local main_list = inv:get_list("main")

    if not main_list then return 0 end

    for _, stack in ipairs(main_list) do
        if not stack:is_empty() and stack:get_name() == item_name then
            count = count + stack:get_count()
        end
    end

    -- Also check the wielded item slot
    local wielded = self:get_wielded_item()
    if wielded:get_name() == item_name then
        count = count + wielded:get_count()
    end

    return count
end


function ia_fake_player.actions.simple.is_inventory_full(self, list_name)
    local inv = self:get_inventory()
    return not inv:room_for_item(list_name or "main", "default:dirt") -- Use a dummy common item
end




