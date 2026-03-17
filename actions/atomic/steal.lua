-- ia_fake_player/actions/atomic/steal.lua

--- Low-level: Should this specific item be "taxed"?
-- @param item_name The name of the item.
-- @return boolean.
function ia_fake_player.actions.atomic.is_valuable(item_name) -- FIXME use graph theory
    -- Whitelist of typical survival valuables
    local valuables = {
        ["default:diamond"] = true,
        ["default:mese_crystal"] = true,
        ["default:gold_ingot"] = true,
        ["default:iron_ingot"] = true,
        ["default:apple"] = true,
        ["farming:bread"] = true,
    }
    
    -- Safety: Never steal the Dunce's own internal tools or system items
    --if item_name:sub(1, 9) == "ia_fake_player:" then 
    --    return false 
    --end
    
    return valuables[item_name] or false
end

--- Mid-level: Does the target (Player or Entity) have anything worth taking?
-- @param target The ObjectRef to check.
-- @return boolean.
function ia_fake_player.actions.atomic.can_steal_from(self, target)
    if not target or not target:get_inventory() then 
        return false 
    end
    
    local inv = target:get_inventory()
    local main_list = inv:get_list("main")
    if not main_list then return false end

    for _, stack in ipairs(main_list) do
        if not stack:is_empty() and ia_fake_player.actions.atomic.is_valuable(stack:get_name()) then
            return true
        end
    end
    return false
end

--- High-level: Is a robbery viable right now?
-- Checks proximity, inventory space, and target value.
-- @param target The ObjectRef.
-- @return boolean.
function ia_fake_player.actions.atomic.could_steal_from(self, target)
    if not target then return false end
    
    -- Distance check (Standard interaction range ~3.0)
    local dist = vector.distance(self:get_pos(), target:get_pos())
    if dist > 3.0 then return false end

    -- Value and Space check
    if not ia_fake_player.actions.atomic.can_steal_from(self, target) then return false end
    if ia_fake_player.actions.primitive.is_inventory_full(self) then return false end

    return true
end

--- Level 1: Atomic Action
-- Performs the actual "levy" of a single stack from a target.
-- @param target The PlayerRef or Entity ObjectRef.
-- @return boolean, string (Success status and reason).
function ia_fake_player.actions.atomic.rob_target(self, target)
    minetest.log('ia_fake_player.rob_target()')
    
    -- 1. Validate Distance (Edge Case: Target moved away during call)
    local dist = vector.distance(self:get_pos(), target:get_pos())
    if dist > 3.0 then 
        return false, "target_too_far" 
    end

    local tgt_inv = target:get_inventory()
    local vil_inv = self:get_inventory()
    
    -- 2. Validate Inventory Access
    if not tgt_inv or not vil_inv then 
        return false, "no_inventory_access" 
    end

    local size = tgt_inv:get_size("main")
    for i = 1, size do
        local stack = tgt_inv:get_stack("main", i)
        
        -- 3. Find the first valuable stack
        if not stack:is_empty() and ia_fake_player.actions.atomic.is_valuable(stack:get_name()) then
            local item_name = stack:get_name()
            
            -- 4. Transfer the item
            local leftover = vil_inv:add_item("main", stack)
            tgt_inv:set_stack("main", i, leftover)
            
            -- Feedback Logic
            if target:is_player() then
                minetest.chat_send_player(target:get_player_name(), 
                    "The Dunce has levied taxes: 1x " .. item_name)
            end
            
            minetest.sound_play("item_pickup", {pos = self:get_pos(), gain = 0.5})
            return true, "success"
        end
    end
    
    return false, "no_valuables_found"
end

--- Finds potential theft targets (Players/Entities with valuables).
function ia_fake_player.actions.atomic.find_theft_targets(self, radius, sort_func)
    local pos = self:get_pos()
    return ia_fake_player.actions.primitive.get_sorted_objects(pos, radius, function(obj)
        -- Use the primitive from steal.lua to check viability
        return obj ~= self.object and ia_fake_player.actions.atomic.can_steal_from(self, obj)
    end, sort_func)
end
