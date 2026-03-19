-- ia_fake_player/actions/primitive/use.lua

--- Uses the currently wielded item on a target position (e.g., tilling soil).
-- @param self The fake player object
-- @param pos The target position
-- @return boolean (Success status)
function ia_fake_player.actions.primitive.use(self, pos)
	minetest.log('ia_fake_player.actions.primitive.use()')
    local stack = self:get_wielded_item()
    if stack:is_empty() then
        return false
    end

    local def = stack:get_definition()
    if not def or not def.on_use then
        -- If it doesn't have an on_use, maybe it's a placeable item?
        -- We could fallback to ia_fake_player.actions.primitive.place(self, pos) here if we wanted.
        return false
    end

    -- 1. Orientation
    local dir = vector.direction(self:get_pos(), pos)
    self:set_look_horizontal(math.atan2(-dir.x, dir.z))

    -- 2. Execution
    -- We pass (stack, user, pointed_thing) just like the engine does.
    local pointed_thing = ia_fake_player.actions.primitive.get_pointed_node(pos)
    
    -- IMPORTANT: Luanti's on_use returns the itemstack that should 
    -- replace the current one (handling wear/consumption).
    local new_stack = def.on_use(stack, self, pointed_thing)

    -- 3. Update Inventory
    -- If the function returned a stack, use it. Otherwise, keep the old one.
    if new_stack then
        self:set_wielded_item(new_stack)
    end

    -- TODO
    -- 4. Feedback
    --self:set_animation({x = 160, y = 200}, 30, 0, true) -- Interaction/Mine animation
    ia_fake_player.actions.primitive.set_animation(self, 'MINE', 40, false)
    
    return true
end

--- Mimics a player consuming/using an item from their inventory.
function ia_fake_player.actions.primitive.use_item(self, item_name)
	minetest.log('ia_fake_player.actions.primitive.use_item('..item_name..')')
	local inv = self:get_inventory()

	-- We remove one to 'use' it
	local stack = inv:remove_item("main", ItemStack(item_name))
	if stack:is_empty() then return false end

	local def = core.registered_items[item_name]
	if def and def.on_use then
		-- Pointed_thing is 'nothing' for self-consumption
		local leftover = def.on_use(stack, self.fake_player, {type="nothing"})
		if leftover then inv:add_item("main", leftover) end
		return true
	end

	-- If no on_use, put it back
	inv:add_item("main", stack)
	return false
end
