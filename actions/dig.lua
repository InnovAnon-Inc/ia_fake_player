-- ia_dunce/dig.lua

--- Low-level: Can this node be dug at all? (ignoring current inventory)
function ia_dunce.is_diggable(pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.diggable ~= false
end

--- Mid-level: Is the mob equipped to dig this specific crumbly node efficiently?
function ia_dunce.can_dig(self, pos)
    if not ia_dunce.is_diggable(pos) then return false end
    
    local node = minetest.get_node(pos)
    local is_crumbly = minetest.get_item_group(node.name, "crumbly") > 0
    if not is_crumbly then return false end

    local can_physically_dig, time = ia_dunce.can_dig_node(self, node.name)
    local has_shovel = ia_dunce.has_item(self, function(n) 
        return minetest.get_item_group(n, "shovel") > 0 
    end)

    return can_physically_dig and (has_shovel or time < 1.0)
end

--- High-level: Is it possible to dig this by crafting a shovel right now?
function ia_dunce.could_dig(self, pos)
    -- If we can already dig it, we're good
    if ia_dunce.can_dig(self, pos) then return true end

    -- Check if it's a crumbly node we could solve by crafting a shovel
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "crumbly") > 0 then
        -- Check for common shovel types (trivial 1-step crafts)
        if ia_dunce.can_obtain_item("default:shovel_stone") or 
           ia_dunce.can_obtain_item("default:shovel_wood") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
function ia_dunce.dig(self, pos, keep) 
    minetest.log('ia_dunce.dig()')
    return ia_dunce.left_click(self, pos, keep) 
end

--- Level 2: Preparation + Action
-- Ensures a shovel is in hand before digging.
function ia_dunce.equip_and_dig(self, pos, keep)
    minetest.log('ia_dunce.equip_and_dig()')
    local is_shovel = function(n) return minetest.get_item_group(n, "shovel") > 0 end
    
    -- Attempt to wield shovel; if none, it will just dig with hand/current item
    ia_dunce.wield_by_condition(self, is_shovel)
    return ia_dunce.dig(self, pos, keep)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts the shovel if missing, then equips and digs.
function ia_dunce.craft_and_dig(self, pos, keep)
    minetest.log('ia_dunce.craft_and_dig()')
    
    local has_shovel = ia_dunce.has_item(self, function(n) 
        return minetest.get_item_group(n, "shovel") > 0 
    end)

    if not has_shovel then
        -- Attempt to craft the best possible trivial shovel
        if ia_dunce.can_obtain_item("default:shovel_stone") then
            ia_dunce.craft_item(self, "default:shovel_stone")
        elseif ia_dunce.can_obtain_item("default:shovel_wood") then
            ia_dunce.craft_item(self, "default:shovel_wood")
        end
    end

    return ia_dunce.equip_and_dig(self, pos, keep)
end
