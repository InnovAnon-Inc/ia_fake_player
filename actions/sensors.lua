-- ia_fake_player/actions/sensors.lua

-- TODO optionally search within chests
-- TODO need to be able to specify a sort callback (it's necessary to be able to sort by distance, but some jobs really need to preference the y-axis over the others)
-- TODO find_items_or_nodes()

--- Internal Helper: Finds and sorts objects based on a filter.
-- @param pos Center position
-- @param radius Search radius
-- @param filter_func function(object) returns boolean
-- @return table Sorted list of {object = obj, pos = p, distance = d}
--local function get_sorted_objects(pos, radius, filter_func)
--	--minetest.log('ia_fake_player.actions.get_sorted_objects()')
--    local all_objects = minetest.get_objects_inside_radius(pos, radius)
--    local filtered = {}
--
--    for _, obj in ipairs(all_objects) do
--        if not filter_func or filter_func(obj) then
--            local obj_pos = obj:get_pos()
--            table.insert(filtered, {
--                object = obj,
--                pos = obj_pos,
--                distance = vector.distance(pos, obj_pos)
--            })
--        end
--    end
--
--    -- Sort by distance (ascending)
--    table.sort(filtered, function(a, b)
--        return a.distance < b.distance
--    end)
--
--    return filtered
--end

--- Finds all players within range, matching an optional condition.
function ia_fake_player.actions.find_players(self, radius, condition)
	--minetest.log('ia_fake_player.actions.find_players()')
    local pos = self:get_pos()
    return ia_fake_player.actions.get_sorted_objects(pos, radius, function(obj)
        if not obj:is_player() then return false end
        return not condition or condition(obj)
    end)
end

--- Finds all dropped items within range, matching an optional condition.
function ia_fake_player.actions.find_items(self, radius, condition)
	--minetest.log('ia_fake_player.actions.find_items()')
	assert(self)
	assert(self.object)
    --local pos = self:get_pos()
    local pos = self:get_pos()
    return ia_fake_player.actions.get_sorted_objects(pos, radius, function(obj)
        local ent = obj:get_luaentity()
        if not ent or ent.name ~= "__builtin:item" then return false end
        
        -- Extract item data for the condition check
        local stack = ItemStack(ent.itemstring)
        return not condition or condition(stack, obj)
    end)
end

--- Finds all entities (mobs/enemies) within range.
-- @param condition function(object) to check for "enemy" status
function ia_fake_player.actions.find_entities(self, radius, condition)
	--minetest.log('ia_fake_player.actions.find_entities()')
    local pos = self:get_pos()
    local my_obj = self.object
    
    return ia_fake_player.actions.get_sorted_objects(pos, radius, function(obj)
        if obj == my_obj then return false end -- Don't find yourself
        if obj:is_player() then return false end -- Players handled separately
        
        return not condition or condition(obj)
    end)
end



--- Finds the closest item that is actually reachable.
-- @param radius The search radius.
-- @param condition Optional extra filter.
-- @return table|nil The best target object data.
function ia_fake_player.actions.find_reachable_item(self, radius, condition)
	minetest.log('ia_fake_player.actions.find_reachable_item()')
    -- 1. Get all items sorted by distance (your existing code)
    local items = self:find_items(radius, condition)
    
    -- 2. Iterate through sorted list and return the first reachable one
    for _, item_data in ipairs(items) do
        if ia_fake_player.actions.is_target_accessible(item_data.pos) then
            -- Optional: Add a simple Line of Sight check here if you want 
            -- to prevent Dunces from "smelling" items through thick walls.
            -- if minetest.line_of_sight(self:get_pos(), item_data.pos) then
                return item_data
            -- end
        end
    end
    
    return nil
end

function ia_fake_player.actions.is_not_crowded(stack, obj) -- TODO expose convenience filters
    local pos = obj:get_pos()
    -- Reuse our occupation check from the previous step!
    -- We ignore the object itself, but check if ANYONE ELSE is standing there.
    return not ia_fake_player.actions.is_node_occupied(pos, obj)
end








--function ia_fake_player.actions.get_sorted_nodes(pos, radius, node_names)
--    local minp = vector.add(pos, -radius)
--    local maxp = vector.add(pos, radius)
--    local nodes = minetest.find_nodes_in_area(minp, maxp, node_names)
--
--    local sorted = {}
--    for _, p in ipairs(nodes) do
--        table.insert(sorted, {
--            pos = p,
--            distance = vector.distance(pos, p)
--        })
--    end
--
--    table.sort(sorted, function(a, b) return a.distance < b.distance end)
--    return sorted
--end


























-- ia_dunce/sensors.lua

--- Returns the number of empty nodes directly above the mob.
function ia_fake_player.actions.get_headspace(self, max_dist)
    local pos = self:get_pos()
    if not pos then return 0 end

    max_dist = max_dist or 5
    for i = 1, max_dist do
        local check_pos = {x = pos.x, y = pos.y + i, z = pos.z}
        local node = minetest.get_node(check_pos)
        if ia_fake_player.actions.get_node_properties(node.name) then -- if walkable/solid
            return i - 1
        end
    end
    return max_dist
end

--- Predicate: Is the mob likely "indoors"?
-- Uses a combination of headspace and light source (artificial vs sunlight).
function ia_fake_player.actions.is_indoors(self)
    local pos = self:get_pos()
    if not pos then return false end

    local light_sun = minetest.get_node_light(pos, 0.5) -- Light from sky
    local light_total = minetest.get_node_light(pos)   -- Total light

    -- If sky light is significantly lower than total light, or very low in general
    -- we are likely under a superstructure or underground.
    return (light_sun or 0) < 5 and ia_fake_player.actions.get_headspace(self, 15) < 15
end

--- Generic Danger Detection
-- Returns a threat score (0 to 100).
function ia_fake_player.actions.get_danger_level(self)
    local pos = self:get_pos()
    if not pos then return 0 end

    local threat = 0

    -- 1. Radiant Node Damage (Lava, Fire, Poop Blocks)
    -- We check a small radius around the mob
    local radius = 2
    local minp = vector.subtract(pos, radius)
    local maxp = vector.add(pos, radius)
    local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:danger", "group:igniter"})

    for _, n_pos in ipairs(nodes) do
        local node = minetest.get_node(n_pos)
        local def = minetest.registered_nodes[node.name]

        -- Check for explicit damage_per_second in the node definition
        if def and def.damage_per_second and def.damage_per_second > 0 then
            threat = threat + (def.damage_per_second * 10)
        end
    end

    -- 2. Proximity to Hostile Entities
    -- Downstream AI can mark certain entities as "hostile" in a table
    local nearby = minetest.get_objects_inside_radius(pos, 6)
    for _, obj in ipairs(nearby) do
        if obj ~= self.object and ia_fake_player.actions.is_hostile(self, obj) then
            local dist = vector.distance(pos, obj:get_pos())
            threat = threat + (20 / math.max(dist, 1))
        end
    end

    return math.min(threat, 100)
end

--- Predicate: Is the mob in immediate danger?
function ia_fake_player.actions.is_in_danger(self)
    return ia_fake_player.actions.get_danger_level(self) > 10
end































-- ia_dunce/sensors.lua

--- Internal: Default Euclidean sort
function ia_fake_player.actions.default_sort(a, b)
    return a.distance < b.distance
end

--- Internal Helper: Finds and sorts objects based on a filter and optional custom sort.
-- @param pos Center position
-- @param radius Search radius
-- @param filter_func function(object) returns boolean
-- @param sort_func Optional function(a, b) for table.sort
-- @return table Sorted list of {object = obj, pos = p, distance = d}
function ia_fake_player.actions.get_sorted_objects(pos, radius, filter_func, sort_func)
    local all_objects = minetest.get_objects_inside_radius(pos, radius)
    local filtered = {}

    for _, obj in ipairs(all_objects) do
        if not filter_func or filter_func(obj) then
            local obj_pos = obj:get_pos()
            table.insert(filtered, {
                object = obj,
                pos = obj_pos,
                distance = vector.distance(pos, obj_pos)
            })
        end
    end

    table.sort(filtered, sort_func or ia_fake_player.actions.default_sort)
    return filtered
end

--- Finds all nodes in area with custom sorting support.
-- @param sort_func Optional function(a, b) to preference specific axes.
function ia_fake_player.actions.get_sorted_nodes(pos, radius, node_names, sort_func)
    local minp = vector.add(pos, -radius)
    local maxp = vector.add(pos, radius)
    local nodes = minetest.find_nodes_in_area(minp, maxp, node_names)

    local sorted = {}
    for _, p in ipairs(nodes) do
        table.insert(sorted, {
            pos = p,
            distance = vector.distance(pos, p)
        })
    end

    table.sort(sorted, sort_func or ia_fake_player.actions.default_sort)
    return sorted
end

--- Finds nodes with inventories (Chests, Furnaces, etc.)
-- @param check_items_func Optional function(stack) to check for specific items inside.
function ia_fake_player.actions.find_inventories(self, radius, check_items_func, sort_func)
    local pos = self:get_pos()
    -- Common container groups in Minetest
    local node_names = {"group:container", "group:chest", "group:furnace"}
    local nodes = ia_fake_player.actions.get_sorted_nodes(pos, radius, node_names, sort_func)

    local results = {}
    for _, node_data in ipairs(nodes) do
        local meta = minetest.get_meta(node_data.pos)
        local inv = meta:get_inventory()

        if inv then
            local match = true
            if check_items_func then
                match = false
                -- Check all lists (main, src, fuel, etc.)
                for listname, _ in pairs(inv:get_lists()) do
                    local list = inv:get_list(listname)
                    for _, stack in ipairs(list) do
                        if not stack:is_empty() and check_items_func(stack) then
                            match = true
                            break
                        end
                    end
                    if match then break end
                end
            end

            if match then
                table.insert(results, node_data)
            end
        end
    end
    return results
end

--- Finds potential theft targets (Players/Entities with valuables).
function ia_fake_player.actions.find_theft_targets(self, radius, sort_func)
    local pos = self:get_pos()
    return ia_fake_player.actions.get_sorted_objects(pos, radius, function(obj)
        -- Use the primitive from steal.lua to check viability
        return obj ~= self.object and ia_fake_player.actions.can_steal_from(self, obj)
    end, sort_func)
end

--- Helper: Generates a Y-axis penalty sort function.
-- Usage: self:find_inventories(10, nil, ia_fake_player.actions.create_y_penalty_sort(pos, 2.0))
function ia_fake_player.actions.create_y_penalty_sort(center_pos, y_weight)
    return function(a, b)
        local da = vector.subtract(a.pos, center_pos)
        local db = vector.subtract(b.pos, center_pos)
        local dist_a = math.sqrt(da.x^2 + (da.y * y_weight)^2 + da.z^2)
        local dist_b = math.sqrt(db.x^2 + (db.y * y_weight)^2 + db.z^2)
        return dist_a < dist_b
    end
end
