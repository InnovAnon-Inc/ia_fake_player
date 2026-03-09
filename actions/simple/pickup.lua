-- ia_fake_player/actions/simple/pickup.lua

--- Internal Helper: Retrieves the inventory object for the fake player.
--local function get_inv(self)
--    return self:get_inventory()
--end

--- Attempts to pick up a specific item entity (dropped item).
-- @param self The fake player object.
-- @param item_obj The ObjectRef of the dropped item.
-- @return boolean, string (Success status and reason).
function ia_fake_player.actions.simple.pickup_item(self, item_obj)
	minetest.log('ia_fake_player.actions.simple.pickup_item()')
    local entity = item_obj:get_luaentity()
    if not entity or entity.name ~= "__builtin:item" then
        return false, "not_an_item"
    end

    -- Validate distance (Standard pickup range is ~2.0)
    local dist = vector.distance(self:get_pos(), item_obj:get_pos())
    if dist > 2.0 then
        return false, "too_far"
    end

    local inv = self:get_inventory()
    local stack = ItemStack(entity.itemstring)
    local leftover = inv:add_item("main", stack)

    -- Handle stack updates or removal
    if leftover:get_count() == stack:get_count() then
        return false, "inventory_full"
    elseif leftover:is_empty() then
        item_obj:remove()
    else
        entity.itemstring = leftover:to_string()
    end

    minetest.sound_play("item_pickup", {pos = self:get_pos(), gain = 0.3})
    return true
end

--- Scans and picks up items matching a condition within range.
-- @param self The fake player object.
-- @param radius Search radius.
-- @param condition Optional function(itemstack).
function ia_fake_player.actions.simple.pickup_nearby(self, radius, condition)
	minetest.log('ia_fake_player.actions.simple.pickup_nearby()')
    local items = self:find_items(radius, condition) -- Calls the sensor helper
    local any_picked_up = false

    for _, item_data in ipairs(items) do
        if ia_fake_player.actions.simple.pickup_item(self, item_data.object) then
            any_picked_up = true
        end
    end

    return any_picked_up
end

