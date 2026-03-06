---- ia_fake_player/persistence.lua
---- Handles the serialization and restoration of actor state.
--
--local log = ia_util.get_logger(minetest.get_current_modname())
--local assert = ia_util.get_assert(minetest.get_current_modname())
--
-----------------------------
---- 1. Internal Helpers
-----------------------------
--
----- Serializes inventory lists including layout metadata.
--local function serialize_inventory(inv)
--    assert(inv, "serialize_inventory: inv is nil")
--
--    local inv_data = {}
--    local lists = inv:get_lists()
--
--    for listname, _ in pairs(lists) do
--        inv_data[listname] = {
--            size = inv:get_size(listname),
--            width = inv:get_width(listname),
--            items = {}
--        }
--
--        -- Store each stack as a string
--        for i = 1, inv_data[listname].size do
--            local stack = inv:get_stack(listname, i)
--            inv_data[listname].items[i] = stack:to_string()
--        end
--    end
--    return inv_data
--end
--
-----------------------------
---- 2. Public API
-----------------------------
--
----- Serializes a fake player's full state into a table.
--function ia_fake_player.get_state(fake_player)
--    assert(fake_player ~= nil, "get_state: Cannot get state of nil player")
--    -- Use the bridged method if available
--    assert(fake_player.get_player_name ~= nil, "get_state: Object is not a valid player proxy")
--
--    local name = fake_player:get_player_name()
--
--    local state = {
--        name        = name,
--        pos         = fake_player:get_pos(),
--        pitch       = fake_player:get_look_vertical(),
--        yaw         = fake_player:get_look_horizontal(),
--        inventory   = serialize_inventory(fake_player:get_inventory()),
--        wield_index = fake_player:get_wield_index(),
--        wield_list  = fake_player:get_wield_list(),
--        meta        = fake_player:get_meta():to_table(),
--        controls    = fake_player:get_player_control(),
--        -- Capture current properties (textures, mesh, etc.)
--        properties  = fake_player:get_properties()
--    }
--
--    -- Validation: Ensure the table is serializable
--    local test_ser = minetest.serialize(state)
--    assert(test_ser, "get_state: FAILED to serialize state for " .. name)
--
--    return state
--end
--
----- Restores state into a fake player object.
--function ia_fake_player.apply_state(fake_player, state_data)
--    assert(fake_player, "apply_state: fake_player is nil")
--    assert(state_data, "apply_state: state_data is nil")
--
--    -- 1. Restore Metadata
--    -- The bridge handles lazy-init, so fake_player:get_meta() is safe.
--    if state_data.meta then
--        local meta = fake_player:get_meta()
--        assert(meta ~= nil, "apply_state: get_meta() returned nil")
--        meta:from_table(state_data.meta)
--    end
--
--    -- 2. Restore Inventory
--    local inv = fake_player:get_inventory()
--    if state_data.inventory and inv then
--        for listname, data in pairs(state_data.inventory) do
--            local size = data.size or (data.items and #data.items) or 0
--            inv:set_size(listname, size)
--            if data.width then inv:set_width(listname, data.width) end
--
--            if data.items then
--                for i, stack_str in ipairs(data.items) do
--                    inv:set_stack(listname, i, ItemStack(stack_str))
--                end
--            end
--        end
--    end
--
--    -- 3. Restore Physical State
--    if state_data.pos   then fake_player:set_pos(state_data.pos) end
--    if state_data.pitch then fake_player:set_look_vertical(state_data.pitch) end
--    if state_data.yaw   then fake_player:set_look_horizontal(state_data.yaw) end
--
--    -- 4. Restore Internal State (Wielding)
--    -- Direct access to .data via the bridge
--    local data = fake_player.data
--    if data then
--        if state_data.wield_index then data.wield_index = state_data.wield_index end
--        if state_data.wield_list  then data.wield_list  = state_data.wield_list  end
--    end
--
--    -- 5. Restore Visual Properties (Fallback to engine ObjectRef)
--    if state_data.properties and next(state_data.properties) then
--        fake_player:set_properties(state_data.properties)
--    end
--end
-- ia_fake_player/persistence.lua
-- Handles the serialization and restoration of actor state.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

---------------------------
-- 1. Internal Helpers
---------------------------

--- Serializes inventory lists including layout metadata.
local function serialize_inventory(inv)
    assert(inv, "serialize_inventory: inv is nil")

    local inv_data = {}
    local lists = inv:get_lists()

    for listname, _ in pairs(lists) do
        inv_data[listname] = {
            size = inv:get_size(listname),
            width = inv:get_width(listname),
            items = {}
        }

        -- Store each stack as a string
        for i = 1, inv_data[listname].size do
            local stack = inv:get_stack(listname, i)
            inv_data[listname].items[i] = stack:to_string()
        end
    end
    return inv_data
end

---------------------------
-- 2. Public API
---------------------------

--- Serializes a fake player's full state into a table.
function ia_fake_player.get_state(fake_player)
    assert(fake_player ~= nil, "get_state: Cannot get state of nil player")
    
    -- Ensure we are working with the bridged interface to avoid "bad self" errors
    local player = ia_fake_player.get_interface(fake_player)
    assert(player and player.get_player_name, "get_state: Object is not a valid player interface")

    local name = player:get_player_name()

    local state = {
        name        = name,
        pos         = player:get_pos(),
        pitch       = player:get_look_vertical(),
        yaw         = player:get_look_horizontal(),
        inventory   = serialize_inventory(player:get_inventory()),
        wield_index = player:get_wield_index(),
        wield_list  = player:get_wield_list(),
        meta        = player:get_meta():to_table(),
        controls    = player:get_player_control(),
        -- Capture current properties (textures, mesh, etc.)
        properties  = player:get_properties()
    }

    -- Validation: Ensure the table is serializable
    local test_ser = minetest.serialize(state)
    assert(test_ser, "get_state: FAILED to serialize state for " .. name)

    return state
end

--- Restores state into a fake player object.
function ia_fake_player.apply_state(fake_player, state_data)
    assert(fake_player, "apply_state: fake_player is nil")
    assert(state_data, "apply_state: state_data is nil")

    -- Ensure we are working with the bridged interface
    local player = ia_fake_player.get_interface(fake_player)
    assert(player, "apply_state: Object is not a valid player interface")

    -- 1. Restore Metadata
    -- The bridge handles lazy-init, so player:get_meta() is safe.
    if state_data.meta then
        local meta = player:get_meta()
        assert(meta ~= nil, "apply_state: get_meta() returned nil")
        meta:from_table(state_data.meta)
    end

    -- 2. Restore Inventory
    local inv = player:get_inventory()
    if state_data.inventory and inv then
        for listname, data in pairs(state_data.inventory) do
            local size = data.size or (data.items and #data.items) or 0
            inv:set_size(listname, size)
            if data.width then inv:set_width(listname, data.width) end

            if data.items then
                for i, stack_str in ipairs(data.items) do
                    inv:set_stack(listname, i, ItemStack(stack_str))
                end
            end
        end
    end

    -- 3. Restore Physical State
    if state_data.pos   then player:set_pos(state_data.pos) end
    if state_data.pitch then player:set_look_vertical(state_data.pitch) end
    if state_data.yaw   then player:set_look_horizontal(state_data.yaw) end

    -- 4. Restore Internal State (Wielding)
    -- Use .data via the bridge
    local data = player.data
    if data then
        if state_data.wield_index then data.wield_index = state_data.wield_index end
        if state_data.wield_list  then data.wield_list  = state_data.wield_list  end
    end

    -- 5. Restore Visual Properties
    if state_data.properties and next(state_data.properties) then
        player:set_properties(state_data.properties)
    end
end
