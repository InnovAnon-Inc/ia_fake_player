-- ia_dunce/interact.lua

----- Dispatches the correct interaction based on the target type.
--function ia_dunce.perform_arrival_action(self, target)
--	minetest.log('ia_dunce.perform_arrival_action()')
--    if not target then return end
--
--    -- If target is a dropped item
--    if target.type == "item" then
--        self:punch(target.object) -- builtin:item is "collected" via punch in many mods
--        return
--    end
--
--    -- If target is a node (like a chest or crafting bench)
--    if target.type == "node" then
--        ia_dunce.interact_with_node(self, target.pos)
--        return
--    end
--end









--- Handles the actual collection and auto-equipping of an item. -- NOTE shadows in inventory
--function ia_dunce.pickup_item(self, item_obj)
--	minetest.log('ia_dunce.pickup_item()')
--    local lua_ent = item_obj:get_luaentity()
--    if not lua_ent or lua_ent.name ~= "__builtin:item" then return end
--
--    local stack = ItemStack(lua_ent.itemstring)
--    local inv = self.fake_player:get_inventory()
--
--    if inv:room_for_item("main", stack) then
--        inv:add_item("main", stack)
--
--        -- Logic: If it's armor, try to put it on immediately
--        if armor and armor:get_element(stack:get_name()) then
--            armor:equip(self.fake_player, stack)
--        end
--
--        item_obj:remove()
--    end
--end

----- Generic arrival dispatcher
--function ia_dunce.perform_arrival_action(self, target_data)
--	minetest.log('ia_dunce.perform_arrival_action()')
--    if not target_data then return end
--
--    if target_data.type == "item" and target_data.object:get_pos() then
--        self:pickup_item(target_data.object)
--    end
--    -- Add more types (node, entity) as we develop them
--end

--- Handles the sequence of mining a node and collecting drops.
-- @param self The fake player object.
-- @param pos Node position.
-- @return boolean (Success status).
function ia_dunce.mine_and_collect(self, pos)
    minetest.log('ia_dunce.mine_and_collect()')

    -- 1. Execute the Atomic Dig
    local success = ia_dunce.dig(self, pos)

    -- 2. If successful, pick up the resulting items
    if success then
        -- We wait a tiny bit for the engine to spawn the items or
        -- just call pickup_nearby immediately.
        ia_dunce.pickup_nearby(self, 2.0)
    end

    return success
end

