---- ia_fake_player/init.lua
-- FIXME weird texture/mesh glitch
-- FIXME mapblocks need to stay loaded
-- TODO ensure that all fake players leave when the server shuts down
---- adapted from `feed_buckets`
--
--assert(minetest.get_modpath('ia_util'))
--assert(ia_util ~= nil)
--local modname                    = minetest.get_current_modname() or "ia_fake_player"
--local storage                    = minetest.get_mod_storage()
--ia_fake_player                   = {}
--
---- Store originals to prevent infinite recursion in overrides
--ia_fake_player.engine_get_connected_players = minetest.get_connected_players
--ia_fake_player.engine_get_player_by_name = minetest.get_player_by_name
--ia_fake_player.engine_check_player_privs = minetest.check_player_privs
--ia_fake_player.engine_get_player_information = minetest.get_player_information
--
--local modpath, S                 = ia_util.loadmod(modname)
--local log                        = ia_util.get_logger(modname)
--local assert                     = ia_util.get_assert(modname)
--
-------------------------------------------------------------
---- 1. Engine API Monkeypatching (Overrides)
-------------------------------------------------------------
--
---- Redirects to logic in names.lua which merges engine and fake players
--minetest.get_connected_players = function()
--    return ia_fake_player.get_all_actors()
--end
--
---- Checks engine first, then checks the naming registry
--minetest.get_player_by_name = function(name)
--    assert(type(name) == "string", "minetest.get_player_by_name: name must be a string")
--    return ia_fake_player.get_actor_by_name(name)
--end
--
---- Routes to privilege logic in names.lua
--minetest.check_player_privs = function(name, privs)
--    return ia_fake_player.check_actor_privs(name, privs)
--end
--core.check_player_privs = minetest.check_player_privs
--
----- Overwrite the engine function to support fake players
--minetest.get_player_information = function(name)
--    return ia_fake_player.get_actor_information(name)
--end
--
-------------------------------------------------------------
---- 2. Event Emulation (The "Online" Illusion)
-------------------------------------------------------------
--
----- Triggers virtual join events for a fake player
---- This ensures mods like hunger_ng initialize metadata for the actor.
--function ia_fake_player.trigger_join(actor)
--    -- Resolve the bridged interface to avoid "bad self" when calling engine methods
--    local player = ia_fake_player.get_interface(actor)
--    assert(player and player.get_player_name, "trigger_join: Invalid actor or interface")
--    
--    local name = player:get_player_name()
--
--    -- Ensure the actor is retrievable by name BEFORE triggering callbacks
--    -- so that on_joinplayer functions can find the "player" object.
--    -- (This is handled by the naming registry in names.lua)
--
--    for _, callback in ipairs(minetest.registered_on_joinplayers) do
--        callback(player)
--    end
--end
--
----- Triggers virtual leave events and performs cleanup
--function ia_fake_player.trigger_leave(actor, timeout)
--    local player = ia_fake_player.get_interface(actor)
--    assert(player and player.get_player_name, "trigger_leave: Invalid actor or interface")
--    
--    local name = player:get_player_name()
--
--    for _, callback in ipairs(minetest.registered_on_leaveplayers) do
--        callback(player, timeout or false)
--    end
--
--    -- Cleanup the naming registry and mirrors
--    ia_fake_player.release_name(name)
--    ia_fake_player.cleanup_entity(player)
--end
--
----- Emulates a player being punched (triggers registered_on_punchplayers)
--function ia_fake_player.trigger_punch(actor, hitter, time_from_last_punch, tool_capabilities, dir, damage)
--    local player = ia_fake_player.get_interface(actor)
--    assert(player and player.get_player_name, "trigger_punch: Invalid actor or interface")
--
--    for _, callback in ipairs(minetest.registered_on_punchplayers) do
--        local result = callback(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
--        if result == true then return true end
--    end
--    return false
--end
--
----- Emulates a player right-clicking (triggers registered_on_rightclickplayers)
--function ia_fake_player.trigger_rightclick(actor, clicker)
--    local player = ia_fake_player.get_interface(actor)
--    assert(player and player.get_player_name, "trigger_rightclick: Invalid actor or interface")
--
--    for _, callback in ipairs(minetest.registered_on_rightclickplayers) do
--        callback(player, clicker)
--    end
--end
--
-------------------------------------------------------------
---- 3. Global Lifecycle Mirroring
-------------------------------------------------------------
--
---- Global step hook for mods that track player-specific periodic logic
--minetest.register_globalstep(function(dtime)
--    local mobs = ia_fake_player.get_connected_mobs()
--    if #mobs == 0 then return end
--    
--    for _, mob in ipairs(mobs) do
--        -- Ensure we have the bridged interface for the global step
--        local player = ia_fake_player.get_interface(mob)
--        if player then
--            -- Logic: Ensure inventory mirrors stay semi-synced
--            local inv = player:get_inventory()
--            local detached_name = player.data and player.data.detached_name
--            if inv and detached_name then
--                 -- Optimization: only sync "main" on global step
--                 ia_fake_player:sync_to_detached(inv, detached_name, "main")
--            end
--        end
--    end
--end)
-- ia_fake_player/init.lua
-- adapted from `feed_buckets`

assert(minetest.get_modpath('ia_util'))
assert(ia_util ~= nil)
local modname                    = minetest.get_current_modname() or "ia_fake_player"
local storage                    = minetest.get_mod_storage()
ia_fake_player                   = {}

-- Store originals to prevent infinite recursion in overrides
ia_fake_player.engine_get_connected_players = minetest.get_connected_players
ia_fake_player.engine_get_player_by_name = minetest.get_player_by_name
ia_fake_player.engine_check_player_privs = minetest.check_player_privs
ia_fake_player.engine_get_player_information = minetest.get_player_information

local modpath, S                 = ia_util.loadmod(modname)
local log                        = ia_util.get_logger(modname)
local assert                     = ia_util.get_assert(modname)

-----------------------------------------------------------
-- 1. Engine API Monkeypatching (Overrides)
-----------------------------------------------------------

-- Redirects to logic in names.lua which merges engine and fake players
minetest.get_connected_players = function()
    return ia_fake_player.get_all_actors()
end

-- Checks engine first, then checks the naming registry
minetest.get_player_by_name = function(name)
    assert(type(name) == "string", "minetest.get_player_by_name: name must be a string")
    return ia_fake_player.get_actor_by_name(name)
end

-- Routes to privilege logic in names.lua
minetest.check_player_privs = function(name, privs)
    return ia_fake_player.check_actor_privs(name, privs)
end
core.check_player_privs = minetest.check_player_privs

--- Overwrite the engine function to support fake players
minetest.get_player_information = function(name)
    return ia_fake_player.get_actor_information(name)
end

-----------------------------------------------------------
-- 2. Event Emulation (The "Online" Illusion)
-----------------------------------------------------------

--- Triggers virtual join events for a fake player
-- This ensures mods like hunger_ng initialize metadata for the actor.
function ia_fake_player.trigger_join(actor)
    -- Resolve the bridged interface to avoid "bad self" when calling engine methods
    local player = ia_fake_player.get_interface(actor)
    assert(player and player.get_player_name, "trigger_join: Invalid actor or interface")
    
    local name = player:get_player_name()

    -- Ensure the actor is retrievable by name BEFORE triggering callbacks
    -- so that on_joinplayer functions can find the "player" object.
    -- (This is handled by the naming registry in names.lua)

    for _, callback in ipairs(minetest.registered_on_joinplayers) do
        callback(player)
    end
end

--- Triggers virtual leave events and performs cleanup
function ia_fake_player.trigger_leave(actor, timeout)
    local player = ia_fake_player.get_interface(actor)
    assert(player and player.get_player_name, "trigger_leave: Invalid actor or interface")
    
    local name = player:get_player_name()

    for _, callback in ipairs(minetest.registered_on_leaveplayers) do
        callback(player, timeout or false)
    end

    -- Cleanup the naming registry and mirrors
    ia_fake_player.release_name(name)
    ia_fake_player.cleanup_entity(player)
end

--- Emulates a player being punched (triggers registered_on_punchplayers)
function ia_fake_player.trigger_punch(actor, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local player = ia_fake_player.get_interface(actor)
    assert(player and player.get_player_name, "trigger_punch: Invalid actor or interface")

    for _, callback in ipairs(minetest.registered_on_punchplayers) do
        local result = callback(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
        if result == true then return true end
    end
    return false
end

--- Emulates a player right-clicking (triggers registered_on_rightclickplayers)
function ia_fake_player.trigger_rightclick(actor, clicker)
    local player = ia_fake_player.get_interface(actor)
    assert(player and player.get_player_name, "trigger_rightclick: Invalid actor or interface")

    for _, callback in ipairs(minetest.registered_on_rightclickplayers) do
        callback(player, clicker)
    end
end

-----------------------------------------------------------
-- 3. Global Lifecycle Mirroring
-----------------------------------------------------------

-- Global step hook for mods that track player-specific periodic logic
minetest.register_globalstep(function(dtime)
    local mobs = ia_fake_player.get_connected_mobs()
    if #mobs == 0 then return end
    
    for _, mob in ipairs(mobs) do
        -- Ensure we have the bridged interface for the global step
        local player = ia_fake_player.get_interface(mob)
        if player then
            -- Logic: Ensure inventory mirrors stay semi-synced
	    -- FIXME semi-synced? I'm gonna tell people that google gemini said that this handles all possible edge cases
            local inv = player:get_inventory()
            local detached_name = player.data and player.data.detached_name
            if inv and detached_name then
                 -- Optimization: only sync "main" on global step
                 ia_fake_player:sync_to_detached(inv, detached_name, "main")
            end
        end
    end
end)
