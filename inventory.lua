---- ia_fake_player/inventory.lua
--
--local log = ia_util.get_logger(minetest.get_current_modname())
--local assert = ia_util.get_assert(minetest.get_current_modname())
--
--ia_fake_player.inventory_mirrors = {}
--
----- Synchronizes a specific list from fakelib to the detached mirror
---- @param fake_inv The fakelib inventory object
---- @param detached_name The name of the detached inventory
---- @param listname The specific list to sync (e.g., "main")
--function ia_fake_player:sync_to_detached(fake_inv, detached_name, listname)
--    local detached = minetest.get_inventory({type="detached", name=detached_name})
--    if not detached then return end
--    
--    local size = fake_inv:get_size(listname)
--    if detached:get_size(listname) ~= size then
--        detached:set_size(listname, size)
--    end
--    
--    for i = 1, size do
--        detached:set_stack(listname, i, fake_inv:get_stack(listname, i))
--    end
--end
--
----- Creates a detached inventory that mirrors the fakelib inventory
---- @param player_name The name used for the detached inventory identifier
---- @param fake_inv The fakelib inventory instance to mirror
---- @return The string name of the created detached inventory
--function ia_fake_player:create_mirror(player_name, fake_inv)
--    assert(player_name, "create_mirror: player_name is required")
--    assert(fake_inv, "create_mirror: fake_inv is required")
--
--    local detached_name = player_name .. "_inventory"
--
--    local detached = minetest.create_detached_inventory(detached_name, {
--        allow_put = function(inv, listname, index, stack, player)
--            return stack:get_count()
--        end,
--        on_put = function(inv, listname, index, stack, player)
--            -- Sync change back to the source of truth
--            fake_inv:set_stack(listname, index, stack)
--        end,
--        on_take = function(inv, listname, index, stack, player)
--            -- Sync change back to the source of truth
--            fake_inv:set_stack(listname, index, ItemStack(""))
--        end,
--        on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
--            -- Sync change back to the source of truth
--            local stack = inv:get_stack(to_list, to_index)
--            fake_inv:set_stack(from_list, from_index, ItemStack(""))
--            fake_inv:set_stack(to_list, to_index, stack)
--        end,
--    }, player_name)
--
--    -- Initialize detached lists based on fakelib lists
--    for listname, _ in pairs(fake_inv:get_lists()) do
--        detached:set_size(listname, fake_inv:get_size(listname))
--        self:sync_to_detached(fake_inv, detached_name, listname)
--    end
--
--    --log("info", "Created inventory mirror: " .. detached_name) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
--    return detached_name
--end
-- ia_fake_player/inventory.lua
-- Handles detached inventory mirrors for formspec compatibility.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

--- Synchronizes a specific list from fakelib to the detached mirror
-- @param fake_inv The fakelib inventory object
-- @param detached_name The name of the detached inventory
-- @param listname The specific list to sync (e.g., "main")
function ia_fake_player:sync_to_detached(fake_inv, detached_name, listname)
    local detached = minetest.get_inventory({type="detached", name=detached_name})
    if not detached then return end
    
    local size = fake_inv:get_size(listname)
    if size == 0 then return end

    if detached:get_size(listname) ~= size then
        detached:set_size(listname, size)
    end
    
    for i = 1, size do
        detached:set_stack(listname, i, fake_inv:get_stack(listname, i))
    end
end

--- Creates a detached inventory that mirrors the fakelib inventory
-- @param player_name The name used for the detached inventory identifier
-- @param fake_inv The fakelib inventory instance to mirror
-- @return The string name of the created detached inventory
function ia_fake_player:create_mirror(player_name, fake_inv)
    assert(player_name, "create_mirror: player_name is required")
    assert(fake_inv, "create_mirror: fake_inv is required")

    -- Use the player_name directly to match formspec: list[detached:<name>;...]
    local detached_name = player_name

    local detached = minetest.create_detached_inventory(detached_name, {
        allow_put = function(inv, listname, index, stack, player)
            return stack:get_count()
        end,
        on_put = function(inv, listname, index, stack, player)
            -- Sync change back to the source of truth (fakelib)
            fake_inv:set_stack(listname, index, stack)
        end,
        on_take = function(inv, listname, index, stack, player)
            fake_inv:set_stack(listname, index, ItemStack(""))
        end,
        on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            local stack = inv:get_stack(to_list, to_index)
            fake_inv:set_stack(from_list, from_index, ItemStack(""))
            fake_inv:set_stack(to_list, to_index, stack)
        end,
    }, player_name)

    -- Initialize detached lists based on fakelib lists
    -- We ignore "armor" here if it's already handled by 3d_armor mirrors
    for listname, _ in pairs(fake_inv:get_lists()) do
        if listname ~= "armor" then
            detached:set_size(listname, fake_inv:get_size(listname))
            self:sync_to_detached(fake_inv, detached_name, listname)
        end
    end

    return detached_name
end
