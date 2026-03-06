-- ia_fake_player/names.lua

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())
local storage = minetest.get_mod_storage()

-- Persistence for reserved names
local reserved = minetest.deserialize(storage:get_string("reserved")) or {}
-- Volatile table to store references to active bridged entities
local active_mobs = {} 

local function save_reserved()
    storage:set_string("reserved", minetest.serialize(reserved))
end

---------------------------
-- 1. Identity Management
---------------------------

function ia_fake_player.is_name_available(name)
    if reserved[name] then return false end
    -- Use engine reference to avoid recursion
    if ia_fake_player.engine_get_player_by_name(name) then return false end
    if minetest.player_exists(name) then return false end
    return true
end

function ia_fake_player.reserve_name(name)
    if not ia_fake_player.is_name_available(name) then
        return false
    end
    reserved[name] = true
    save_reserved()
    return true
end

function ia_fake_player.release_name(name)
    reserved[name] = nil
    active_mobs[name] = nil
    save_reserved()
end

---------------------------
-- 2. Actor Registry
---------------------------

function ia_fake_player.register_active(name, object)
    assert(name, "register_active: name is required")
    assert(object, "register_active: object is required")
    active_mobs[name] = object
end

function ia_fake_player.unregister_active(name)
    active_mobs[name] = nil
end

function ia_fake_player.get_connected_mobs()
    local mobs = {}
    for name, obj in pairs(active_mobs) do
        local player = ia_fake_player.get_interface(obj)
        if player then
            table.insert(mobs, player)
        else
            active_mobs[name] = nil
        end
    end
    return mobs
end

function ia_fake_player.get_all_actors()
    local actors = ia_fake_player.engine_get_connected_players()
    local mobs = ia_fake_player.get_connected_mobs()
    for _, mob in ipairs(mobs) do
        table.insert(actors, mob)
    end
    return actors
end

function ia_fake_player.get_actor_by_name(name)
    local player = ia_fake_player.engine_get_player_by_name(name)
    if player then return player end
    
    local obj = active_mobs[name]
    return ia_fake_player.get_interface(obj)
end

---------------------------
-- 3. Permissions & Logic
---------------------------

function ia_fake_player.get_mob_default_privs()
    return {
        interact = true,
        shout = true,
        fly = false,
    }
end

----- Robust replacement for check_player_privs
---- Handles both string and table formats for 'privs'
--function ia_fake_player.check_actor_privs(name_or_actor, privs)
--    -- Normalize the name and detect if it's a fake player early
--    local name = type(name_or_actor) == "string" and name_or_actor or 
--                 (name_or_actor and name_or_actor.get_player_name and name_or_actor:get_player_name())
--
--    if not name or name == "" then
--        return false, {}
--    end
--
--    -- If it's NOT one of our active fake players, pass it to the engine
--    if not active_mobs[name] then
--        if ia_fake_player.engine_check_player_privs then
--            return ia_fake_player.engine_check_player_privs(name, privs)
--        end
--        return false, {}
--    end
--
--    -- Logic for Fake Players
--    local actor_privs = ia_fake_player.get_mob_default_privs()
--    local missing = {}
--    local has_all = true
--
--    -- Normalize 'privs' input (Engine allows table OR string)
--    local check_table = {}
--    if type(privs) == "string" then
--        check_table[privs] = true
--    elseif type(privs) == "table" then
--        check_table = privs
--    else
--        log("warning", "check_actor_privs: privs is invalid type " .. type(privs))
--        return false, {}
--    end
--
--    for p, _ in pairs(check_table) do
--        if not actor_privs[p] then
--            has_all = false
--            table.insert(missing, p)
--        end
--    end
--
--    return has_all, missing
--end
--function ia_fake_player.check_actor_privs(name, privs)
--    -- 1. Check if this is an active fake player
--    local actor = ia_fake_player.active_actors and ia_fake_player.active_actors[name]
--
--    if actor then
--        -- If the mod only asks for 'interact', return true immediately
--        if privs.interact and ia_util.table_size(privs) == 1 then
--            return true
--        end
--        -- If they ask for more, fake players generally have 'interact' + whatever else
--        local modified_privs = ia_util.table_copy(privs)
--        modified_privs.interact = nil -- We handle this
--
--        -- Check engine for remaining (usually false for fakes)
--        local has_others = ia_fake_player.engine_check_player_privs(name, modified_privs)
--        return has_others
--    end
--
--    -- 2. Fallback to engine for real players
--    return ia_fake_player.engine_check_player_privs(name, privs)
--end
---- ia_fake_player/names.lua
--
--function ia_fake_player.check_actor_privs(name, privs)
--    -- [FIX] Correct table name from active_actors to active_mobs
--    local actor = active_mobs[name]
--
--    if actor then
--        -- If the mod only asks for 'interact', return true immediately
--        if privs.interact and ia_util.table_size(privs) == 1 then
--            return true
--        end
--        
--        local modified_privs = ia_util.table_copy(privs)
--        modified_privs.interact = nil 
--
--        local has_others = ia_fake_player.engine_check_player_privs(name, modified_privs)
--        return has_others
--    end
--
--    return ia_fake_player.engine_check_player_privs(name, privs)
--end
-- ia_fake_player/names.lua

function ia_fake_player.check_actor_privs(name, privs)
    -- 1. Check if this is an active fake player
    -- [FIX] Using the correct table 'active_mobs' from this file
    local actor = active_mobs[name]

    if actor then
        -- 2. Handle 'interact' specifically (most common mod check)
        -- We use pairs to check if 'interact' is the only key without a size helper
        local has_interact = privs.interact
        local other_privs = false
        for k, _ in pairs(privs) do
            if k ~= "interact" then
                other_privs = true
                break
            end
        end

        if has_interact and not other_privs then
            return true
        end

        -- 3. If they ask for more than just interact, check the engine
        -- [FIX] Use engine's built-in table.copy
        local modified_privs = table.copy(privs)
        modified_privs.interact = nil 

        return ia_fake_player.engine_check_player_privs(name, modified_privs)
    end

    -- 4. Fallback for real players
    return ia_fake_player.engine_check_player_privs(name, privs)
end

---------------------------
-- 4. Engine Hooks
---------------------------

minetest.register_on_prejoinplayer(function(name)
    if reserved[name] then
        return "This ID is reserved for system entities."
    end
end)

-- ia_fake_player/names.lua

local auth_handler = minetest.get_auth_handler()

--- Registers a name in the engine's authentication database
-- This prevents the record_login crash and allows future "identity takeover"
function ia_fake_player.provision_auth(name)
    assert(type(name) == "string", "provision_auth: name must be a string")

    -- Check if they already exist in auth
    if auth_handler.get_auth(name) then
        return true
    end

    -- Create a new auth entry
    -- We use a random/dummy password because no one "logs in" via the menu yet.
    -- We give them 'interact' and 'shout' by default.
    local password = minetest.get_password_hash(name, math.random(1000, 9999))
    local success = auth_handler.create_auth(name, password)

    if success then
        -- Initialize privileges
        auth_handler.set_privileges(name, {interact = true, shout = true})
        -- log("action", "Provisioned engine auth for actor: " .. name)
    end

    return success
end

-- ia_fake_player/names.lua

--- Returns connection info for real players or a mock table for fake players
function ia_fake_player.get_actor_information(name)
    -- 1. Check engine first for real players
    local info = ia_fake_player.engine_get_player_information(name)
    if info then return info end

    -- 2. Check if it's one of our active fake players
    -- Note: using 'active_mobs' as identified in previous step
    if active_mobs[name] then
        return {
            address = "127.0.0.1",
            ip_version = 4,
            min_rtt = 0,
            max_rtt = 0,
            avg_rtt = 0,
            connection_uptime = 0, -- You could track this in 'data' if needed
            --protocol_version = minetest.get_protocol_version(),
            formspec_version = 4,
            lang_code = "en",
        }
    end

    -- 3. Not found
    return nil
end
