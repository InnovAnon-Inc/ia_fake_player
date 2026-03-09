-- ia_fake_player/actions/simple/walk.lua

--- Level 1: Atomic Action (Physics)
-- Moves the mob toward a target position and updates its rotation.
function ia_fake_player.actions.simple.walk(self, target_pos)
    local my_pos = self:get_pos()
    if not my_pos or not target_pos then return false end

    -- 1. Calculate Direction and Distance
    local vec = {
        x = target_pos.x - my_pos.x,
        y = 0, -- Horizontal movement only
        z = target_pos.z - my_pos.z
    }
    local dist = vector.length(vec)
    
    -- 2. Update Yaw (Rotation)
    if dist > 0.1 then
        local yaw = math.atan2(-vec.x, vec.z)
        self:set_yaw(yaw)
    end

    -- 3. Apply Velocity
    -- Using a standard speed of 3.0; can be made dynamic based on self.speed
    local speed = self.speed or 3.0
    local v = self:get_velocity()
    
    if dist > 0.2 then
        local move_vec = vector.multiply(vector.normalize(vec), speed)
        self:set_velocity({x = move_vec.x, y = v.y, z = move_vec.z})
        ia_fake_player.actions.simple.set_animation(self, 'WALK')
        return true
    else
        -- We are essentially there, stop horizontal movement
        ia_fake_player.actions.simple.stop(self)
        return false
    end
end
