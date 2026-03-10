-- ia_fake_player/actions/atomic/move_vertically.lua

function ia_dunce.move_vertically(self)
	--minetest.log('ia_pathfinding.vertical_auto_pilot()')
    -- Priority: Falling -> Climbing -> Swimming -> Flying
    local result
    result = ia_dunce.fall(self)
    if result then return result end
    result = ia_dunce.climb(self) -- up or down ???
    if result then return result end
    result = ia_dunce.swim(self)
    if result then return result end
    result = ia_dunce.fly(self)
    if result then return result end
    return false
end
