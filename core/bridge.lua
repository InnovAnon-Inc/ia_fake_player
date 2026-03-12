-- ia_fake_player/bridge.lua
-- This bridge provides the Player API stubs/data that entities lack.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

---------------------------
-- 1. Elite Bridge Injection
---------------------------

function ia_fake_player.bridge_object(object, entity, proxy)
    assert(object and object:is_valid(), "bridge_object: Invalid ObjectRef")
    assert(proxy, "bridge_object: Proxy is nil")
    
    local data = proxy.data

    -- 1. BATTLE-HARDENING: Direct injection of fakelib methods
    -- This ensures they are found even by engine code that bypasses metatables.
    local fakelib_methods = {
	    "get_player_name",
	    "get_guid",
	    "get_inventory",
            "get_meta",
	    "get_look_dir",
	    "get_look_horizontal",
	    "set_look_horizontal",
	    "get_look_vertical",
	    "set_look_vertical",
	    "get_player_control",
	    "get_player_control_bits",
	    "get_pos",
	    "set_pos",
	    "add_pos",
	    "get_wield_index",
	    "get_wield_list",
	    "get_wielded_item",
	    "set_wielded_item",

	    "is_player",
	    --"get_animation",
	    --"get_armor_groups",
	    --"get_bone_override",
	    --"get_bone_position",
	    --"get_breath",
	    --"get_camera",
	    --"get_children",
	    --"get_clouds",
	    --"get_eye_offset",
	    --"get_flags",
	    "get_formspec_prepend",
	    --"get_fov",
	    --"get_hp",
	    "get_inventory_formspec",
	    --"get_lighting",
	    --"get_local_animation",
	    --"get_moon",
	    --"get_nametag_attributes",
	    --"get_physics_override",
            "get_physics_override", -- TODO
            "set_physics_override", -- TODO
	    --"get_properties",
	    "get_sky_color",
	    --"get_sky",
	    --"get_stars",
	    --"get_sun",
	    --"get_velocity",
            --"get_player_velocity",
	    "hud_get_all",
	    "hud_get_flags",
	    "hud_get_hotbar_image",
	    "hud_get_hotbar_itemcount",
	    "hud_get_hotbar_selected_image",
	    "is_valid",

            --"add_to_inventory",
    }

    for _, method in ipairs(fakelib_methods) do
        if proxy[method] then
            -- We bind to proxy so fakelib has the correct internal context
            entity[method] = function(_, ...)
                return proxy[method](proxy, ...)
            end
        end
    end

    -- 2. ENGINE COMPATIBILITY: Required for auth.lua:record_login
    -- We put these directly on the entity table.
    --entity.get_player_name = function() return data.name end
    --entity.is_player       = function() return true end
    --entity.get_wield_index = function() return data.wield_index or 1 end
    --entity.get_wield_list  = function() return data.wield_list or "main" end
    entity.get_breath      = function(self)
	    if data.breath ~= nil then return data.breath end
	    return 11
    end
    entity.set_breath      = function(self, value)
	assert(value ~= nil)
	assert(tonumber(value) == value, tostring(value))
        data.breath = value
    end

    -- 3. THE COMPREHENSIVE BRIDGE
    local mt = {
        __index = function(t, k)
            -- Identity & Internal data access
            if k == "data" then return data end
            if k == "object" then return object end
            if k == "is_fake_player" then return true end

            -- PRIMARY: Your Comprehensive API (ia_fake_player/player.lua)
            local val = ia_fake_player[k]
            if val ~= nil then
                if type(val) == "function" then
                    -- Bind to 't' (the bridged table)
                    return function(_, ...) return val(t, ...) end
                end
                return val
            end

            -- SECONDARY: Engine ObjectRef fallback
            -- Bound to 'object' (userdata) to avoid "bad self" errors.
            local engine_val = object[k]
            if engine_val ~= nil then
                if type(engine_val) == "function" then
                    return function(_, ...) return engine_val(object, ...) end
                end
                return engine_val
            end
            
            return nil
        end
    }

    setmetatable(entity, mt)

--local old_set_hp = entity.set_hp
--assert(old_set_hp)
--entity.set_hp = function(self, value, reason)
--    assert(self   ~= nil)
--    assert(value  ~= nil)
--    assert(reason ~= nil)
--    -- 1. Calculate the delta before updating the state
--    local old_hp = self:get_hp() --or 20
--    old_set_hp(self, value, reason)
--    local new_hp = self:get_hp()
--    --if (new_hp >= old_hp) then return end
--    --if (new_hp == old_hp) then return end
--    local d_hp   = (new_hp - old_hp)
--    --assert(d_hp < 0)
--    --assert(d_hp == 0)
--    ia_fake_player.on_playerhp_change(self, d_hp, reason) -- TODO
--end
end

---------------------------
-- 2. Proxy & Interface Helpers
---------------------------

function ia_fake_player.create_player(params)
    minetest.log('ia_fake_player.create_player(name='..tostring(params.name)..')')
    assert(params.name, "create_player: name required")
    assert(params.object, "create_player: object required")

    -- Use fakelib to create a secure proxy
    local proxy = fakelib.create_player({
        name = params.name,
        position = params.object:get_pos(),
    })

    -- Initialize internal structures
    proxy.data.metadata = fakelib.create_metadata()
    proxy.data.inventory = fakelib.create_inventory({
        --main = 32, craft = 9, armor = 6, hand = 1 -- NOTE wrong
	main = 32, craft = 9, craftpreview = 1, craftresult = 1 -- NOTE canonical
    })
    
    proxy.data.huds = {}
    proxy.data.wield_index = 1
    proxy.data.wield_list = "main"
    proxy.data.object = params.object
    proxy.data.name = params.name

    -- Create mirror for 3d_armor if library supports it
    --if ia_fake_player.create_mirror then -- TODO what is this? 3d armor automatically creates & syncs a detached inv
    proxy.data.detached_name = ia_fake_player:create_mirror(params.name, proxy.data.inventory)
    --end

    return proxy
end

function ia_fake_player.get_interface(obj)
    if not obj or (type(obj) == "userdata" and not obj:is_valid()) then return nil end
    
    -- Case 1: Real engine player (Userdata)
    if type(obj) == "userdata" and obj:is_player() then return obj end
    
    -- Case 2: Already a bridged entity (Table)
    if type(obj) == "table" and obj.is_player and obj:is_player() then
        return obj
    end
    
    -- Case 3: Raw ObjectRef to a fake player entity (Userdata)
    if type(obj) == "userdata" then
        local ent = obj:get_luaentity()
        if ent and ent.is_player and ent:is_player() then
            -- Note: In this case, we return the entity table (the bridge)
            return ent
        end
    end
    
    return nil
end




































--function ia_fake_player.on_playerhp_change(self, d_hp, reason)
--    local player = ia_fake_player.get_interface(self)
--    assert(player)
--    --if not player then return end
--
--    -- Only notify the ketchup script and other ia_ listeners
--    -- We use our own custom callback system to avoid clashing with the engine's protected tables
--    --if ia_fake_player.registered_on_hp_change then
--        for _, callback in ipairs(ia_fake_player.registered_on_hp_change) do
--            callback(player, d_hp, reason)
--        end
--    --end
--end
