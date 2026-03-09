-- ia_dunce/is_at.lua

function ia_dunce.is_at(self, pos, threshold)
	--minetest.log('ia_dunce.is_at()')
    local my_pos = self.object:get_pos()
    if not my_pos or not pos then return false end
    local flat_dist = vector.distance({x=my_pos.x, y=0, z=my_pos.z}, {x=pos.x, y=0, z=pos.z})
    return flat_dist < (threshold or 0.5) and math.abs(my_pos.y - pos.y) < 1.5
end
