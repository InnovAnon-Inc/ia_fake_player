-- ia_fake_player/actions/atomic/attack.lua
-- TODO more sword types

--- Low-level: Is the target valid to be hit?
-- Environmental/Entity check regardless of agent status.
function ia_fake_player.actions.atomic.is_attackable(target)
    -- Target must exist, have an ObjectRef, and be alive.
    return target and target.get_hp and target:get_hp() > 0
end

--- Mid-level: Is the mob currently armed and ready to engage the target?
function ia_fake_player.actions.atomic.can_attack(self, target)
    if not ia_fake_player.actions.atomic.is_attackable(target) then return false end

    -- Check if we are currently holding or carrying a weapon.
    local is_weapon = function(n)
        return minetest.get_item_group(n, "sword") > 0 or 
               minetest.get_item_group(n, "weapon") > 0
    end
    return ia_fake_player.actions.primitive.has_item(self, is_weapon)
end

--- High-level: Could the mob attack if it performed a trivial craft?
function ia_fake_player.actions.atomic.could_attack(self, target)
    -- Check if we can already attack.
    if ia_fake_player.actions.atomic.can_attack(self, target) then return true end

    -- Only consider crafting if the target is worth attacking.
    if ia_fake_player.actions.atomic.is_attackable(target) then
        -- Check for common trivial weapons.
        if ia_fake_player.actions.primitive.can_obtain_item("default:sword_stone") or 
           ia_fake_player.actions.primitive.can_obtain_item("default:sword_wood") then
            return true
        end
    end

    return false
end

--- Level 1: Atomic Action
-- Performs the punch/hit interaction.
function ia_fake_player.actions.atomic.attack(self, target_obj)
    minetest.log('ia_fake_player.actions.atomic.attack()')
    -- We use left_click with keep_tool=true to prevent swapping back to hand immediately.
    return ia_fake_player.actions.primitive.left_click(self, target_obj, true)
end

--- Level 2: Preparation + Action
-- Ensures a weapon is wielded before attacking.
function ia_fake_player.actions.atomic.equip_and_attack(self, target_obj)
    minetest.log('ia_fake_player.actions.atomic.equip_and_attack()')
    local is_weapon = function(n)
        return minetest.get_item_group(n, "sword") > 0 or 
               minetest.get_item_group(n, "weapon") > 0
    end

    -- Attempt to find and wield the best weapon available.
    ia_fake_player.actions.primitive.wield_by_condition(self, is_weapon)
    return ia_fake_player.actions.atomic.attack(self, target_obj)
end

--- Level 3: Provisioning + Preparation + Action
-- Crafts a weapon if missing, then equips and attacks.
function ia_fake_player.actions.atomic.craft_and_attack(self, target_obj)
    minetest.log('ia_fake_player.actions.atomic.craft_and_attack()')

    if not ia_fake_player.actions.atomic.can_attack(self, target_obj) then
        -- Attempt to craft a basic defense if we have materials.
        if ia_fake_player.actions.primitive.can_obtain_item("default:sword_stone") then
            ia_fake_player.actions.primitive.craft_item(self, "default:sword_stone")
        elseif ia_fake_player.actions.primitive.can_obtain_item("default:sword_wood") then
            ia_fake_player.actions.primitive.craft_item(self, "default:sword_wood")
        end
    end

    return ia_fake_player.actions.atomic.equip_and_attack(self, target_obj)
end
