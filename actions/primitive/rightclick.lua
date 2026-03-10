-- ia_fake_player/actions/primitive/rightclick.lua

--- Mimics a player right-clicking a node.
-- @param self The fake player object
-- @param pos The position of the node
-- @param sneak boolean: If true, forces item placement (skips node interaction)
-- @return boolean (Whether an interaction occurred)
function ia_fake_player.actions.primitive.right_click(self, pos, sneak)
	minetest.log('ia_fake_player.actions.primitive.rightclick()')
    -- 1. Setup Control State
    -- We temporarily set the sneak control so engine callbacks (like on_rightclick)
    -- see the Dunce as "sneaking".
    self.data.controls.sneak = sneak == true

    -- 2. Orientation
    local dir = vector.direction(self:get_pos(), pos)
    self:set_look_horizontal(math.atan2(-dir.x, dir.z))

    -- 3. Interaction Logic
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    local stack = self:get_wielded_item()
    local pointed_thing = {type = "node", under = pos, above = pos}

    local success = false

    -- Logic: If NOT sneaking, try the node's interaction first
    if not sneak and def and def.on_rightclick then
        local new_stack = def.on_rightclick(pos, node, self, stack, pointed_thing)
        if new_stack then self:set_wielded_item(new_stack) end
        success = true
    else
        -- If sneaking OR node has no right-click, try to place/use the held item
        success = ia_fake_player.actions.primitive.place(self, pos)
    end

    -- 4. Cleanup & Feedback
    if success then
        --self:set_animation({x = 160, y = 200}, 30, 0, true)
	ia_fake_player.actions.primitive.set_animation(self, "MINE", 40, false)
    end
    
    -- Reset sneak state so the Dunce doesn't stay "crouched"
    self.data.controls.sneak = false
    
    return success
end
