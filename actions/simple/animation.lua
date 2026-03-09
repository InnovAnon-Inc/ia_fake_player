-- ia_fake_player/actions/simple/animation.lua

ia_fake_player.actions.simple.animation_frames = {
    STAND     = { x =   0, y =  79, },
    LAY       = { x = 162, y = 166, },
    WALK      = { x = 168, y = 187, },
    MINE      = { x = 189, y = 198, },
    WALK_MINE = { x = 200, y = 219, },
    SIT       = { x =  81, y = 160, },

    PUNCH     = { x = 189, y = 191, },
    EAT       = { x = 190, y = 198, },
    GREET     = { x =   0, y =  79, },
    DEATH     = { x = 162, y = 166, },
}

--- Updates the entity animation only if the state has changed.
-- @param self The entity.
-- @param state The string key from ia_fake_player.actions.simple.animation_frames (e.g., "WALK")
-- @param speed Animation speed (default 30)
-- @param loop Whether the animation should repeat (default true)
function ia_fake_player.actions.simple.set_animation(self, state, speed, loop)
	--minetest.log('ia_fake_player.actions.simple.set_animation()')
    local frames = ia_fake_player.actions.simple.animation_frames[state]
    if not frames then return end

    -- Default loop to true if not provided
    if loop == nil then loop = true end

    -- Only update if the state is actually different
    -- (Note: We skip the check for non-looping animations so they can be re-triggered)
    if self._current_animation == state and loop then
        return
    end

    self._current_animation = state
    self:set_animation(frames, speed or 30, 0, loop)
end
