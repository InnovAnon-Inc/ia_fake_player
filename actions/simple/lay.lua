-- ia_fake_player/actions/simple/lay.lua

--function ia_fake_player.actions.simple.lay(self)
--	minetest.log('ia_fake_player.actions.simple.lay()')
--    -- Reduce collision box height for laying down
--    self:set_properties({
--        collisionbox = {-0.3, 0, -0.3, 0.3, 0.5, 0.3},
--    })
--    ia_fake_player.actions.simple.set_animation(self, 'LAY')
--end
--
----- Sets the mob into a laying posture.
---- @param self The entity object.
---- @param state boolean: true to lay down, false to stand up.
--function ia_fake_player.actions.simple.set_lay_posture(self, state)
--	minetest.log('ia_fake_player.actions.simple.set_lay_posture()')
--    if state then
--        -- Lower collision box for laying down
--        self:set_properties({
--            collisionbox = {-0.3, 0, -0.3, 0.3, 0.5, 0.3},
--            physical = false -- Usually disabled while in a bed to prevent "shaking"
--        })
--        ia_fake_player.actions.simple.set_animation(self, 'LAY')
--        self.data.is_laying = true
--    else
--        -- Restore standard collision box (adjust values to your default mob size)
--        self:set_properties({
--            collisionbox = {-0.3, 0, -0.3, 0.3, 1.7, 0.3},
--            physical = true
--        })
--        ia_fake_player.actions.simple.set_animation(self, 'STAND')
--        self.data.is_laying = false
--    end
--end

--- Sets the mob into a laying posture (animations and collision).
-- @param self The entity object.
-- @param state boolean: true to lay down, false to stand up.
function ia_fake_player.actions.simple.set_lay_posture(self, state)
    minetest.log('ia_fake_player.actions.simple.set_lay_posture()')
    if state then
        -- Lower collision box for laying down
        self:set_properties({
            collisionbox = {-0.3, 0, -0.3, 0.3, 0.5, 0.3},
            physical = false -- Usually disabled while laying to prevent "jitter"
        })
        ia_fake_player.actions.simple.set_animation(self, 'LAY')
        self.data.is_laying = true
    else
        -- Restore standard collision box (standard human height)
        self:set_properties({
            collisionbox = {-0.3, 0, -0.3, 0.3, 1.7, 0.3},
            physical = true
        })
        ia_fake_player.actions.simple.set_animation(self, 'STAND')
        self.data.is_laying = false
    end
end
