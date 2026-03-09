-- ia_dunce/is_line_of_sight_clear.lua

--- Internal: Simple raycast to check if a straight line is walkable.
-- This ensures smoothing doesn't take us through walls or over pits.
function ia_dunce.is_line_of_sight_clear(pos1, pos2) -- TODO this needs to be extensible (no-clipping ability)
    -- We check for a clear path at foot level and head level
    local ray_foot = minetest.line_of_sight(
        {x=pos1.x, y=pos1.y + 0.5, z=pos1.z}, 
        {x=pos2.x, y=pos2.y + 0.5, z=pos2.z}
    )
    local ray_head = minetest.line_of_sight(
        {x=pos1.x, y=pos1.y + 1.5, z=pos1.z}, 
        {x=pos2.x, y=pos2.y + 1.5, z=pos2.z}
    )
    
    -- Also ensure there is actually a floor between the two points
    -- (Prevents smoothing across a gap/pit)
    local dist = vector.distance(pos1, pos2)
    local mid_pos = vector.divide(vector.add(pos1, pos2), 2)
    local ground = ia_dunce.find_ground_level(mid_pos, 1, 2)
    
    return ray_foot and ray_head and ground ~= nil
end

