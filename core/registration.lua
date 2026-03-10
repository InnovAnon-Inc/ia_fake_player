-- ia_fake_player/registration.lua
-- The factory for turning Luanti Entities into Fake Players.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())
local gravity = tonumber(minetest.settings:get("movement_gravity")) or 9.81 -- TODO ia_space

---------------------------
-- 1. Internal Helpers
---------------------------

-- Safely bridges the entity object to the fake_player proxy
local function apply_actor_bridge(self)
    -- 1. Capture the prototype (the methods defined in register_entity)
    local entity_mt = getmetatable(self)
    local prototype = entity_mt and entity_mt.__index
    assert(prototype ~= nil, "Actor bridge failed: No entity prototype found")

    -- 2. Use fakelib to bridge the object to the fake_player
    -- self.fake_player was created during ia_fake_player.init_actor
    ia_fake_player.bridge_object(self.object, self, self.fake_player)

    -- 3. RE-WRAP the new metatable's __index to allow fallbacks
    local new_mt = getmetatable(self)
    local bridge_index = new_mt.__index
    assert(bridge_index ~= nil, "Actor bridge failed: bridge_object did not set __index")

    new_mt.__index = function(t, k)
        -- A. Try the bridge (Fake Player / Proxy) first
        local val
        if type(bridge_index) == "function" then
            val = bridge_index(t, k)
        else
            val = bridge_index[k]
        end

        if val ~= nil then return val end

        -- B. Fallback to the Prototype (Entity Definition)
        -- Ensures on_step, on_punch, etc. are found by the engine
        if type(prototype) == "function" then
            return prototype(t, k)
        else
            return prototype[k]
        end
    end
    
    --log("action", "Bridge established for " .. (self.mob_name or "unknown")) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
end

---------------------------
-- 2. Lifecycle API
---------------------------

function ia_fake_player.init_actor(self, staticdata)
    -- TODO need a guard ?
    local data = minetest.deserialize(staticdata) or {}

    -- A. Identity
    self.gender = data.gender or (ia_gender and ia_gender.generate_human_gender()) or "male"
    self.mob_name = data.mob_name or ia_fake_player.generate_random_name(self.gender)
    minetest.log('ia_fake_player.init_actor() mob_name='..tostring(self.mob_name))

    -- [NEW] Provision Engine Auth
    -- This satisfies the record_login assertion in builtin/game/auth.lua
    ia_fake_player.provision_auth(self.mob_name)

    -- B. Proxy Creation
    self.fake_player = ia_fake_player.create_player({
        name = self.mob_name,
        position = self.object:get_pos(),
        object = self.object,
    })
    
    -- C. Bridge & Registry
    apply_actor_bridge(self)
    ia_fake_player.register_active(self.mob_name, self.object)

    -- D. Metadata & State
    if data.state then
        ia_fake_player.apply_state(self, data.state)
    else
        self:get_meta():set_string(ia_gender.attr, self.gender)
    end

    -- E. Join Callbacks
    -- Now safe to call without pcall because auth entry exists
    ia_fake_player.trigger_join(self) -- TODO double call ? maybe not

    -- F. Post-Join Syncs
--    if armor then sync_armor_inventory(self) end -- NOTE bug fixed: no longer necessary
    self.object:set_acceleration({x = 0, y = -gravity, z = 0})
end

---------------------------
-- 3. Registration Factory
---------------------------

ia_fake_player.default_props = {
    visual       = "mesh",
    mesh         = "character.b3d",
    textures     = {"character.png"},
    visual_size  = {x=1, y=1},
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    stepheight   = 0.6,
    health_max   = 20,
    physical     = true,
}

function ia_fake_player.register_actor(name, definition)
    local props = table.copy(ia_fake_player.default_props)
    if definition.initial_properties then
        for k, v in pairs(definition.initial_properties) do
            props[k] = v
        end
    end

    local final_def = table.copy(definition)
    final_def.initial_properties = props

    -- Injected Activation
--    local user_on_activate = definition.on_activate
--    final_def.on_activate = function(self, staticdata, dtime_s)
--        ia_fake_player.init_actor(self, staticdata)
--        assert(self.mob_name ~= nil, "Activation failed: mob_name is nil")
--        ia_fake_player.register_active(self.mob_name, self.object)
--        
--        if user_on_activate then
--            user_on_activate(self, staticdata, dtime_s)
--        end
--    end
    -- Injected Activation
    local user_on_activate = definition.on_activate
    final_def.on_activate = function(self, staticdata, dtime_s)
        ia_fake_player.init_actor(self, staticdata)
        assert(self.mob_name ~= nil, "Activation failed: mob_name is nil")
        -- [REMOVED] redundant register_active call
       
        local data = minetest.deserialize(staticdata) or {} -- NOTE testing (mapblock)
	--if data.persistent then -- NOTE testing (mapblock; optional) -- TODO need a way to enable/disable this... globally? per-mob? idc. do something easy
	    ia_fake_player.set_persistence(self, true)
	--end

        if user_on_activate then
            user_on_activate(self, staticdata, dtime_s)
        end
    end

    -- Injected Persistence
    final_def.get_staticdata = function(self)
        local state = ia_fake_player.get_state(self)
        return minetest.serialize({
            gender = self.gender,
            mob_name = self.mob_name,
            state = state,
	    persistent = (self._forceload_handle ~= nil), -- NOTE testing (mapblock)
        })
    end

    -- Injected Combat (3d_armor)
    local user_on_punch = definition.on_punch
    final_def.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if armor and armor.punch then
            armor:punch(self, puncher, time_from_last_punch, tool_capabilities)
        end
        if user_on_punch then
            user_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
        end
    end

    -- Injected Environmental Processing
    local user_on_step = definition.on_step
    final_def.on_step = function(self, dtime)
        if not self.object or not self.object:get_pos() then
            ia_fake_player.unregister_active(self.mob_name)
            return
        end

	if self._forceload_handle then -- NOTE testing (mapblock)
            local pos = self.object:get_pos()
            -- Only re-anchor if we've moved significantly to save CPU
            if not self._last_load_pos or vector.distance(pos, self._last_load_pos) > 8 then -- TODO make sure this is accurate (don't want weird edge cases where the bug sometimes re-emerges)
                ia_fake_player.set_persistence(self, true)
                self._last_load_pos = pos
            end
        end

        -- Handle Drowning, Falling, and Fire
        ia_fake_player.handle_environment_effects(self, dtime)

        if self:get_hp() <= 0 then return end

        if user_on_step then
            user_on_step(self, dtime)
        end
    end

    minetest.register_entity(name, final_def)
    --log("action", "Registered actor entity: " .. name) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
end

function ia_fake_player.set_persistence(self, enabled)
    local pos = self.object:get_pos()
    if not pos then return end

    -- Clean up existing handle first
    if self._forceload_handle then
        minetest.forceload_free_block(self._forceload_handle)
        self._forceload_handle = nil
    end

    if enabled then
        -- We use the pos directly; forceload_block returns the pos it locked
        self._forceload_handle = pos
        minetest.forceload_block(pos, true) -- 'true' makes it persistent across restarts
        minetest.log("action", "[ia_fake_player] Forceloading block at " .. minetest.pos_to_string(pos) .. " for " .. (self.mob_name or "unknown"))
    end
end

---------------------------
-- 4. Global Overrides
---------------------------

-- Patch 3d_armor to accept our fake players -- NOTE bug fixed: no longer necessary
--if armor and armor.get_valid_player then
--    local old_get_valid_player = armor.get_valid_player
--    armor.get_valid_player = function(self, player, msg)
--        -- If it's a bridged actor, it will respond to is_player()
--        if player and player.is_player and player:is_player() then
--            local name = player:get_player_name()
--            if name then
--                local inv = minetest.get_inventory({type="detached", name=name.."_armor"})
--                if inv then return name, inv end
--            end
--        end
--        return old_get_valid_player(self, player, msg)
--    end
--end
