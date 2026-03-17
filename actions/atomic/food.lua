-- ia_fake_player/actions/atomic/food.lua

--- Low-level: Is this item actually edible?
-- @param item_name The name of the item.
-- @return boolean.
function ia_fake_player.actions.atomic.is_edible(item_name)
    local def = minetest.registered_items[item_name]
    -- In Minetest, edible items usually have an 'on_use' that calls minetest.item_eat
    -- or they belong to the 'food' group.
    return def and (minetest.get_item_group(item_name, "food") > 0 or def.on_use ~= nil)
end

--- Mid-level: Does the agent have food in their inventory?
function ia_fake_player.actions.atomic.can_eat(self)
    return ia_fake_player.actions.primitive.has_item(self, function(n) 
        return ia_fake_player.actions.atomic.is_edible(n) 
    end)
end

--- High-level: Could the agent eat if they crafted food (e.g., bread)?
function ia_fake_player.actions.atomic.could_eat(self)
    if ia_fake_player.actions.atomic.can_eat(self) then return true end

    -- Check for common trivial food recipes
    if ia_fake_player.actions.primitive.can_obtain_item(self, "farming:bread") or 
       ia_fake_player.actions.primitive.can_obtain_item(self, "default:apple") then
        return true
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the "eat" action with the currently wielded item.
function ia_fake_player.actions.atomic.eat(self)
    minetest.log('ia_fake_player.eat()')
    local itemstack = self:get_wielded_item()
    local item_name = itemstack:get_name()

    if ia_fake_player.actions.atomic.is_edible(item_name) then
        -- We simulate a right-click on "self" to trigger the on_use/item_eat logic
        local player_obj = self.fake_player
        local pointed_thing = {type="nothing"} -- Eating usually doesn't require a target
        
        local def = minetest.registered_items[item_name]
        if def and def.on_use then
            -- Trigger the engine's eating mechanic
            local leftover = def.on_use(itemstack, player_obj, pointed_thing)
            if leftover then
                self:set_wielded_item(leftover)
            end
            
            -- Play the standard eating sound
            minetest.sound_play("player_eat", {pos = self:get_pos(), gain = 0.7})
            return true
        end
    end
    return false, "not_edible_or_missing"
end

--- Level 2: Preparation + Action
-- Finds food in inventory, wields it, and eats.
function ia_fake_player.actions.atomic.equip_and_eat(self)
    minetest.log('ia_fake_player.equip_and_eat()')
    --local is_food = function(n) return ia_fake_player.actions.atomic.is_edible(n) end -- NOTE google gemini strikes again
    local is_food = ia_fake_player.actions.atomic.is_edible
    
    if ia_fake_player.actions.primitive.wield_by_condition(self, is_food) then
        return ia_fake_player.actions.atomic.eat(self)
    end
    return false, "no_food_found"
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts food (like bread from flour/wheat) then eats it.
function ia_fake_player.actions.atomic.craft_and_eat(self)
    minetest.log('ia_fake_player.craft_and_eat()')
    
    if not ia_fake_player.actions.atomic.can_eat(self) then
        -- Attempt to craft bread (a staple trivial food)
        if ia_fake_player.actions.primitive.can_obtain_item(self, "farming:bread") then
            ia_fake_player.actions.primitive.craft_item(self, "farming:bread")
        end
    end

    return ia_fake_player.actions.atomic.equip_and_eat(self)
end
