-- ia_fake_player/actions/atomic/trapdoors.lua

--- Level 0: Predicates (State & Capability)

--- Is this specific position a trapdoor?
function ia_dunce.is_trapdoor(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "trapdoor") > 0
end

--- Is the trapdoor currently open?
function ia_dunce.is_trapdoor_open(pos)
    if not minetest.get_modpath("doors") then return false end
    local door = doors.get(pos)
    return door and door:state() == true
end

--- Can the agent interact with this trapdoor right now?
-- (Checks for distance and material—steel trapdoors usually require external triggers)
function ia_dunce.can_open_trapdoor(self, pos)
    if not ia_dunce.is_trapdoor(pos) then return false end
    
    local node = minetest.get_node(pos)
    local is_steel = string.find(node.name, "steel") ~= nil
    
    -- If steel, check if we are holding a key or have access to a button/lever
    -- For now, we assume wooden trapdoors are always "can" if within range (1.5)
    local dist = vector.distance(self:get_pos(), pos)
    if is_steel then
        return dist < 1.5 and ia_dunce.has_item(self, "default:key") -- Placeholder logic
    end
    
    return dist < 1.5
end

--- Could the agent use this path if they performed an action?
-- (e.g. Crafting a trapdoor to bridge a hole, or finding a way to power a steel one)
function ia_dunce.could_use_trapdoor(self, pos)
    if ia_dunce.is_trapdoor(pos) then return true end
    
    -- Could we place one here?
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if def and not def.walkable and ia_dunce.can_obtain_item(self, "group:trapdoor") then
        return true
    end
    
    return false
end

--- Level 1: Atomic Action
-- Standard interaction via the doors API.
function ia_dunce.interact_trapdoor(self, pos, action)
    minetest.log('action', '[ia_dunce] interact_trapdoor: ' .. (action or "toggle"))
    
    -- Track for cleanup (closing behind us)
    self._active_door_pos = vector.new(pos)
    
    local state_map = {open = true, close = false, toggle = nil}
    return set_trapdoor_state(pos, state_map[action])
end

--- Level 2: Preparation + Action
-- Ensures the trapdoor is in the correct state before attempting to move through the node.
function ia_dunce.prepare_trapdoor_path(self, pos, target_state)
    local current_open = ia_dunce.is_trapdoor_open(pos)
    
    if current_open ~= target_state then
        return ia_dunce.interact_trapdoor(self, pos, target_state and "open" or "close")
    end
    
    return true
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts and places a trapdoor if a "bridge" or "seal" is needed.
function ia_dunce.place_and_use_trapdoor(self, pos)
    if not ia_dunce.has_item(self, "group:trapdoor") then
        if ia_dunce.can_obtain_item(self, "doors:trapdoor") then
            ia_dunce.craft_item(self, "doors:trapdoor")
        end
    end
    
    -- Wield and place
    if ia_dunce.wield_by_condition(self, function(s) return minetest.get_item_group(s:get_name(), "trapdoor") > 0 end) then
        return ia_dunce.right_click(self, pos, false)
    end
    
    return false
end

-- mods/ia_dunce/trapdoors.lua

--- Internal Helper: Interacts with a trapdoor at a given position.
-- @param pos The position of the trapdoor node.
-- @param state boolean: true to open, false to close, nil to toggle.
local function set_trapdoor_state(pos, state)
    minetest.log('info', '[ia_dunce] set_trapdoor_state() at ' .. minetest.pos_to_string(pos))
    if not minetest.get_modpath("doors") then return false end

    local door = doors.get(pos)
    if not door then
        minetest.log('warning', '[ia_dunce] Could not get trapdoor object at ' .. minetest.pos_to_string(pos))
        return false
    end

    local current_state = door:state()

    if state == nil then
        if current_state then door:close() else door:open() end
        return true
    elseif state ~= current_state then
        if state then door:open() else door:close() end
        return true
    end

    return false
end

--- Helper: Returns the traversal vectors (above and below) for a trapdoor.
-- @param pos Vector position of the trapdoor
-- @return table {above, below} as unit offsets
function ia_dunce.get_trapdoor_vectors(pos)
    local node = minetest.get_node(pos)
    local name = node.name

    -- Assert: Ensure we are actually looking at a trapdoor
    assert(minetest.get_item_group(name, "trapdoor") > 0, "get_trapdoor_vectors: node is not a trapdoor: " .. name)

    -- For trapdoors, the traversal is always vertical
    return {
        above = {x = 0, y = 1, z = 0},
        below = {x = 0, y = -1, z = 0}
    }
end

--- Scans for and handles trapdoors in the Dunce's path (above or below).
-- @param self The fake player object.
-- @param action "open", "close", or "toggle"
-- @param direction "up" or "down"
function ia_dunce.handle_trapdoor(self, action, direction)
    minetest.log('info', 'ia_dunce.handle_trapdoor()')
    local my_pos = self:get_pos()
    if not my_pos then return false end

    -- Check node above head (y+2) or node below feet (y)
    local check_offset = (direction == "up") and 2 or 0
    local target_pos = vector.round({x = my_pos.x, y = my_pos.y + check_offset, z = my_pos.z})
    local node = minetest.get_node(target_pos)

    if minetest.get_item_group(node.name, "trapdoor") > 0 then
        -- Track for cleanup
        self._active_door_pos = vector.new(target_pos)

        local state_map = {open = true, close = false, toggle = nil}
        return set_trapdoor_state(target_pos, state_map[action])
    end

    return false
end

--- Finds all trapdoors within a specific search area.
function ia_dunce.find_nearby_trapdoors(pos, radius)
    local r = radius or 2
    return ia_dunce.get_sorted_nodes(pos, r, {"group:trapdoor"})
end
