-- ia_dunce/armor.lua
-- NOTE musut handle boots, pants, shirt, helmet, shield and whatever the 6th slot is for

----- Low-level: Is this item name actually armor?
---- @param item_name The name of the item.
---- @param armor_type Optional specific group like "torso", "legs", "head", "feet".
--function ia_dunce.is_armorable(item_name, armor_type)
--    local is_armor = minetest.get_item_group(item_name, "armor") > 0
--    if armor_type then
--        return is_armor and minetest.get_item_group(item_name, armor_type) > 0
--    end
--    return is_armor
--end
--
----- Mid-level: Is the agent already wearing armor of this type?
--function ia_dunce.is_armored(self, armor_type)
--    -- This depends on the 'armor' mod being present
--    if not armor or not armor.get_armor_inventory then return false end
--    
--    local armor_inv = armor:get_armor_inventory(self.fake_player)
--    local list = armor_inv:get_list("armor")
--    
--    for _, stack in ipairs(list) do
--        if not stack:is_empty() and ia_dunce.is_armorable(stack:get_name(), armor_type) then
--            return true
--        end
--    end
--    return false
--end

--- Mid-level: Does the agent have suitable armor in their inventory?
function ia_dunce.can_armor(self, armor_type)
    return ia_dunce.has_item(self, function(n) 
        return ia_dunce.is_armorable(n, armor_type) 
    end)
end

--- High-level: Could the agent obtain armor via trivial crafting?
function ia_dunce.could_armor(self, armor_type)
    if ia_dunce.can_armor(self, armor_type) then return true end

    -- Check for common trivial armor recipes (e.g., wood/steel/leather)
    -- Note: We check for a generic chestplate if no type is specified
    local target = armor_type == "head" and "3d_armor:helmet_wood" 
                or armor_type == "torso" and "3d_armor:chestplate_wood"
                or "3d_armor:chestplate_wood"

    return ia_dunce.can_obtain_item(self, target)
end

--- Level 1: Atomic Action
-- Direct call to armor mod API to equip a stack.
function ia_dunce.equip_armor_stack(self, stack)
    minetest.log('ia_dunce.equip_armor_stack()')
    if armor and armor.equip then
        armor:equip(self.fake_player, stack)
        return true
    end
    return false, "armor_mod_missing"
end

----- Level 2: Preparation + Action
---- Finds armor in inventory and puts it on.
--function ia_dunce.search_and_equip_armor(self, armor_type)
--    minetest.log('ia_dunce.search_and_equip_armor()')
--    local inv = self.fake_player:get_inventory()
--    local main_list = inv:get_list("main")
--
--    for i, stack in ipairs(main_list) do
--        if not stack:is_empty() and ia_dunce.is_armorable(stack:get_name(), armor_type) then
--            local success = ia_dunce.equip_armor_stack(self, stack)
--            if success then
--                inv:set_stack("main", i, ItemStack("")) -- Remove from main inv
--                return true
--            end
--        end
--    end
--    return false, "no_armor_found_in_inventory"
--end
-- ia_dunce/armor.lua

--function ia_dunce.is_armor(item_name)
--	local groups   = minetest.get_item_group(item_name, "armor")
--	local is_armor = groups > 0
--	if is_armor then
--		return true
--	end
--	if minetest.get_item_group(name, "armor_head") > 0 then
--		return true
--	end
--	if minetest.get_item_group(name, "armor_torso") > 0 then
--		return true
--	end
--	if minetest.get_item_group(name, "armor_legs") > 0 then
--		return true
--	end
--	if minetest.get_item_group(name, "armor_feet") > 0 then
--		return true
--	end
--	if minetest.get_item_group(name, "armor_shield") > 0 then
--		return true
--	end
--	return false
--end

--- Low-level: Is this item name actually armor?
-- @param item_name The name of the item.
-- @param armor_type Optional specific group like "torso", "legs", "head", "feet".
function ia_dunce.is_armorable(item_name, armor_type)
    -- CHANGE: More robust check. Some items might lack the generic "armor" group 
    -- but possess specific slot groups.
    local groups = minetest.get_item_group(item_name, "armor")
    local is_armor = groups > 0
    
    -- Fallback: Check specific slot groups if generic "armor" group is 0
    if not is_armor then
        if minetest.get_item_group(item_name, "armor_head") > 0 or
           minetest.get_item_group(item_name, "armor_torso") > 0 or
           minetest.get_item_group(item_name, "armor_legs") > 0 or
           minetest.get_item_group(item_name, "armor_feet") > 0 then
            is_armor = true
        end
    end

    if armor_type then
        -- Handle both "legs" and "armor_legs" formats
        local specific_group = armor_type
        if not armor_type:find("armor_") then
            specific_group = "armor_" .. armor_type
        end
        return is_armor and minetest.get_item_group(item_name, specific_group) > 0
    end
    
    return is_armor
end

--- Mid-level: Is the agent already wearing armor of this type?
function ia_dunce.is_armored(self, armor_type)
    assert(armor_type, "armor_type is required for is_armored check")
    
    -- This depends on the 'armor' mod being present
    if not armor or not armor.get_armor_inventory then return false end
    
    -- Ensure we are checking the right group name
    local group_to_check = armor_type
    if not armor_type:find("armor_") then
        group_to_check = "armor_" .. armor_type
    end
    
    local armor_inv = armor:get_armor_inventory(self.fake_player)
    local list = armor_inv:get_list("armor")
    
    for _, stack in ipairs(list) do
        if not stack:is_empty() and minetest.get_item_group(stack:get_name(), group_to_check) > 0 then
            return true
        end
    end
    return false
end

--- Level 2: Preparation + Action
-- Finds armor in inventory and puts it on.
function ia_dunce.search_and_equip_armor(self, armor_type)
    minetest.log('action', '[ia_dunce] search_and_equip_armor() looking for ' .. (armor_type or "any armor"))
    
    local inv = self:get_inventory()
    local main_list = inv:get_list("main")

    for i, stack in ipairs(main_list) do
        if not stack:is_empty() and ia_dunce.is_armorable(stack:get_name(), armor_type) then
            local success, err = ia_dunce.equip_armor_stack(self, stack)
            if success then
                -- Remove exactly 1 item from the stack
                stack:take_item(1)
                inv:set_stack("main", i, stack)
                return true
            else
                minetest.log('warning', '[ia_dunce] Failed to equip ' .. stack:get_name() .. ': ' .. tostring(err))
            end
        end
    end
    return false, "no_armor_found_in_inventory"
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts armor if missing, then equips it.
function ia_dunce.craft_and_equip_armor(self, armor_type)
    minetest.log('ia_dunce.craft_and_equip_armor()')
    
    if not ia_dunce.can_armor(self, armor_type) then
        local target = armor_type == "torso" and "3d_armor:chestplate_wood" or "3d_armor:helmet_wood"
        if ia_dunce.can_obtain_item(self, target) then
            ia_dunce.craft_item(self, target)
        end
    end

    return ia_dunce.search_and_equip_armor(self, armor_type)
end

--- High-level: Returns a table of armor requirements for missing slots.
-- Useful for passing directly into handle_scavenging.
--function ia_dunce.get_armor_requirements(self)
--    local missing = {}
--    -- Standard 3d_armor elements
--    local elements = {"head", "torso", "legs", "feet"}
--
--    for _, element in ipairs(elements) do
--        -- Use the existing ia_dunce check
--        if not ia_dunce.is_armored(self, element) then
--            -- Requirements table format: { ["criteria"] = value }
--            -- We look for any item in the specific armor group (e.g., group:head)
--            missing["group:" .. element] = true
--        end
--    end
--
--    return next(missing) and missing or nil
--end
-- ia_dunce/armor.lua

--- High-level: Returns a table of armor requirements for missing slots.
function ia_dunce.get_armor_requirements(self)
    local missing = {}
    local elements = {"head", "torso", "legs", "feet"}
    local found_missing = false

    for _, element in ipairs(elements) do
        if not ia_dunce.is_armored(self, element) then
            -- We map the slot to the group name used by 3d_armor
            -- Requirements: { ["group:armor_head"] = true } etc.
            -- NOTE: 3d_armor usually uses "armor_head", "armor_torso", etc.
            local group_key = "group:armor_" .. element
            missing[group_key] = true
            found_missing = true
        end
    end
    
    if found_missing then
        -- Logging the requirement table for debugging
        --minetest.log("action", "[ia_dunce] Armor reqs for " .. self.mob_name .. ": " .. dump(missing))
        return missing
    end

    return nil
end
