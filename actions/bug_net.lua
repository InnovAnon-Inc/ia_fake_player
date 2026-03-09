-- ia_dunce/bug_net.lua

-- Feature Matrix:
-- Level 1: Atomic Action (catch)
-- Level 2: Preparation + Action (equip_and_catch)
-- Level 3: Provisioning + Preparation + Action (craft_and_catch)
--
-- Checks:
-- Environmental: is_catchable(pos)
-- Agent State:  can_catch(self, pos)
-- Potential:    could_catch(self, pos)

local bugs = {
    names = {
        ["fireflies:firefly"] = {},
        ["butterflies:butterfly_red"] = {},
        ["butterflies:butterfly_white"] = {},
        ["butterflies:butterfly_violet"] = {},
    },
    groups = {
        ["bugs"] = {},
        ["butterflies"] = {},
    },
}

--- Internal: Helper to identify if a node is a bug
local function get_bug_data(node_name)
    if bugs.names[node_name] then
        return bugs.names[node_name]
    end
    for group, value in pairs(bugs.groups) do
        if minetest.get_item_group(node_name, group) > 0 then
            return value
        end
    end
    return nil
end

--- Low-level: Environmental check
-- Is the node at this position actually a bug we can collect?
function ia_dunce.is_catchable(pos)
    local node = minetest.get_node(pos)
    return get_bug_data(node.name) ~= nil
end

--- Mid-level: Agent state check
-- Does the agent have a net and can they reach the bug?
function ia_dunce.can_catch(self, pos)
    if not ia_dunce.is_catchable(pos) then return false end
    
    local has_net = ia_dunce.has_item(self, function(n)
        return n == "fireflies:bug_net" or minetest.get_item_group(n, "bug_net") > 0
    end)

    return has_net
end

--- High-level: Potential check
-- Could the agent catch this if they crafted a net?
function ia_dunce.could_catch(self, pos)
    if ia_dunce.can_catch(self, pos) then return true end

    if ia_dunce.is_catchable(pos) then
        -- Check if a net is craftable from current inventory
        if ia_dunce.can_obtain_item("fireflies:bug_net") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the actual collection (digging with the net).
function ia_dunce.catch(self, pos, keep)
    minetest.log('action', '[ia_dunce] catch() at ' .. minetest.pos_to_string(pos))
    -- Bug nets in Minetest usually function via the dig (left_click) callback
    return ia_dunce.left_click(self, pos, keep)
end

--- Level 2: Preparation + Action
-- Ensures the bug net is in hand before catching.
function ia_dunce.equip_and_catch(self, pos, keep)
    minetest.log('action', '[ia_dunce] equip_and_catch()')
    local is_net = function(n) 
        return n == "fireflies:bug_net" or minetest.get_item_group(n, "bug_net") > 0 
    end
    
    local wielded = ia_dunce.wield_by_condition(self, is_net)
    if not wielded then
        return false, "no_net_equipped"
    end

    return ia_dunce.catch(self, pos, keep)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts a net if missing, then equips and catches.
function ia_dunce.craft_and_catch(self, pos, keep)
    minetest.log('action', '[ia_dunce] craft_and_catch()')
    
    local is_net = function(n) 
        return n == "fireflies:bug_net" or minetest.get_item_group(n, "bug_net") > 0 
    end

    if not ia_dunce.has_item(self, is_net) then
        if ia_dunce.can_obtain_item("fireflies:bug_net") then
            ia_dunce.craft_item(self, "fireflies:bug_net")
        end
    end

    return ia_dunce.equip_and_catch(self, pos, keep)
end
