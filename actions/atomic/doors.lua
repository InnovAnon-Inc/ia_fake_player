-- ia_fake_player/actions/atomic/doors.lua

--- Internal Logic Helpers (Private) ---

local function set_door_state(pos, state)
    if not minetest.get_modpath("doors") then return false end
    local door = doors.get(pos)
    if not door then return false end

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

function ia_dunce.is_doorway_clear(pos)
    local objects = minetest.get_objects_inside_radius(pos, 0.8)
    return #objects == 0
end

--- Level 0: Predicates (State & Capability) ---

function ia_dunce.is_door(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "door") > 0
end

function ia_dunce.is_door_open(pos)
    local node = minetest.get_node(pos)
    -- Doors mod uses "_c" for the open (centered) state
    return string.find(node.name, "_c") ~= nil
end

function ia_dunce.can_open_door(self, pos)
    if not ia_dunce.is_door(pos) then return false end
    local node = minetest.get_node(pos)
    local is_steel = string.find(node.name, "steel") ~= nil
    local dist = vector.distance(self:get_pos(), pos)

    if is_steel then return false end
    return dist < 1.6
end

function ia_dunce.could_use_door(self, pos)
    if ia_dunce.is_door(pos) then return true end
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if def and not def.walkable and ia_dunce.can_obtain_item(self, "group:door") then
        return true
    end
    return false
end

--- Level 1: Atomic Action ---

function ia_dunce.interact_door(self, pos, action)
    minetest.log('action', '[ia_dunce] interact_door: ' .. (action or "toggle") .. " at " .. minetest.pos_to_string(pos))
    -- Assert that we are actually interacting with a door
    assert(ia_dunce.is_door(pos), "interact_door: pos is not a door node")
    
    self._active_door_pos = vector.new(pos)
    local state_map = {open = true, close = false, toggle = nil}
    return set_door_state(pos, state_map[action])
end

--- Level 2: Preparation + Action ---

function ia_dunce.prepare_door_path(self, pos, target_state)
    local current_open = ia_dunce.is_door_open(pos)
    if current_open ~= target_state then
        return ia_dunce.interact_door(self, pos, target_state and "open" or "close")
    end
    return true
end

--- Level 3: Provisioning + Preparation + Action ---

function ia_dunce.place_and_use_door(self, pos)
    -- Placeholder for inventory/crafting logic
    if ia_dunce.has_item(self, "group:door") then
        -- Logic to wield and right_click
        return true
    end
    return false
end

--- Navigation & API Helpers (Required by ia_pathfinding) ---

-- This was the missing function causing the crash!
function ia_dunce.find_nearby_doors(pos, radius)
    local r = radius or 8 -- Using 8 as a sensible default for detours
    -- Assert sensor helper exists to prevent cascading nils
    assert(ia_dunce.get_sorted_nodes, "ia_dunce.find_nearby_doors requires ia_dunce.get_sorted_nodes")
    return ia_dunce.get_sorted_nodes(pos, r, {"group:door"})
end

function ia_dunce.get_door_vectors(pos)
    local node = minetest.get_node(pos)
    assert(minetest.get_item_group(node.name, "door") > 0, "get_door_vectors: not a door")
    
    local p2 = node.param2
    local is_open = ia_dunce.is_door_open(pos)
    local axis_offset = {x = 0, y = 0, z = 0}

    -- Param2 mapping for Minetest 'doors' mod (West, South, East, North)
    if not is_open then
        if p2 == 0 then axis_offset = {x = 0, y = 0, z = 1}
        elseif p2 == 1 then axis_offset = {x = 1, y = 0, z = 0}
        elseif p2 == 2 then axis_offset = {x = 0, y = 0, z = -1}
        elseif p2 == 3 then axis_offset = {x = -1, y = 0, z = 0}
        end
    else
        if p2 == 1 then axis_offset = {x = 0, y = 0, z = 1}
        elseif p2 == 2 then axis_offset = {x = 1, y = 0, z = 0}
        elseif p2 == 3 then axis_offset = {x = 0, y = 0, z = -1}
        elseif p2 == 0 then axis_offset = {x = -1, y = 0, z = 0}
        end
    end

    return {
        front = axis_offset,
        back = {x = -axis_offset.x, y = 0, z = -axis_offset.z}
    }
end

--- Cleanup Loop ---

function ia_dunce.process_door_cleanup(self)
    if not self._active_door_pos then return end
    local my_pos = self:get_pos()
    if not my_pos then return end

    local dist = vector.distance(my_pos, self._active_door_pos)
    if dist > 1.4 and dist < 4.0 then
        if is_doorway_clear(self._active_door_pos) then
            set_door_state(self._active_door_pos, false)
            self._active_door_pos = nil
        end
    elseif dist >= 4.0 then
        self._active_door_pos = nil
    end
end

-- mods/ia_dunce/doors.lua

-- ... (Keep the previous Level 0-3 matrix and set_door_state helper) ...

--- Scans for and handles doors in front of the Dunce.
-- This is the specific API call ia_pathfinding/doors.lua:48 is looking for.
function ia_dunce.handle_door_front(self, action)
    minetest.log('info', '[ia_dunce] handle_door_front action: ' .. (action or "open"))

    -- Assert that we have a valid object to check from
    assert(self.object, "handle_door_front: self.object is nil")

    -- Use the relative node helper (assumed to be in ia_dunce/sensors.lua)
    local front_pos = ia_dunce.get_relative_node_pos(self, 1)

    -- Check if it's actually a door before interacting
    if ia_dunce.is_door(front_pos) then
        -- Track this door for the cleanup (closing) loop
        self._active_door_pos = vector.new(front_pos)

        -- Delegate to our Level 1 atomic action
        return ia_dunce.interact_door(self, front_pos, action)
    end

    minetest.log('warning', '[ia_dunce] handle_door_front called but no door found at ' .. minetest.pos_to_string(front_pos))
    return false
end

-- FIXME THIS BELONGS IN ia_dunce/trapdoors.lua
----- Scans for and handles trapdoors in the Dunce's path (above or below).
---- Restoring this as well to ensure parity across all obstacle types.
--function ia_dunce.handle_trapdoor(self, action, direction)
--    local my_pos = self:get_pos()
--    if not my_pos then return false end
--
--    -- Check node above head (y+2) or node below feet (y)
--    local check_offset = (direction == "up") and 2 or 0
--    local target_pos = vector.round({x = my_pos.x, y = my_pos.y + check_offset, z = my_pos.z})
--
--    if ia_dunce.is_trapdoor(target_pos) then
--        self._active_door_pos = vector.new(target_pos)
--        return ia_dunce.interact_trapdoor(self, target_pos, action)
--    end
--
--    return false
--end

---- Ensure these are available for the detour logic
--function ia_dunce.find_nearby_doors(pos, radius)
--    local r = radius or 8
--    assert(ia_dunce.get_sorted_nodes, "ia_dunce.get_sorted_nodes is missing!")
--    return ia_dunce.get_sorted_nodes(pos, r, {"group:door"})
--end
