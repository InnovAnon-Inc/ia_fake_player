-- ia_fake_player/actions/primitive/sneak.lua

function ia_fake_player.actions.primitive.sneak(self, active)
	minetest.log('ia_fake_player.actions.primitive.sneak()')
    if active then
        -- Slow down speed and lower eye level/animation
        self._is_sneaking = true
        ia_fake_player.actions.primitive.set_animation(self, 'SNEAK')
    else
        self._is_sneaking = false
        ia_fake_player.actions.primitive.set_animation(self, 'STAND')
    end
end

function ia_fake_player.actions.primitive.is_sneaking(self)
    return self._is_sneaking == true
end
