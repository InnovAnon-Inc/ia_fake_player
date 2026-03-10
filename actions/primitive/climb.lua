-- ia_fake_player/actions/primitive/climb.lua
-- NOTE must handle climbing up & down

--- Predicate: Is the mob currently in a climbing state?
function ia_fake_player.actions.primitive.is_climbing(self)
    return self._is_climbing == true
end

--- Predicate: Is the mob at a height where it can stop climbing up?
function ia_fake_player.actions.primitive.is_at_climb_up_target(self, target_y)
    local pos = self:get_pos()
    if not pos then return false end
    -- We've reached or exceeded the target height
    return pos.y >= (target_y - 0.2)
end

--- Predicate: Is the mob at a height where it can stop climbing down?
function ia_fake_player.actions.primitive.is_at_climb_down_target(self, target_y)
    local pos = self:get_pos()
    if not pos then return false end
    -- We've reached or gone below the target height
    return pos.y <= (target_y + 0.2)
end

--- Atomic Action: Physics for ascending a climbable node.
-- @param target_y The height we are aiming for.
function ia_fake_player.actions.primitive.climb_up(self, target_y)
    local pos = self:get_pos()
    if not pos or not ia_fake_player.actions.primitive.is_climbable(pos) then
        self._is_climbing = false
        return false
    end

    local v = self:get_velocity()
    local above = vector.add(pos, {x=0, y=1, z=0})

    -- Ledge Clearing: If there is no more ladder above and we are near target
    if not ia_fake_player.actions.primitive.is_climbable(above) and pos.y >= (target_y - 0.5) then
        local yaw = self:get_yaw()
        local dir = {x = -math.sin(yaw), z = math.cos(yaw)}
        -- Vault over the top
        self:set_velocity({x = dir.x * 2.2, y = 2.0, z = dir.z * 2.2})
    else
        -- Standard upward ascent
        self:set_velocity({x = v.x, y = 2.0, z = v.z})
    end

    if not self._is_climbing then
        ia_fake_player.actions.primitive.set_animation(self, 'CLIMB')
        self._is_climbing = true
    end
    return true
end

--- Atomic Action: Physics for descending a climbable node.
-- @param target_y The height we want to reach (floor level).
function ia_fake_player.actions.primitive.climb_down(self, target_y)
    local pos = self:get_pos()
    if not pos or not ia_fake_player.actions.primitive.is_climbable(pos) then
        self._is_climbing = false
        return false
    end

    local v = self:get_velocity()

    -- Controlled descent
    self:set_velocity({x = v.x, y = -3.0, z = v.z})

    if not self._is_climbing then
        ia_fake_player.actions.primitive.set_animation(self, 'CLIMB')
        self._is_climbing = true
    end
    return true
end

--- General wrapper to maintain compatibility with existing bridge calls.
-- Logic is now delegated to the specific atomic actions.
function ia_fake_player.actions.primitive.climb(self, target_y)
    local pos = self:get_pos()
    if not pos then return false end

    if target_y and target_y < pos.y - 0.5 then
        return ia_fake_player.actions.primitive.climb_down(self, target_y)
    else
        -- Default to up if no target or target is above
        return ia_fake_player.actions.primitive.climb_up(self, target_y or (pos.y + 1))
    end
end
