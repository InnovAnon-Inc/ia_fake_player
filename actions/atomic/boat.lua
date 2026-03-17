-- ia_fake_player/actions/atomic/boat.lua
-- Feature matrix for handling boats and maritime transit.

-- CHANGE: Internal mapping for boat-related items
local boat_types = {
    names = {
        ["boats:boat"] = true,
    },
    groups = {
        ["boat"] = true,
    }
}

--- Low-level: Is the position suitable for a boat?
-- Environmental check: requires liquid (water) to float.
function ia_fake_player.actions.atomic.is_navigable_water(pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    -- Check if it is a liquid (drawtype usually 'liquid' or 'flowingliquid')
    -- or has the liquid group
    return def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid" or minetest.get_item_group(node.name, "liquid") > 0)
end

--- Mid-level: Is the agent currently equipped and positioned to use a boat?
function ia_fake_player.actions.atomic.can_boat(self, pos)
    if not ia_fake_player.actions.atomic.is_navigable_water(pos) then return false end

    -- Check if agent has a boat in inventory
    local has_boat = ia_fake_player.actions.primitive.has_item(self, function(n)
        return boat_types.names[n] or minetest.get_item_group(n, "boat") > 0
    end)

    return has_boat
end

--- High-level: Could the agent use a boat here if they crafted one?
function ia_fake_player.actions.atomic.could_boat(self, pos)
    if ia_fake_player.actions.atomic.can_boat(self, pos) then return true end

    if ia_fake_player.actions.atomic.is_navigable_water(pos) then
        -- Check for common boat recipes (5 wood planks)
        if ia_fake_player.actions.primitive.can_obtain_item("boats:boat") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the placement of a boat onto the water.
function ia_fake_player.actions.atomic.place_boat(self, pos)
    minetest.log('ia_fake_player.place_boat()')
    -- We use right_click with 'sneak' false to place the item onto the water surface
    return ia_fake_player.actions.primitive.right_click(self, pos, false)
end

--- Level 2: Preparation + Action
-- Ensures a boat is wielded and then placed.
function ia_fake_player.actions.atomic.equip_and_place_boat(self, pos)
    minetest.log('ia_fake_player.equip_and_place_boat()')
    local is_boat = function(n) 
        return boat_types.names[n] or minetest.get_item_group(n, "boat") > 0 
    end
    
    local wielded = ia_fake_player.actions.primitive.wield_by_condition(self, is_boat)
    if not wielded then
        return false, "no_boat_to_wield"
    end

    return ia_fake_player.actions.atomic.place_boat(self, pos)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts a boat if missing, then places it and prepares for boarding.
function ia_fake_player.actions.atomic.craft_and_place_boat(self, pos)
    minetest.log('ia_fake_player.craft_and_place_boat()')
    
    local is_boat = function(n) 
        return boat_types.names[n] or minetest.get_item_group(n, "boat") > 0 
    end

    if not ia_fake_player.actions.primitive.has_item(self, is_boat) then
        if ia_fake_player.actions.primitive.can_obtain_item("boats:boat") then
            ia_fake_player.actions.primitive.craft_item(self, "boats:boat")
        end
    end

    local success = ia_fake_player.actions.atomic.equip_and_place_boat(self, pos)
    
    -- NOTE: Boarding the boat is typically handled by a separate right-click 
    -- on the resulting entity, which would be managed by pathfinding/interaction logic.
    return success
end

--- Helper: Check if an item is a boat
function ia_fake_player.actions.atomic.is_boat_item(item_name)
    if boat_types.names[item_name] then return true end
    if minetest.get_item_group(item_name, "boat") > 0 then return true end
    return false
end
