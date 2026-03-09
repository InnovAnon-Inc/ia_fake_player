-- ia_dunce/is_stuck.lua

function ia_dunce.is_stuck(self)
    local my_pos = self.object:get_pos()
    if not my_pos or not self._last_pos then return false end

    -- Only check for being stuck if the mob is actually trying to walk/move
    local v = self.object:get_velocity()
    local horizontal_vel = vector.length({x = v.x, y = 0, z = v.z})

    if horizontal_vel > 0.1 then
        local dist = vector.distance(my_pos, self._last_pos)
        -- If we moved less than 0.05 meters in a tick while trying to move
        if dist < 0.05 then
            self._stuck_ticks = (self._stuck_ticks or 0) + 1
        else
            self._stuck_ticks = 0
        end
    else
        self._stuck_ticks = 0
    end

    -- Return true if we've been stagnant for ~1 second (assuming 20fps)
    return (self._stuck_ticks or 0) > 20
end
