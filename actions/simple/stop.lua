-- ia_fake_player/actions/simple/stop.lua

function ia_fake_player.actions.simple.stop(self)
	minetest.log('ia_fake_player.actions.simple.stop()')
    local v = self:get_velocity()
    if not v then return end
    self:set_velocity({x = 0, y = v.y, z = 0})
    ia_fake_player.actions.simple.set_animation(self, 'STAND')
end

