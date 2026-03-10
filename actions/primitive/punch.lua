-- ia_fake_player/actions/primitive/punch.lua

function ia_fake_player.actions.primitive.punch(self, target)
    minetest.log('ia_fake_player.actions.primitive.punch()')
    local target_pos = (type(target) == "table" and target.x) and target or target:get_pos()
    if not target_pos then return false end

    ia_fake_player.actions.primitive.stop_and_look_at(self, target_pos)
    
    local dir = vector.direction(self:get_pos(), target_pos)
    if type(target) == "table" then
        local node = minetest.get_node(target)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_punch then
            def.on_punch(target, node, self.fake_player, nil)
        end
    else
        target:punch(self.fake_player, 1.0, self:get_wielded_item():get_tool_capabilities(), dir)
    end

    ia_fake_player.actions.primitive.set_animation(self, 'PUNCH', 30, false)
    minetest.sound_play("player_punchplayer", {pos = target_pos, gain = 0.5})

    return true
end
