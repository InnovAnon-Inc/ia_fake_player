-- ia_fake_player/actions/simple/fall.lua

--- Logic for detecting and reacting to falling.
function ia_fake_player.actions.simple.fall(self)
	--minetest.log('ia_fake_player.actions.simple.fall()')
    local v = self:get_velocity()
    if not v then return false end

    -- If descending faster than a certain threshold
    if v.y < -4.0 then
        -- Trigger "Panic" state or "FALL" animation
        ia_fake_player.actions.simple.set_animation(self, 'FALL')
        
        -- Future-proofing: Look for water or hay blocks below to steer toward
        return true
    end

    return false
end

function ia_fake_player.actions.simple.is_falling(self)
    local v = self:get_velocity()
    if v.y >= -1.0 then return false end -- Not falling fast enough

    local pos = self:get_pos()
    local ground = ia_fake_player.actions.simple.find_ground_level(pos, 0, 2)
    return ground == nil -- No ground immediately beneath
end
