-- ia_dunce/bed.lua
-- NOTE must handle beds and sleeping mats
--
------ Helper: Get the direction vector from param2
----local function get_direction_from_param2(param2)
----    local dirs = {
----        [0] = {x = 0, z = 1},   -- North
----        [1] = {x = 1, z = 0},   -- East
----        [2] = {x = 0, z = -1},  -- South
----        [3] = {x = -1, z = 0},  -- West
----    }
----    return dirs[param2 % 4]
----end
----
------- Makes the mob lay down, automatically adjusting for bed parts.
------ @param self The fake player object
------ @param pos The position of the node (Head, Foot, or Mat)
----function ia_dunce.lay_down(self, pos)
----	minetest.log('ia_dunce.lay_down()')
----    local node = minetest.get_node(pos)
----    local def = minetest.registered_nodes[node.name]
----    if not def then return false end
----
----    local is_mat = node.name == "sleeping_mat:mat"
----    local target_pos = vector.new(pos)
----    local dir = get_direction_from_param2(node.param2)
----
----    -- 1. Offset Logic: Find the "Head" if we clicked the "Foot"
----    -- Standard beds use groups to identify parts.
----    if not is_mat and minetest.get_item_group(node.name, "is_bed_foot") ~= 0 then
----        -- Move target_pos to the head node based on rotation
----        target_pos = vector.add(pos, dir)
----    end
----
----    -- 2. Physics & State
----    self.object:set_velocity({x = 0, y = 0, z = 0})
----    self.object:set_properties({ physical = false })
----
----    -- 3. Positioning
----    -- Mats are flat on the floor, beds are raised.
----    local height_offset = is_mat and 0.1 or 0.4
----    self.object:set_pos({x = target_pos.x, y = target_pos.y + height_offset, z = target_pos.z})
----
----    -- 4. Rotation
----    -- We want the mob to face AWAY from the headboard (laying down)
----    -- Or align with the mat's long axis.
----    local yaw = math.atan2(dir.x, dir.z) + math.pi
----    self.object:set_yaw(yaw)
----
----    -- 5. Animation (LAY sequence)
----    --self.object:set_animation({x = 162, y = 166}, 0, 0, false)
----    ia_dunce.set_animation(self, 'LAY')
----    
----    self.data.is_sleeping = true
----    return true
----end
----
----function ia_dunce.get_up(self)
----	minetest.log('ia_dunce.get_up()')
----    self.object:set_properties({ physical = true })
----    --self.object:set_animation({x = 0, y = 79}, 30, 0, true) -- STAND
----    ia_dunce.set_animation(self, 'STAND')
----
----    -- Shift them slightly so they don't spawn 'inside' the bed frame
----    local pos = self.object:get_pos()
----    self.object:set_pos({x = pos.x, y = pos.y + 0.5, z = pos.z})
----
----    self.data.is_sleeping = false
----    return true
----end
--
---- Helper: Get the direction vector from param2
--
--
----- Makes the mob lay down, automatically adjusting for bed parts.
--function ia_dunce.lay_down(self, pos) -- TODO in lay.lua
--	minetest.log('ia_dunce.lay_down()')
--    local node = minetest.get_node(pos)
--    local def = minetest.registered_nodes[node.name]
--    if not def then return false end
--
--    local is_mat = node.name == "sleeping_mat:mat"
--    local target_pos = vector.new(pos)
--    local dir = get_direction_from_param2(node.param2)
--
--    -- 1. Offset Logic: Find the "Head"
--    if not is_mat and minetest.get_item_group(node.name, "is_bed_foot") ~= 0 then
--        target_pos = vector.add(pos, dir)
--    end
--
--    -- 2. State & Physics
--    ia_dunce.stop(self)
--    ia_dunce.set_lay_posture(self, true)
--
--    -- 3. Positioning
--    local height_offset = is_mat and 0.05 or 0.4
--    self.object:set_pos({x = target_pos.x, y = target_pos.y + height_offset, z = target_pos.z})
--
--    -- 4. Rotation: Align with bed axis
--    local yaw = math.atan2(dir.x, dir.z) + math.pi
--    self.object:set_yaw(yaw)
--
--    self.data.is_sleeping = true
--    return true
--end
--
----- Handles waking up and clearing the bed obstruction.
--function ia_dunce.get_up(self) -- TODO in lay.lua
--	minetest.log('ia_dunce.get_up()')
--    if not self.data.is_sleeping then return false end
--
--    local current_pos = self.object:get_pos()
--
--    -- 1. Restore Physics and Animation
--    ia_dunce.set_lay_posture(self, false)
--
--    -- 2. Edge Case: Obstruction Handling
--    -- Find a safe spot so we don't stand up "into" the wall or bed headboard
--    local safe_pos = find_safe_wakeup_pos(vector.round(current_pos))
--    self.object:set_pos(safe_pos)
--
--    self.data.is_sleeping = false
--    return true
--end
--
--
----- Finds the closest bed or sleeping mat.
--function ia_dunce.find_closest_bed(self, radius)
--    local pos = self.object:get_pos()
--    local beds = ia_dunce.get_sorted_nodes(pos, radius, {"group:bed", "sleeping_mat:mat"})
--    return beds[1] -- Return closest
--end
-- ia_dunce/bed.lua

--- Low-level: Is this node a bed or mat?
function ia_dunce.is_bed(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "bed") > 0 or node.name == "sleeping_mat:mat"
end

--- Mid-level: Is there a bed we can actually use?
-- Checks for ownership, headspace, and valid bed parts.
function ia_dunce.can_sleep(self, pos)
    if not ia_dunce.is_bed(pos) then return false end
    
    -- Check for headspace (2 nodes of air above the bed)
    local above_1 = {x=pos.x, y=pos.y+1, z=pos.z}
    local above_2 = {x=pos.x, y=pos.y+2, z=pos.z}
    if minetest.get_node(above_1).name ~= "air" then return false end

    -- Ownership check (if the mod supports it)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    if owner ~= "" and owner ~= self.name then return false end

    return true
end

--- High-level: Could we sleep if we crafted/placed a bed?
function ia_dunce.could_sleep(self, pos)
    -- 1. Can we sleep right now?
    if ia_dunce.can_sleep(self, pos) then return true end

    -- 2. Could we place one at this location?
    -- Requires 2 blocks of flat space and 2 blocks of air.
    if ia_dunce.is_buildable(pos) and ia_dunce.can_obtain_item(self, "group:bed") then
        return true
    end

    return false
end

--- Level 1: Atomic Action (Lay down on existing bed)
function ia_dunce.lay_down(self, pos)
    minetest.log('ia_dunce.lay_down()')
    local node = minetest.get_node(pos)
    local dir = ia_dunce.get_direction_from_param2(node.param2)
    local target_pos = vector.new(pos)

    -- Offset Logic: Find the "Head" if we clicked the "Foot"
    if minetest.get_item_group(node.name, "is_bed_foot") ~= 0 then
        target_pos = vector.add(pos, dir)
    end

    ia_dunce.stop(self)
    ia_dunce.set_lay_posture(self, true)

    -- Mats are flat, beds are raised
    local is_mat = node.name == "sleeping_mat:mat"
    local height_offset = is_mat and 0.05 or 0.4
    
    self.object:set_pos({x = target_pos.x, y = target_pos.y + height_offset, z = target_pos.z})
    self.object:set_yaw(math.atan2(dir.x, dir.z) + math.pi)

    self.data.is_sleeping = true
    return true
end

--- Level 2: Preparation + Action (Find/Place then Sleep)
function ia_dunce.place_and_sleep(self, pos)
    minetest.log('ia_dunce.place_and_sleep()')
    
    local is_bed_item = function(n) return minetest.get_item_group(n, "bed") > 0 end
    if ia_dunce.wield_by_condition(self, is_bed_item) then
        local success = ia_dunce.right_click(self, pos, false)
        if success then
            return ia_dunce.lay_down(self, pos)
        end
    end
    return false
end

--- Level 3: Provisioning + Preparation + Action
function ia_dunce.craft_and_sleep(self, pos)
    minetest.log('ia_dunce.craft_and_sleep()')
    
    if not ia_dunce.has_item(self, function(n) return minetest.get_item_group(n, "bed") > 0 end) then
        if ia_dunce.can_obtain_item(self, "default:bed") then
            ia_dunce.craft_item(self, "default:bed")
        end
    end
    
    return ia_dunce.place_and_sleep(self, pos)
end

--- Handles waking up and clearing the bed obstruction.
function ia_dunce.get_up(self)
    minetest.log('ia_dunce.get_up()')
    if not self.data.is_sleeping then return false end

    ia_dunce.set_lay_posture(self, false)

    -- Move to a safe adjacent spot to avoid getting stuck in the bed node
    local safe_pos = ia_dunce.find_safe_wakeup_pos(vector.round(self.object:get_pos()))
    self.object:set_pos(safe_pos)

    self.data.is_sleeping = false
    return true
end
