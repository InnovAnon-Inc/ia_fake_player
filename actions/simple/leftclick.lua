-- ia_fake_player/actions/simple/leftclick.lua

--- Internal helper to find the best tool for a job.
local function get_best_tool_for_node(self, node_name) -- TODO expose
    local def = minetest.registered_nodes[node_name]
    if not def or not def.groups then return nil end

    local inv = self:get_inventory()
    local main_list = inv:get_list("main")
    local best_tool_index = nil
    local best_time = 999

    -- Check current wielded item first
    local wielded = self:get_wielded_item()
    local w_caps = wielded:get_tool_capabilities()
    if w_caps then
        local w_stats = minetest.get_dig_params(def.groups, w_caps)
        if w_stats.diggable then best_time = w_stats.time end
    end

    -- Scan inventory for a better match
    for i, stack in ipairs(main_list) do
        local caps = stack:get_tool_capabilities()
        if caps then
            local stats = minetest.get_dig_params(def.groups, caps)
            if stats.diggable and stats.time < best_time then
                best_time = stats.time
                best_tool_index = i
            end
        end
    end

    return best_tool_index, best_time
end

--- Determines if the Dunce can potentially clear a path through this node.
-- @return boolean, number (can_dig, dig_time_estimate)
function ia_fake_player.actions.simple.can_dig_node(self, node_name)
    local def = minetest.registered_nodes[node_name]
    if not def or not def.diggable then return false, 0 end

    -- Check best tool in inventory to get an accurate time estimate
    local _, time = get_best_tool_for_node(self, node_name)

    -- If no tool makes it diggable under 10s, consider it unbreakable
    if time > 10 then return false, time end

    return true, time
end

--- Primary left-click action. Handles digging and hitting.
function ia_fake_player.actions.simple.left_click(self, pos_or_obj, keep_tool)
    minetest.log('ia_fake_player.actions.simple.left_click()')
    local is_object = type(pos_or_obj) == "userdata" and pos_or_obj.get_pos
    local pos = is_object and pos_or_obj:get_pos() or pos_or_obj

    if not ia_fake_player.actions.simple.is_within_reach(self, pos) then return false, "too_far" end

    ia_fake_player.actions.simple.stop_and_look_at(self, pos)
    ia_fake_player.actions.simple.set_animation(self, 'MINE')

    local original_wield = self:get_wielded_item()
    if not is_object then
        local node_name = minetest.get_node(pos).name
        local tool_idx = get_best_tool_for_node(self, node_name)

        if tool_idx then
            local inv = self:get_inventory()
            local tool_stack = inv:get_stack("main", tool_idx)
            self:set_wielded_item(tool_stack)
            inv:set_stack("main", tool_idx, original_wield)
        end
    end

    local success = false
    if is_object then
        pos_or_obj:punch(self.fake_player, 1.0, self:get_wielded_item():get_tool_capabilities())
        success = true
    else
        local node = minetest.get_node(pos)
        success = minetest.node_dig(pos, node, self.fake_player)
        if success then ia_fake_player.actions.simple.play_node_sound(node.name, pos, "dug") end
    end

    if not keep_tool and not is_object then
        local current_tool = self:get_wielded_item()
        self:set_wielded_item(original_wield)
        local inv = self:get_inventory()
        for i, stack in ipairs(inv:get_list("main")) do
            if stack:is_empty() then
                inv:set_stack("main", i, current_tool)
                break
            end
        end
    end

    ia_fake_player.actions.simple.set_animation(self, 'STAND')
    return success
end
