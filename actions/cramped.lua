-- ia_dunce/sensors.lua

--- Returns distances to nearest walkable obstacles in cardinal directions.
-- @return table {forward, back, left, right}
function ia_dunce.get_surrounding_clearance(self, max_dist)
    local pos = self.object:get_pos()
    if not pos then return {f = 0, b = 0, l = 0, r = 0} end
    
    max_dist = max_dist or 10
    local look_dir = self.object:get_look_horizontal()
    
    -- Helper to scan in a specific vector
    local function scan(dir_vec)
        for i = 1, max_dist do
            local check_pos = vector.add(pos, vector.multiply(dir_vec, i))
            -- Check at foot level and head level
            local node_f = minetest.get_node(check_pos)
            local node_h = minetest.get_node({x=check_pos.x, y=check_pos.y+1, z=check_pos.z})
            
            local walk_f = ia_dunce.get_node_properties(node_f.name)
            local walk_h = ia_dunce.get_node_properties(node_h.name)
            
            if walk_f or walk_h then return i - 1 end
        end
        return max_dist
    end

    -- Cardinal directions based on current rotation
    local forward = {x = -math.sin(look_dir), y = 0, z = math.cos(look_dir)}
    local right = {x = math.cos(look_dir), y = 0, z = math.sin(look_dir)}
    
    return {
        forward = scan(forward),
        back    = scan(vector.multiply(forward, -1)),
        right   = scan(right),
        left    = scan(vector.multiply(right, -1))
    }
end

--- Predicate: Is the mob in a cramped area (e.g., 1x2 tunnel)?
function ia_dunce.is_tight_space(self)
    local clearance = ia_dunce.get_surrounding_clearance(self, 2)
    local headspace = ia_dunce.get_headspace(self, 3)
    
    -- If headspace is low AND opposite sides are close
    local narrow_x = (clearance.left + clearance.right) <= 1
    local narrow_z = (clearance.forward + clearance.back) <= 1
    
    return headspace <= 2 and (narrow_x or narrow_z)
end
