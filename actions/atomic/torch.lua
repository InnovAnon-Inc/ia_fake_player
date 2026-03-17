-- ia_fake_player/actions/atomic/torch.lua

--- Low-level: Can a torch be attached to this node/surface?
-- Environmental check: uses util helper to verify surface solidity.
function ia_fake_player.actions.atomic.is_torch_placeable(pos)
    local node = minetest.get_node(pos)
    local props = ia_fake_player.actions.primitive.get_node_properties(node.name)
    return props == true
end

--- Mid-level: Does the agent have torches and a valid surface?
function ia_fake_player.actions.atomic.can_place_torch(self, pos)
    if not ia_fake_player.actions.atomic.has_torches(self) then return false end
    return ia_fake_player.actions.atomic.is_torch_placeable(pos)
end

--- High-level: Could the agent place a torch by crafting one first?
function ia_fake_player.actions.atomic.could_place_torch(self, pos)
    if ia_fake_player.actions.atomic.can_place_torch(self, pos) then return true end

    if ia_fake_player.actions.atomic.is_torch_placeable(pos) then
        -- Check for trivial torch recipe (usually default:torch)
        if ia_fake_player.actions.primitive.can_obtain_item("default:torch") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the right-click interaction to place a torch.
function ia_fake_player.actions.atomic.place_torch(self, pos)
    minetest.log('ia_fake_player.place_torch()')
    -- Sneak=true is used to place the torch ON containers without opening them.
    return ia_fake_player.actions.primitive.right_click(self, pos, true)
end

--- Level 2: Preparation + Action
-- Ensures a torch is wielded before placement.
function ia_fake_player.actions.atomic.equip_and_place_torch(self, pos)
    minetest.log('ia_fake_player.equip_and_place_torch()')
    local is_torch = function(n) return minetest.get_item_group(n, "torch") > 0 end
    
    if ia_fake_player.actions.primitive.wield_by_condition(self, is_torch) then
        return ia_fake_player.actions.atomic.place_torch(self, pos)
    end
    
    return false, "no_torches_to_equip"
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts torches if missing, then equips and places one.
function ia_fake_player.actions.atomic.craft_and_place_torch(self, pos)
    minetest.log('ia_fake_player.craft_and_place_torch()')

    if not ia_fake_player.actions.atomic.has_torches(self) then
        if ia_fake_player.actions.primitive.can_obtain_item("default:torch") then
            ia_fake_player.actions.primitive.craft_item(self, "default:torch")
        end
    end

    return ia_fake_player.actions.atomic.equip_and_place_torch(self, pos)
end

--- Returns true if the agent carries any item in the 'torch' group.
function ia_fake_player.actions.atomic.has_torches(self)
    return ia_fake_player.actions.primitive.has_item(self, function(n) 
        return minetest.get_item_group(n, "torch") > 0 
    end)
end

--- Checks if light level at current position is below threshold.
function ia_fake_player.actions.atomic.is_too_dark(self)
    local pos = self:get_pos()
    if not pos then return false end
    -- Standard threshold for monster spawning and visibility
    return (minetest.get_node_light(pos) or 15) < 5
end
