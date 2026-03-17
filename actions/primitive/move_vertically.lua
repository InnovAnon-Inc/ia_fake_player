-- ia_fake_player/actions/primitive/move_vertically.lua

function ia_fake_player.actions.primitive.move_vertically(self)
	--minetest.log('ia_pathfinding.vertical_auto_pilot()')
    -- Priority: Falling -> Climbing -> Swimming -> Flying
    local result
    result = ia_fake_player.actions.primitive.fall(self)
    if result then return result end
    result = ia_fake_player.actions.primitive.climb(self) -- up or down ???
    if result then return result end
    result = ia_fake_player.actions.primitive.swim(self)
    if result then return result end
    result = ia_fake_player.actions.primitive.fly(self)
    if result then return result end
    return false
end
