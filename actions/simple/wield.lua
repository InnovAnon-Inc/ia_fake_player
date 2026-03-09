-- ia_fake_player/actions/simple/wield.lua



--- Swaps current wielded item with an item from 'main' inventory.
-- @param self The fake player object.
-- @param condition function(name) or string (itemname).
-- @return boolean (Success status).
function ia_fake_player.actions.simple.wield_by_condition(self, condition)
	minetest.log('ia_fake_player.actions.simple.wield_by_condition()')
    local inv = self:get_inventory()
    local main_list = inv:get_list("main")
    
    local predicate = type(condition) == "string" 
        and function(name) return name == condition end 
        or condition

    for i, stack in ipairs(main_list) do
        if not stack:is_empty() and predicate(stack:get_name()) then
            -- Use official methods to swap safely
            local current_hand_stack = self:get_wielded_item()
            self:set_wielded_item(stack)
            inv:set_stack("main", i, current_hand_stack)
            return true
        end
    end
    return false
end





















