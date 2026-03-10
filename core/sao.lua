-- ia_fake_player/sao.lua
-- Emulation of ServerActiveObject (PlayerSAO) logic for bridged entities.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

---------------------------
-- 1. Breathing & Drowning
---------------------------

function ia_fake_player.handle_breathing_and_drowning(self, dtime)
    -- Initialize timers on the entity if they don't exist
    self._breathing_timer = (self._breathing_timer or 0) + dtime
    self._drowning_timer = (self._drowning_timer or 0) + dtime

    -- Eye-level node check
    local pos = self.object:get_pos()
    if not pos then return end
    
    -- Use data properties if available, fallback to standard humanoid height
    local props = self.object:get_properties()
    local eye_height = props.eye_height or 1.625
    local head_pos = {x = pos.x, y = pos.y + eye_height, z = pos.z}
    
    local node = minetest.get_node_or_nil(head_pos)
    if not node then return end
    
    local def = minetest.registered_nodes[node.name]
    local is_submerged = def and (def.drowning and def.drowning > 0)

    -- Drowning Logic (Every 2 seconds)
    if is_submerged then
        if self._drowning_timer >= 2.0 then
            self._drowning_timer = 0
            local breath = self:get_breath()
	    assert(breath ~= nil)
	    assert(tonumber(breath) == breath, tostring(breath))
            if breath > 0 then
                self:set_breath(breath - 1)
            else
                local damage = def.drowning or 1
                -- set_hp triggers armor/death logic
                self:set_hp(self:get_hp() - damage)
            end
        end
    -- Breathing Logic (Every 0.5 seconds)
    elseif self._breathing_timer >= 0.5 then
        self._breathing_timer = 0
        local breath = self:get_breath()
	assert(breath ~= nil)
	assert(tonumber(breath) == breath, tostring(breath))
        local max_breath = 11 -- Engine default
        if breath < max_breath then
            self:set_breath(breath + 1)
        end
    end
end

---------------------------
-- 2. Falling Damage
---------------------------

function ia_fake_player.handle_falling_damage(self, dtime)
    local pos = self.object:get_pos()
    local vel = self.object:get_velocity()
    if not pos or not vel then return end

    -- Initialize tracking variables
    self._last_y_vel = self._last_y_vel or 0

    -- Detection: Check if the downward velocity drop was significant
    -- If current Y velocity is ~0 (hit ground) and we were falling fast:
    if vel.y >= -0.1 and self._last_y_vel < -4.0 then
        local safe_speed = 4.0
        local multiplier = 2.0
        local impact_speed = math.abs(self._last_y_vel)

        if impact_speed > safe_speed then
            local damage = math.floor((impact_speed - safe_speed) * multiplier)

            -- 3d_armor integration: Feather fall check
            local name = self:get_player_name()
            if armor and armor.def and armor.def[name] and (armor.def[name].feather or 0) > 0 then
                damage = 0
                --log("action", name .. " feather-falled, negating " .. damage .. " damage.") -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
            end

            if damage > 0 then
                --log("action", string.format("%s took %d fall damage (impact: %.2f)",
                --    name, damage, impact_speed)) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string

                self:set_hp(self:get_hp() - damage)

                minetest.sound_play("default_hard_footstep", {
                    pos = pos,
                    gain = 1.0,
                    max_hear_distance = 10,
                })
            end
        end
    end

    -- Update tracking for next step
    self._last_y_vel = vel.y
end

---------------------------
-- 3. Node Damage (Lava/Fire)
---------------------------

function ia_fake_player.handle_node_damage(self, dtime)
    self._node_damage_timer = (self._node_damage_timer or 0) + dtime
    if self._node_damage_timer < 1.0 then return end
    self._node_damage_timer = 0

    local pos = self.object:get_pos()
    if not pos then return end

    -- Check multiple points to ensure we catch lava-wading or ceiling-fire
    local positions = {
        {x=pos.x, y=pos.y + 0.2, z=pos.z}, -- Feet
        {x=pos.x, y=pos.y + 1.0, z=pos.z}, -- Torso
        {x=pos.x, y=pos.y + 1.6, z=pos.z}, -- Head
    }

    local max_damage = 0
    for _, p in ipairs(positions) do
        local node = minetest.get_node_or_nil(p)
        if node then
            local def = minetest.registered_nodes[node.name]
            if def and def.damage_per_second and def.damage_per_second > max_damage then
                max_damage = def.damage_per_second
            end
        end
    end

    if max_damage > 0 then
        -- 3d_armor integration: Fire protection check
        local name = self:get_player_name()
        if armor and armor.def and armor.def[name] and (armor.def[name].fire or 0) > 0 then
            max_damage = math.max(0, max_damage - armor.def[name].fire)
        end

        if max_damage > 0 then
            self:set_hp(self:get_hp() - max_damage)
            
            -- Lava sizzle sound for high damage
            if max_damage > 3 then
                minetest.sound_play("default_lava_level_heavy", {pos = pos, gain = 0.5})
            end
        end
    end
end

---------------------------
-- 4. Unified Interface
---------------------------

--- Combined Environmental Handler to be called in the entity's on_step
function ia_fake_player.handle_environment_effects(self, dtime)
    assert(self.object and self.object:is_valid(), "handle_environment_effects: Invalid object")
    
    ia_fake_player.handle_breathing_and_drowning(self, dtime)
    ia_fake_player.handle_falling_damage(self, dtime)
    ia_fake_player.handle_node_damage(self, dtime)
end
