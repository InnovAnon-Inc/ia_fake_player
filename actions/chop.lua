-- ia_dunce/chop.lua

--- Low-level: Is the node at this position wood-like/choppable?
-- Environmental check for 'choppy' group (trees, wood, etc.)
function ia_dunce.is_choppable(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "choppy") > 0
end

--- Mid-level: Can the mob efficiently chop this wood with its current gear?
function ia_dunce.can_chop(self, pos)
    if not ia_dunce.is_choppable(pos) then return false end

    local has_axe = ia_dunce.has_item(self, function(n)
        return minetest.get_item_group(n, "axe") > 0
    end)

    local node = minetest.get_node(pos)
    local can_physically_dig, time = ia_dunce.can_dig_node(self, node.name)
    
    -- Chopping is viable if we have an axe or the node is soft enough (< 1.5s)
    return can_physically_dig and (has_axe or time < 1.5)
end

--- High-level: Could the mob chop this if it performed a trivial craft?
function ia_dunce.could_chop(self, pos)
    -- Check readiness first
    if ia_dunce.can_chop(self, pos) then return true end

    -- Check if it's a choppable node solvable by crafting an axe
    if ia_dunce.is_choppable(pos) then
        if ia_dunce.can_obtain_item("default:axe_stone") or 
           ia_dunce.can_obtain_item("default:axe_wood") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
function ia_dunce.chop(self, pos, keep)
    minetest.log('ia_dunce.chop()')
    return ia_dunce.left_click(self, pos, keep)
end

--- Level 2: Preparation + Action
function ia_dunce.equip_and_chop(self, pos, keep)
    minetest.log('ia_dunce.equip_and_chop()')
    local is_axe = function(n) return minetest.get_item_group(n, "axe") > 0 end
    
    -- Attempt to wield an axe
    ia_dunce.wield_by_condition(self, is_axe)
    return ia_dunce.chop(self, pos, keep)
end

--- Level 3: Provisioning + Preparation + Action
function ia_dunce.craft_and_chop(self, pos, keep)
    minetest.log('ia_dunce.craft_and_chop()')
    
    local has_axe = ia_dunce.has_item(self, function(n) 
        return minetest.get_item_group(n, "axe") > 0 
    end)

    if not has_axe then
        -- Try crafting stone then wood axes
        if ia_dunce.can_obtain_item("default:axe_stone") then
            ia_dunce.craft_item(self, "default:axe_stone")
        elseif ia_dunce.can_obtain_item("default:axe_wood") then
            ia_dunce.craft_item(self, "default:axe_wood")
        end
    end

    return ia_dunce.equip_and_chop(self, pos, keep)
end
