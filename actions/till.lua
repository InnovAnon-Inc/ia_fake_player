-- ia_dunce/till.lua

--- Low-level: Is the node capable of being turned into farmland?
-- Environmental check: requires 'soil' group and 'air' above.
function ia_dunce.is_tillable(pos)
    local node = minetest.get_node(pos)
    local is_soil = minetest.get_item_group(node.name, "soil") > 0
    local above = {x = pos.x, y = pos.y + 1, z = pos.z}
    local has_air_above = minetest.get_node(above).name == "air"
    return is_soil and has_air_above
end

--- Mid-level: Is the agent currently equipped and in position to till?
function ia_dunce.can_till(self, pos)
    if not ia_dunce.is_tillable(pos) then return false end

    local has_hoe = ia_dunce.has_item(self, function(n) 
        return minetest.get_item_group(n, "hoe") > 0 
    end)
    
    return has_hoe
end

--- High-level: Could the agent till this if they crafted a hoe first?
function ia_dunce.could_till(self, pos)
    if ia_dunce.can_till(self, pos) then return true end

    if ia_dunce.is_tillable(pos) then
        -- Check for common trivial hoe recipes
        if ia_dunce.can_obtain_item("farming:hoe_stone") or 
           ia_dunce.can_obtain_item("farming:hoe_wood") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the right-click interaction to till the soil.
function ia_dunce.till(self, pos)
    minetest.log('ia_dunce.till()')
    -- Hoes usually don't need 'sneak' for placement logic
    return ia_dunce.right_click(self, pos, false)
end

--- Level 2: Preparation + Action
-- Ensures a hoe is in hand before tilling.
function ia_dunce.equip_and_till(self, pos)
    minetest.log('ia_dunce.equip_and_till()')
    local is_hoe = function(name) return minetest.get_item_group(name, "hoe") > 0 end
    
    local has_hoe = ia_dunce.wield_by_condition(self, is_hoe)
    if not has_hoe then
        return false, "no_hoe_to_equip"
    end

    return ia_dunce.till(self, pos)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts a hoe if missing, then equips and tills.
function ia_dunce.craft_and_till(self, pos)
    minetest.log('ia_dunce.craft_and_till()')
    
    local is_hoe = function(n) return minetest.get_item_group(n, "hoe") > 0 end
    if not ia_dunce.has_item(self, is_hoe) then
        -- Try to craft a stone hoe, then fallback to wood
        if ia_dunce.can_obtain_item("farming:hoe_stone") then
            ia_dunce.craft_item(self, "farming:hoe_stone")
        elseif ia_dunce.can_obtain_item("farming:hoe_wood") then
            ia_dunce.craft_item(self, "farming:hoe_wood")
        end
    end

    return ia_dunce.equip_and_till(self, pos)
end
