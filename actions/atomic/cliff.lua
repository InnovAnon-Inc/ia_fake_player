-- ia_fake_player/actions/atomic/cliff.lua

function ia_fake_player.actions.atomic.find_cliff(self)
    local pos = self:get_pos()
    local dir = minetest.yaw_to_dir(self:get_yaw())
    local check_pos = vector.add(pos, vector.multiply(dir, 1))
    for y = 0, -3, -1 do
	local pos  = {x=check_pos.x, y=check_pos.y + y, z=check_pos.z}
        local node = core.get_node(pos)
        if node.name ~= "air" then
            return pos
        end
    end
    return nil
end

function ia_fake_player.actions.atomic.find_and_use_cliff(self)
    local cliff = ia_fake_player.actions.atomic.find_cliff(self)
    if not cliff then return nil end
    self:set_velocity({x=0, y=v.y, z=0}) -- FIXME `v` ???
    return cliff
end
