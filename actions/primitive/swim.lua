-- ia_fake_player/actions/primitive/swim.lua

--- Logic for aquatic movement and floating.
function ia_fake_player.actions.primitive.swim(self)
	--minetest.log('ia_fake_player.actions.primitive.swim()')
    local pos = self:get_pos()
    if not pos then return false end

    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]

    -- Check if the node is a liquid (water, lava, etc.)
    if def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid") then
        -- Apply a gentle upward force to simulate swimming/treading water
        ia_fake_player.actions.primitive.apply_vertical_impulse(self, 2)
        return true
    end
    
    return false
end

function ia_fake_player.actions.primitive.is_in_liquid(self)
    local pos = self:get_pos()
    if not pos then return false end
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.drawtype == "liquid"
end



--- Predicate: Is the mob's head underwater?
function ia_fake_player.actions.primitive.is_submerged(self)
    local pos = self:get_pos()
    if not pos then return false end
    local head_pos = {x = pos.x, y = pos.y + 1.5, z = pos.z}
    local node = minetest.get_node(head_pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.drawtype == "liquid"
end

--- Returns depth of liquid mob is currently in.
function ia_fake_player.actions.primitive.get_liquid_depth(self)
    if not ia_fake_player.actions.primitive.is_in_liquid(self) then return 0 end
    local pos = self:get_pos()

    for i = 1, 10 do
        local check = {x = pos.x, y = pos.y + i, z = pos.z}
        if not ia_fake_player.actions.primitive.is_in_liquid({object = {get_pos = function() return check end}}) then
            return i
        end
    end
    return 10
end
