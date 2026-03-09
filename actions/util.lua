-- ia_dunce/util.lua

-- Helper: Build a pointed_thing for a node target
function ia_dunce.get_pointed_node(pos)
    return {
        type = "node",
        under = pos,
        above = pos -- For 'use', under and above are often the same node
    }
end

--- Stops all movement and faces a target.
function ia_dunce.stop_and_look_at(self, pos)
    self.object:set_velocity({x=0, y=0, z=0})
    ia_dunce.face_pos(self, pos)
end

--- Forces the Dunce to face a specific coordinate.
--function ia_dunce.face_pos(self, target_pos)
--    local my_pos = self.object:get_pos()
--    local dir = vector.direction(my_pos, target_pos)
--    -- Standard Luanti yaw: atan2(-x, z)
--    self.object:set_yaw(math.atan2(-dir.x, dir.z))
--end

--- Calculates a unit vector based on current yaw.
--function ia_dunce.get_dir(self)
--    return minetest.yaw_to_dir(self.object:get_yaw())
--end

--- Returns a standard pointed_thing for node interactions.
function ia_dunce.get_pointed_thing(pos, above_pos)
    return {
        type = "node",
        under = pos,
        above = above_pos or pos
    }
end

--- Gets a node position relative to current facing.
--function ia_dunce.get_relative_node_pos(self, distance, height_offset)
--    local dir = ia_dunce.get_dir(self)
--    dir.y = 0 -- Keep calculations on the horizontal plane
--
--    local offset = vector.multiply(vector.normalize(dir), distance or 1)
--    local final_pos = vector.add(self.object:get_pos(), offset)
--
--    if height_offset then
--        final_pos.y = final_pos.y + height_offset
--    end
--
--    return vector.round(final_pos)
--end

--- Range check with eye-height adjustment.
function ia_dunce.is_within_reach(self, target_pos, range)
    local my_pos = self.object:get_pos()
    my_pos.y = my_pos.y + 1.5 -- Eye level
    return vector.distance(my_pos, target_pos) <= (range or 5)
end

--- Checks if a node can be replaced (air, grass, etc.)
--function ia_dunce.is_buildable(pos)
--    local node = minetest.get_node(pos)
--    local def = minetest.registered_nodes[node.name]
--    return def and def.buildable_to or false
--end

--- Retrieves node walkability and actual collision height.
--function ia_dunce.get_node_properties(node_name)
--    local def = minetest.registered_nodes[node_name]
--    if not def then return false, 0 end
--    if not def.walkable then return false, 0 end
--
--    local height = 1.0
--    if def.collision_box and def.collision_box.type == "fixed" then
--        local boxes = def.collision_box.fixed
--        -- Handle both single box and array of boxes
--        if type(boxes[1]) == "table" then
--            for _, box in ipairs(boxes) do
--                height = math.max(height, box[5])
--            end
--        else
--            height = boxes[5]
--        end
--    end
--    return true, height
--end





----- Finds the walkable surface at a given x/z coordinate relative to a height.
---- @param pos The position to check.
---- @param jump_max Max height the Dunce can climb.
---- @param fall_max Max height the Dunce can drop.
---- @return table|nil The adjusted position or nil if impassable.
----function ia_dunce.find_ground_level(pos, jump_max, fall_max)
----    local p = vector.new(pos)
----    local node = minetest.get_node(p)
----
----    -- If inside a solid block, try to move UP (climbing)
----    if ia_dunce.is_walkable(node) then
----        for i = 1, jump_max do
----            p.y = p.y + 1
----            node = minetest.get_node(p)
----            if not ia_dunce.is_walkable(node) then return p end
----        end
----        return nil -- Too high to climb
----    end
----
----    -- If in air, try to move DOWN (dropping)
----    for i = 1, fall_max do
----        p.y = p.y - 1
----        node = minetest.get_node(p)
----        if ia_dunce.is_walkable(node) then
----            return {x = p.x, y = p.y + 1, z = p.z}
----        end
----    end
----
----    return nil -- Too deep to fall safely
----end
--
--
--
--
----- util.lua
--
----- Finds a solid surface by checking up and down from a point.
---- Used by the pathfinder to allow jumping and falling.
--function ia_dunce.find_ground_level(pos, max_up, max_down)
--    local p = vector.round(pos)
--
--    -- Check from top down (prioritize the highest walkable surface)
--    for y = max_up, -max_down, -1 do
--        local check_pos = {x = p.x, y = p.y + y, z = p.z}
--        local node_under = minetest.get_node(check_pos)
--        local node_above = minetest.get_node({x = check_pos.x, y = check_pos.y + 1, z = check_pos.z})
--        local node_head  = minetest.get_node({x = check_pos.x, y = check_pos.y + 2, z = check_pos.z})
--
--        -- A valid "ground" is:
--        -- 1. Solid node below feet
--        -- 2. Buildable (air/grass) at leg level
--        -- 3. Buildable (air/grass) at head level
--        if ia_dunce.get_node_properties(node_under.name) and
--           ia_dunce.is_buildable(node_above) and
--           ia_dunce.is_buildable(node_head) then
--            return check_pos
--        end
--    end
--    return nil
--end




--- Gets the unit vector of where the Dunce is currently looking.
function ia_dunce.get_look_vector(self)
    local yaw = self.object:get_yaw()
    if not yaw then return {x = 0, y = 0, z = 0} end
    -- Convert yaw to a direction vector
    return {
        x = -math.sin(yaw),
        y = 0,
        z = math.cos(yaw)
    }
end

--- Determines if an entity is physically solid and likely to obstruct movement.
-- @param obj The object (player or luaentity) to check.
-- @return boolean
--function ia_dunce.is_obstructive(obj)
--    if not obj or not obj:get_pos() then return false end
--
--    -- 1. Players are always physical obstacles.
--    if obj:is_player() then return true end
--
--    -- 2. Check engine properties for Lua entities.
--    local props = obj:get_properties()
--    if props and props.physical then
--        -- We ignore things with tiny collision boxes (like dropped items)
--        -- even if they are 'physical', as they don't really block a Dunce.
--        local box = props.collisionbox
--        if box and (math.abs(box[4] - box[1]) < 0.2) then
--            return false
--        end
--        return true
--    end
--
--    return false
--end
--- Checks if a node is occupied by a stationary, solid obstacle.
--function ia_dunce.is_node_occupied(pos, ignore_self)
--    -- A 0.5 radius covers the center of the node.
--    local objs = minetest.get_objects_inside_radius(pos, 0.5)
--
--    for _, obj in ipairs(objs) do
--        if obj ~= ignore_self and ia_dunce.is_obstructive(obj) then
--            local v = obj:get_velocity()
--            -- We only treat it as an A* 'obstacle' if it is stationary.
--            -- If it's moving, our steering/avoidance logic handles it instead.
--            if v and vector.length(v) < 0.1 then
--                return true
--            end
--        end
--    end
--    return false
--end






--- Checks if a target position is likely reachable (not buried or floating).
-- @param pos The target position.
-- @return boolean
function ia_dunce.is_target_accessible(pos)
    if not pos then return false end

    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]

    -- Edge Case: Is the target inside a solid block? (e.g., an item fell into a wall)
    if def and def.walkable and not (minetest.get_item_group(node.name, "door") > 0) then
        -- If it's a solid block and not a door, we can't "arrive" there.
        return false
    end

    -- Edge Case: Is there air/space to stand at the target?
    local head_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
    if ia_dunce.get_node_properties(minetest.get_node(head_pos).name) then
        -- If head level is blocked by a non-walkable solid, it's a tight squeeze or buried.
        -- (Using your existing get_node_properties logic)
        return false
    end

    return true
end




--- Checks if a target object is still valid and hasn't been picked up/deleted.
-- @param obj The object to validate.
-- @return boolean
--function ia_dunce.is_valid_object(obj)
--    -- Check if object exists and is not a "null" userdata
--    if not obj or type(obj) ~= "userdata" or not obj:get_pos() then
--        return false
--    end
--
--    -- If it's a dropped item, ensure it hasn't been collected
--    local ent = obj:get_luaentity()
--    if ent and ent.name == "__builtin:item" then
--        -- In some mods, items get 'removed' but the object persists for a frame
--        if ent.itemstring == "" then return false end
--    end
--
--    return true
--end



































































--- Forces the Dunce to face a specific coordinate.
function ia_dunce.face_pos(self, target_pos)
    local my_pos = self.object:get_pos()
    if not my_pos or not target_pos then return end

    local dir = vector.direction(my_pos, target_pos)
    -- Standard Luanti yaw calculation: atan2(-x, z)
    self.object:set_yaw(math.atan2(-dir.x, dir.z))
end

--- Calculates a unit vector based on current yaw.
function ia_dunce.get_dir(self)
    local yaw = self.object:get_yaw()
    if not yaw then return {x = 0, y = 0, z = 0} end
    return minetest.yaw_to_dir(yaw)
end

--- Gets a node position relative to current facing.
function ia_dunce.get_relative_node_pos(self, distance, height_offset)
    local my_pos = self.object:get_pos()
    if not my_pos then return nil end

    local dir = ia_dunce.get_dir(self)
    dir.y = 0 -- Keep calculations on the horizontal plane

    local offset = vector.multiply(vector.normalize(dir), distance or 1)
    local final_pos = vector.add(my_pos, offset)

    if height_offset then
        final_pos.y = final_pos.y + height_offset
    end

    return vector.round(final_pos)
end

--- Checks if a node can be replaced (air, grass, etc.)
function ia_dunce.is_buildable(pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.buildable_to or false
end

--- Retrieves node walkability and actual collision height.
function ia_dunce.get_node_properties(node_name)
    local def = minetest.registered_nodes[node_name]
    if not def then return false, 0 end
    if not def.walkable then return false, 0 end

    local height = 1.0
    if def.collision_box and def.collision_box.type == "fixed" then
        local boxes = def.collision_box.fixed
        if type(boxes[1]) == "table" then
            for _, box in ipairs(boxes) do
                height = math.max(height, box[5])
            end
        else
            height = boxes[5]
        end
    end
    return true, height
end

--- Finds a solid surface by checking up and down from a point.
-- Used by the pathfinder to allow jumping and falling.
function ia_dunce.find_ground_level(pos, max_up, max_down)
    local p = vector.round(pos)

    for y = max_up, -max_down, -1 do
        local check_pos = {x = p.x, y = p.y + y, z = p.z}
        local node_under = minetest.get_node(check_pos)
        local node_above = minetest.get_node({x = check_pos.x, y = check_pos.y + 1, z = check_pos.z})
        local node_head  = minetest.get_node({x = check_pos.x, y = check_pos.y + 2, z = check_pos.z})

        if ia_dunce.get_node_properties(node_under.name) and
           ia_dunce.is_buildable(node_above) and
           ia_dunce.is_buildable(node_head) then
            return check_pos
        end
    end
    return nil
end

--- Determines if an entity is physically solid.
function ia_dunce.is_obstructive(obj)
    if not obj or not obj:get_pos() then return false end
    if obj:is_player() then return true end

    local props = obj:get_properties()
    if props and props.physical then
        local box = props.collisionbox
        -- Ignore small items
        if box and (math.abs(box[4] - box[1]) < 0.2) then
            return false
        end
        return true
    end
    return false
end

--- Checks if a node is occupied by a stationary, solid obstacle.
function ia_dunce.is_node_occupied(pos, ignore_self)
    local objs = minetest.get_objects_inside_radius(pos, 0.5)
    for _, obj in ipairs(objs) do
        if obj ~= ignore_self and ia_dunce.is_obstructive(obj) then
            local v = obj:get_velocity()
            -- Stationary entities are A* obstacles; moving ones are side-stepped.
            if v and vector.length(v) < 0.1 then
                return true
            end
        end
    end
    return false
end

--- Checks if a target object is still valid in the world.
function ia_dunce.is_valid_object(obj)
    if not obj or type(obj) ~= "userdata" then return false end
    if not obj:get_pos() then return false end

    local ent = obj:get_luaentity()
    if ent and ent.name == "__builtin:item" and ent.itemstring == "" then
        return false
    end
    return true
end

function ia_dunce.apply_vertical_impulse(self, power)
    local v = self.object:get_velocity()
    if not v then return end

    self.object:set_velocity({
        x = v.x,
        y = power,
        z = v.z
    })
end








-- ia_dunce/util.lua

--- Logic for determining if an object is a threat.
-- This is a placeholder that can be expanded by mods using ia_dunce.
function ia_dunce.is_hostile(self, object)
    -- If it's a player, maybe they are hostile if holding a sword?
    if object:is_player() then
        local item = object:get_wielded_item():get_name()
        if minetest.get_item_group(item, "weapon") > 0 then
            return true
        end
    end

    -- Check for entity-specific hostility flags
    local lua_ent = object:get_luaentity()
    if lua_ent and lua_ent._is_hostile then
        return true
    end

    return false
end



function ia_dunce.get_direction_from_param2(param2)
    local dirs = {
        [0] = {x = 0, z = 1},   -- North
        [1] = {x = 1, z = 0},   -- East
        [2] = {x = 0, z = -1},  -- South
        [3] = {x = -1, z = 0},  -- West
    }
    return dirs[param2 % 4]
end
--- Internal: Finds a safe spot next to the bed to stand up.
function ia_dunce.find_safe_wakeup_pos(pos)
	minetest.log('ia_dunce.find_safe_wakeup_pos()')
    -- Check 4 cardinal directions around the bed
    local neighbors = {
        {x=1, y=0, z=0}, {x=-1, y=0, z=0},
        {x=0, y=0, z=1}, {x=0, y=0, z=-1}
    }
    for _, offset in ipairs(neighbors) do
        local check_pos = vector.add(pos, offset)
        local node = minetest.get_node(check_pos)
        local head_node = minetest.get_node({x=check_pos.x, y=check_pos.y+1, z=check_pos.z})

        -- If the floor is walkable and there is air for the head/body
        if ia_dunce.is_buildable(check_pos) and ia_dunce.is_buildable(head_node) then
            return check_pos
        end
    end
    return vector.add(pos, {x=0, y=0.5, z=0}) -- Fallback: pop up slightly
end
