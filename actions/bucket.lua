-- ia_dunce/bucket.lua

-- CHANGE: Local mapping for liquid-to-bucket relationships
local bucket_map = {
    ["default:water_source"] = "bucket:bucket_water",
    ["default:river_water_source"] = "bucket:bucket_river_water",
    ["default:lava_source"] = "bucket:bucket_lava",
}

-- CHANGE: List of items considered empty buckets
local empty_buckets = {
    ["bucket:bucket_empty"] = true,
}

--- Low-level: Is the node at this position a collectable liquid?
function ia_dunce.is_bucketable(pos)
    local node = minetest.get_node(pos)
    return bucket_map[node.name] ~= nil
end

--- Mid-level: Does the agent have an empty bucket to collect this liquid?
function ia_dunce.can_collect_liquid(self, pos)
    if not ia_dunce.is_bucketable(pos) then return false end

    local has_empty = ia_dunce.has_item(self, function(name)
        return empty_buckets[name] == true
    end)

    return has_empty
end

--- High-level: Could the agent collect this if they had a bucket?
function ia_dunce.could_collect_liquid(self, pos)
    if not ia_dunce.is_bucketable(pos) then return false end
    if ia_dunce.can_collect_liquid(self, pos) then return true end

    -- Check for trivial obtainability of an empty bucket
    return ia_dunce.can_obtain_item("bucket:bucket_empty")
end

--- Level 1: Atomic Action
-- Performs the right-click to fill or empty a bucket.
function ia_dunce.bucket_action(self, pos)
    minetest.log('ia_dunce.bucket_action()')
    -- Right-clicking a liquid source with an empty bucket fills it.
    -- Right-clicking a node with a full bucket places the liquid.
    return ia_dunce.right_click(self, pos, false)
end

--- Level 2: Preparation + Action (Collection)
-- Ensures an empty bucket is wielded, then collects the liquid.
function ia_dunce.equip_and_collect(self, pos)
    minetest.log('ia_dunce.equip_and_collect()')
    
    local is_empty = function(name) 
        return empty_buckets[name] == true
    end

    local success_wield = ia_dunce.wield_by_condition(self, is_empty)
    if not success_wield then
        return false, "no_empty_bucket"
    end

    local source_node = minetest.get_node(pos).name
    local filled_item = bucket_map[source_node]
    
    if not filled_item or not ia_dunce.has_room_for(self, filled_item) then
        return false, "inventory_full_or_invalid_liquid"
    end

    return ia_dunce.bucket_action(self, pos)
end

--- Level 2: Preparation + Action (Placement)
-- Ensures a specific filled bucket is wielded, then places the liquid.
function ia_dunce.equip_and_place_liquid(self, pos, bucket_item)
    minetest.log('ia_dunce.equip_and_place_liquid()')
    
    if not ia_dunce.has_item(self, bucket_item) then
        return false, "missing_filled_bucket"
    end

    ia_dunce.wield_item(self, bucket_item)
    return ia_dunce.bucket_action(self, pos)
end

--- Level 3: Provisioning + Preparation + Action
-- Obtains a bucket if missing, then collects the target liquid.
function ia_dunce.obtain_and_collect(self, pos)
    minetest.log('ia_dunce.obtain_and_collect()')
    
    local is_empty = function(name) 
        return empty_buckets[name] == true
    end

    if not ia_dunce.has_item(self, is_empty) then
        -- Attempt to craft or take an empty bucket
        if ia_dunce.can_obtain_item("bucket:bucket_empty") then
            ia_dunce.craft_item(self, "bucket:bucket_empty")
        else
            return false, "cannot_obtain_bucket"
        end
    end

    return ia_dunce.equip_and_collect(self, pos)
end
