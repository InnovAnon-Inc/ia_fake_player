-- ia_dunce/mine.lua

--- Low-level: Is the node at this position of a type that can be mined?
-- This is an environmental check independent of the agent's state.
function ia_dunce.is_mineable(pos)
    local node = minetest.get_node(pos)
    -- Stone and ores belong to the 'cracky' group
    return minetest.get_item_group(node.name, "cracky") > 0
end

--- Mid-level: Is the mob currently equipped to mine this efficiently?
-- Aware of current inventory and physical capabilities.
function ia_dunce.can_mine(self, pos)
    if not ia_dunce.is_mineable(pos) then return false end

    local node = minetest.get_node(pos)
    local can_physically_dig, time = ia_dunce.can_dig_node(self, node.name)
    local has_pick = ia_dunce.has_item(self, function(n)
        return minetest.get_item_group(n, "pickaxe") > 0
    end)

    -- Mining usually requires a pickaxe unless the node is very soft (< 2.0s)
    return can_physically_dig and (has_pick or time < 2.0)
end

--- High-level: Could the mob mine this if it performed a trivial craft?
-- Aware of current inventory + potential inventory.
function ia_dunce.could_mine(self, pos)
    -- If we can already mine it, we're good
    if ia_dunce.can_mine(self, pos) then return true end

    -- Check if it's a cracky node solvable by crafting a pickaxe
    if ia_dunce.is_mineable(pos) then
        -- Check for common pickaxe types (trivial 1-step crafts)
        if ia_dunce.can_obtain_item("default:pick_stone") or 
           ia_dunce.can_obtain_item("default:pick_wood") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the left-click mining interaction.
function ia_dunce.mine(self, pos, keep)
    minetest.log('ia_dunce.mine()')
    return ia_dunce.left_click(self, pos, keep)
end

--- Level 2: Preparation + Action
-- Ensures a pickaxe is wielded before attempting to mine.
function ia_dunce.equip_and_mine(self, pos, keep)
    minetest.log('ia_dunce.equip_and_mine()')
    local is_pick = function(n) return minetest.get_item_group(n, "pickaxe") > 0 end
    
    -- Try to wield a pickaxe if we have one
    ia_dunce.wield_by_condition(self, is_pick)
    return ia_dunce.mine(self, pos, keep)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts the pickaxe if missing, then equips and mines.
function ia_dunce.craft_and_mine(self, pos, keep)
    minetest.log('ia_dunce.craft_and_mine()')
    
    local has_pick = ia_dunce.has_item(self, function(n) 
        return minetest.get_item_group(n, "pickaxe") > 0 
    end)

    if not has_pick then
        -- Attempt to craft the best possible trivial pickaxe available
        if ia_dunce.can_obtain_item("default:pick_stone") then
            ia_dunce.craft_item(self, "default:pick_stone")
        elseif ia_dunce.can_obtain_item("default:pick_wood") then
            ia_dunce.craft_item(self, "default:pick_wood")
        end
    end

    return ia_dunce.equip_and_mine(self, pos, keep)
end
