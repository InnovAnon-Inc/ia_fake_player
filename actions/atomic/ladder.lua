-- ia_fake_player/actions/atomic/ladder.lua
-- NOTE must handle climbing up & down

-- ia_dunce/ladder.lua

--- Finds all ladders within a specific search area.
function ia_dunce.find_nearby_ladders(pos, radius, vertical_range)
    local v_range = vertical_range or 2
    local minp = vector.add(pos, {x = -radius, y = -v_range, z = -radius})
    local maxp = vector.add(pos, {x = radius, y = v_range, z = radius})

    return minetest.find_nodes_in_area(minp, maxp, {"group:ladder"})
end

--- Low-level: Is this specific position climbable?
function ia_dunce.is_climbable(pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and (def.climbable or minetest.get_item_group(node.name, "ladder") > 0)
end

--- Mid-level: Is there a ladder here and can the agent use it?
function ia_dunce.can_climb(self, pos)
    local p = pos or self:get_pos()
    return ia_dunce.is_climbable(p)
end

--- High-level: Could the agent scale this wall if they placed ladders?
function ia_dunce.could_climb(self, pos)
    if ia_dunce.can_climb(self, pos) then return true end

    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]

    -- We can only place a ladder on a walkable surface
    local is_walkable = def and def.walkable
    if is_walkable and ia_dunce.can_obtain_item(self, "group:ladder") then
        return true
    end

    return false
end

--- Level 2: Preparation + Action
-- Places a ladder from inventory and then initiates climbing.
function ia_dunce.place_and_climb(self, pos, target_y)
    local is_ladder = function(stack)
        return minetest.get_item_group(stack:get_name(), "ladder") > 0
    end

    if ia_dunce.wield_by_condition(self, is_ladder) then
        -- Place the ladder node
        if ia_dunce.right_click(self, pos, false) then
            -- Delegate to the atomic physics layer
            return ia_dunce.climb(self, target_y)
        end
    end
    return false
end

--- Level 3: Provisioning + Preparation + Action
function ia_dunce.craft_and_climb(self, pos, target_y)
    local has_ladder = ia_dunce.has_item(self, function(name)
        return minetest.get_item_group(name, "ladder") > 0
    end)

    if not has_ladder then
        if ia_dunce.can_obtain_item(self, "default:ladder_wood") then
            ia_dunce.craft_item(self, "default:ladder_wood")
        end
    end

    return ia_dunce.place_and_climb(self, pos, target_y)
end

--- Helper: Returns the traversal offset for a ladder based on its attachment wall.
-- @param pos Vector position of the ladder node
-- @return vector The offset where a mob must stand to use the ladder
function ia_dunce.get_ladder_vectors(pos)
    local node = minetest.get_node(pos)
    local p2 = node.param2

    -- Assertion to prevent logic errors in pathfinding
    assert(minetest.get_item_group(node.name, "ladder") > 0,
        "get_ladder_vectors: node at " .. minetest.pos_to_string(pos) .. " is not a ladder (" .. node.name .. ")")

    -- face_offsets map where the mob stands relative to the ladder node
    -- Standard Minetest ladder param2: 2=N, 3=S, 4=E, 5=W
    local face_offsets = {
        [2] = {x = 0, y = 0, z = 1},  -- Attached North, Stand South
        [3] = {x = 0, y = 0, z = -1}, -- Attached South, Stand North
        [4] = {x = 1, y = 0, z = 0},  -- Attached East, Stand West
        [5] = {x = -1, y = 0, z = 0}, -- Attached West, Stand East
    }

    local offset = face_offsets[p2] or {x = 0, y = 0, z = 1}
    return vector.new(offset)
end
