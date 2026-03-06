-- ia_fake_player/lifecycle.lua
-- TODO machine-generated code that we didn't ask for: needs audit

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

--- Handles the initialization of a bridged entity's state
-- This should be called from the mob's on_activate or after bridge_mob
function ia_fake_player.init_entity_state(entity, staticdata)
    assert(entity, "init_entity_state: entity is nil")
    
    -- If there's saved state in staticdata, apply it immediately
    if staticdata and staticdata ~= "" then
        local data = minetest.deserialize(staticdata)
        if data and data.fake_player_state then
            ia_fake_player.apply_state(entity, data.fake_player_state)
            --log("info", "Restored persisted state for " .. entity:get_player_name()) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
        end
    end
end

--- Cleans up resources associated with a fake player
-- Prevents detached inventory "leaks" in the engine
function ia_fake_player.cleanup_entity(entity)
    assert(entity, "cleanup_entity: entity is nil")
    
    local data = entity.data
    if data and data.detached_name then
        -- The engine doesn't have a 'delete_detached_inventory', 
        -- but we can clear its contents and size to minimize memory.
        local inv = minetest.get_inventory({type="detached", name=data.detached_name})
        if inv then
            for listname, _ in pairs(inv:get_lists()) do
                inv:set_size(listname, 0)
            end
            --log("info", "Cleaned up detached mirror: " .. data.detached_name) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
        end
    end
end
