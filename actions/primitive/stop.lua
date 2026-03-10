-- ia_fake_player/actions/primitive/stop.lua

function ia_fake_player.actions.primitive.stop(self)
	minetest.log('ia_fake_player.actions.primitive.stop()')
    local v = self:get_velocity()
    if not v then return end
    self:set_velocity({x = 0, y = v.y, z = 0})
    ia_fake_player.actions.primitive.set_animation(self, 'STAND')
end

--- Stops all movement and faces a target.
function ia_fake_player.actions.primitive.stop_and_look_at(self, pos)
    self:set_velocity({x=0, y=0, z=0})
    ia_fake_player.actions.face_pos(self, pos)
end
