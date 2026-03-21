-- ia_fake_player/core/names.lua
-- FIXME randomly generated passwords MUST be saved in order to satisfy the basic reqs

local modname = core.get_current_modname()
local log = ia_util.get_logger(modname)
local assert = ia_util.get_assert(modname)
local storage = core.get_mod_storage()
local auth_handler = core.get_auth_handler()

-- Persistence for reserved names
local reserved = core.deserialize(storage:get_string("reserved")) or {}
-- Volatile table to store references to active bridged entities
local active_mobs = {} 

local function save_reserved()
    storage:set_string("reserved", core.serialize(reserved))
end

---------------------------
-- 1. Identity Management
---------------------------

function ia_fake_player.is_name_available(name)
    if reserved[name] then return false end
    -- Use engine reference to avoid recursion
    if ia_fake_player.engine_get_player_by_name(name) then return false end
    if core.player_exists(name) then return false end
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

--- Retrieves the active ObjectRef for a registered fake player
function ia_fake_player.get_active_object(name)
    return active_mobs[name]
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

--core.register_on_prejoinplayer(function(name, ip)
--    -- If the name is reserved for a bot, the engine's built-in auth
--    -- will handle password verification. If they pass, we let them in.
--    if reserved[name] and not auth_handler.get_auth(name) then
--        return "Identity reserved. No authentication record found."
--    end
--end)
core.register_on_prejoinplayer(function(name, ip)
    if reserved[name] then
        local auth = auth_handler.get_auth(name)
        if not auth then
            return "This ID is reserved for system entities and has no password record."
        end
        -- If auth exists, they can proceed to password verification
    end
end)


----- Registers a name in the engine's authentication database
---- This prevents the record_login crash and allows future "identity takeover"
--function ia_fake_player.provision_auth(name)
--    assert(type(name) == "string", "provision_auth: name must be a string")
--
--    -- Check if they already exist in auth
--    if auth_handler.get_auth(name) then
--        return true
--    end
--
--    -- Create a new auth entry
--    -- We use a random/dummy password because no one "logs in" via the menu yet.
--    -- We give them 'interact' and 'shout' by default.
--    local password = core.get_password_hash(name, math.random(1000, 9999)) -- FIXME need to save that password
--    local success = auth_handler.create_auth(name, password)
--
--    if success then
--        -- Initialize privileges
--        auth_handler.set_privileges(name, {interact = true, shout = true})
--        -- log("action", "Provisioned engine auth for actor: " .. name)
--    end
--
--    return success
--end
function ia_fake_player.provision_auth(name, password)
    assert(type(name) == "string", "provision_auth: name must be a string")
    
    if auth_handler.get_auth(name) then return true end

    -- If no password provided, generate a dummy one for system entities
    local pass = password or math.random(100000, 999999) -- FIXME need to save that password
    local hash = core.get_password_hash(name, tostring(pass))
    
    local success = auth_handler.create_auth(name, hash)
    if success then
        auth_handler.set_privileges(name, {interact = true, shout = true})
        -- If we generated a password, we might want to log it or store it 
        -- for the "descendant" takeover downstream.
    end
    return success
end

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
            --protocol_version = core.get_protocol_version(),
            formspec_version = 4,
            lang_code = "en",
        }
    end

    -- 3. Not found
    return nil
end

---------------------------
-- 1. Identity & State Transfer
---------------------------

--- Deep copy of inventory and metadata from one ObjectRef to another.
-- Used for seamless "Identity Handoff".
local function transfer_identity_state(source, target)
    assert(source and target, "transfer_identity_state: source or target is nil")
    -- 1. Inventory Transfer
    local s_inv = source:get_inventory()
    local t_inv = target:get_inventory()
    if s_inv and t_inv then
        for listname, _ in pairs(s_inv:get_lists()) do
            t_inv:set_list(listname, s_inv:get_list(listname))
        end
    end

    -- 2. Metadata/Attribute Transfer
    local s_meta = source:get_meta()
    local t_meta = target:get_meta()
    if s_meta and t_meta then
        local fields = s_meta:to_table().fields
        for key, value in pairs(fields) do
            t_meta:set_string(key, value)
        end
    end

    -- 3. Physics & Position
    assert(source                     ~= nil)
    assert(source.get_pos             ~= nil)
    assert(source.get_look_horizontal ~= nil)
    assert(source.get_look_vertical   ~= nil)

    assert(target                     ~= nil)
    assert(target.set_pos             ~= nil)
    assert(target.set_look_horizontal ~= nil)
    assert(target.set_look_vertical   ~= nil)

    local pos    = source:get_pos()
    local look_h = source:get_look_horizontal()
    local look_v = source:get_look_vertical()
    assert(pos                        ~= nil)
    assert(look_h                     ~= nil)
    assert(look_v                     ~= nil)
    assert(type(pos)                  == 'table')
    assert(type(look_h)               == 'table')
    assert(type(look_v)               == 'table')

    --target:set_pos            (pos)
    --target:set_look_horizontal(look_h)
    --target:set_look_vertical  (look_v)
    if pos then target:set_pos(pos) end
    if look_h then target:set_look_horizontal(look_h) end
    if look_v then target:set_look_vertical(look_v) end
end

---------------------------
-- 2. Handoff Logic (The "Swap")
---------------------------

--- MOB -> PLAYER: A real player logs in and takes over an active fake player.
function ia_fake_player.handle_player_takeover(player)
    assert(player and player:is_player(), "handle_player_takeover: Invalid player object")
    if type(player) ~= "userdata" then -- CRITICAL: Ensure this is a real engine player.
        return
    end
    local name = player:get_player_name()
    local mob_obj = active_mobs[name]

    if mob_obj then
        core.log("action", "Player " .. name .. " is taking over active mob shell.")

        -- Transfer mob's current state (items they gathered, where they moved) to player
        transfer_identity_state(mob_obj, player)

        -- Remove the mob entity
        mob_obj:remove()

        -- Clean up registries
        active_mobs[name] = nil
        reserved[name] = nil
        save_reserved()
    end
end


--- PLAYER -> MOB: A fake player is spawned to stand-in for a logged-out player.
-- @param name The player name to mirror
-- @param pos Optional override position
function ia_fake_player.spawn_stand_in(name, pos)
    if active_mobs[name] or ia_fake_player.engine_get_player_by_name(name) then
        return nil, "identity_active"
    end

    -- 1. Ensure the name is reserved so the real player is blocked from joining
    -- until we are ready or the stand-in is cleared.
    reserved[name] = true
    save_reserved()

    -- 2. Spawn the entity (Logic handled in your mob/ia_humanoid code)
    local mob_entity = ia_fake_player.spawn_mob_entity(name, pos)

    -- 3. Transfer player's last saved state to the mob
    -- Note: This works because player_exists(name) is true even when offline,
    -- and we can load their inventory/meta via internal engine calls if needed,
    -- but usually, we do this right at the moment of logout.
    if mob_entity then
        active_mobs[name] = mob_entity
    else
        -- If spawning failed, release the name so the player isn't locked out
        reserved[name] = nil
        save_reserved()
    end

    return mob_entity
end


---------------------------
-- 4. Connectivity Hooks
---------------------------

-- Block real players if their "Identity" is currently occupied by an active mob

core.register_on_joinplayer(function(player)
    -- If a mob was standing in for this player, kill the mob and transfer state back
    ia_fake_player.handle_player_takeover(player) -- FIXME ai crap
end)

-- 4b. Leave/Stand-in
core.register_on_leaveplayer(function(player, timeout)
    local name  = player:get_player_name()
    local proxy = player:get_meta():get_string(modname..":spawnentity")
    
    -- Flag check: Should this player leave a stand-in?
    -- (e.g., if they have a specific metadata attribute set)
    if proxy and proxy ~= "" then -- NOTE testing
        local pos = player:get_pos()
        core.after(0, function() -- Defer to ensure player object is fully saved/unloaded
            local mob = ia_fake_player.spawn_stand_in(name, pos)
            if mob then
                -- Transfer the just-logged-out player's state to the new mob
                transfer_identity_state(player, mob)
            end
        end)
    end
end)

function ia_fake_player.spawn_mob_entity(name, pos)
    local player = ia_fake_player.engine_get_player_by_name(name)
    -- Fallback to player_exists if they are already offline
    if not (player or core.player_exists(name)) then return nil end

    -- Retrieve the entity name to spawn from player metadata
    -- If no specific proxy is set, we can't spawn a stand-in.
    local meta = player and player:get_meta()
    local entity_name = meta and meta:get_string(modname .. ":spawnentity")

    if not entity_name or entity_name == "" then
        core.log("info", "No spawnentity meta set for " .. name .. ", skipping stand-in.")
        return nil
    end

    -- Prepare identity data to be picked up by ia_fake_player.init_actor
    -- We spoof the staticdata so the mob wakes up as the player.
    local gender = meta:get_string("ia_gender:gender")
    local staticdata = core.serialize({
	    -- in registration.lua:
            --gender      = self.gender,
            --mob_name    = self.mob_name,
            --state       = state,
	    --persistent  = self.persistent,
	    --personality = self.personality, -- important! contains executable code!
        mob_name = name,
        gender = gender ~= "" and gender or nil,
        --persistent = true, -- don't always forceload blocks
    })

    core.log("action", "Spawning stand-in [" .. entity_name .. "] for player: " .. name)
    return core.add_entity(pos, entity_name, staticdata)
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
--core.register_on_prejoinplayer(function(name)
--    if reserved[name] then
--        return "This ID is reserved for system entities."
--    end
----    if reserved[name] and active_mobs[name] then
----        -- Optional: Trigger the takeover instead of kicking?
----        -- If we allow join, on_joinplayer will handle the 'handle_player_takeover'
----        return nil
----    end
--end)




-- ia_fake_player/core/names.lua

---------------------------
-- 1. Identity & State Transfer
---------------------------

--- Deep copy of inventory and metadata from one ObjectRef to another.
-- Used for seamless "Identity Handoff".
