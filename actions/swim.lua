-- ia_dunce/swim.lua

--- Logic for aquatic movement and floating.
function ia_dunce.swim(self)
	--minetest.log('ia_dunce.swim()')
    local pos = self.object:get_pos()
    if not pos then return false end

    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]

    -- Check if the node is a liquid (water, lava, etc.)
    if def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid") then
        -- Apply a gentle upward force to simulate swimming/treading water
        ia_dunce.apply_vertical_impulse(self, 2)
        return true
    end
    
    return false
end

function ia_dunce.is_in_liquid(self)
    local pos = self.object:get_pos()
    if not pos then return false end
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.drawtype == "liquid"
end



-- ia_dunce/swim.lua (or sensors.lua)

--- Predicate: Is the mob's head underwater?
function ia_dunce.is_submerged(self)
    local pos = self.object:get_pos()
    if not pos then return false end
    local head_pos = {x = pos.x, y = pos.y + 1.5, z = pos.z}
    local node = minetest.get_node(head_pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.drawtype == "liquid"
end

--- Returns depth of liquid mob is currently in.
function ia_dunce.get_liquid_depth(self)
    if not ia_dunce.is_in_liquid(self) then return 0 end
    local pos = self.object:get_pos()

    for i = 1, 10 do
        local check = {x = pos.x, y = pos.y + i, z = pos.z}
        if not ia_dunce.is_in_liquid({object = {get_pos = function() return check end}}) then
            return i
        end
    end
    return 10
end
