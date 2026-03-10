-- ia_fake_player/actions/primitive/place.lua

--- Generic wrapper for placing a block or using an item (like a hoe).
-- @param self The Dunce entity.
-- @param pos The position to place 'against' or 'on'.
-- @return boolean (Success).
function ia_fake_player.actions.primitive.place(self, pos)
    minetest.log('ia_fake_player.actions.primitive.place()')
    local stack = self:get_wielded_item()
    if stack:is_empty() then return false end

    -- Determine where we are placing (usually 'above' the node we clicked)
    -- This follows standard Minetest 'under' and 'above' logic.
    local pointed_thing = {
        type = "node",
        under = pos,
        above = vector.add(pos, {x = 0, y = 1, z = 0})
    }

    -- 1. Check protection using fake_player identity
    if minetest.is_protected(pointed_thing.above, self:get_player_name()) then
        return false, "protected"
    end

    -- 2. Call the item's placement/usage logic
    -- This triggers hoes, torches, and block placement.
    local leftover, success = minetest.item_place(stack, self.fake_player, pointed_thing)

    if success then
        self:set_wielded_item(leftover)

        -- Feedback
        local node_name = stack:get_name()
        ia_fake_player.actions.primitive.play_node_sound(node_name, pointed_thing.above, "place")
        ia_fake_player.actions.primitive.set_animation(self, "MINE", 40, false)
    end

    return success
end
