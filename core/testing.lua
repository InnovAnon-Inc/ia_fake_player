-- ia_fake_player/testing.lua

-- ia_fake_player/testing.lua

--function ia_fake_player.set_persistence(self, enabled)
--    local pos = self.object:get_pos()
--    if not pos then return end
--
--    -- Clean up existing handle first
--    if self._forceload_handle then
--        minetest.forceload_free_block(self._forceload_handle)
--        self._forceload_handle = nil
--    end
--
--    if enabled then
--        -- We use the pos directly; forceload_block returns the pos it locked
--        self._forceload_handle = pos
--        minetest.forceload_block(pos, true) -- 'true' makes it persistent across restarts
--        minetest.log("action", "[ia_fake_player] Forceloading block at " .. minetest.pos_to_string(pos) .. " for " .. (self.mob_name or "unknown"))
--    end
--end

-- Warning: You must manage the forceload handle carefully. If the entity is remove()'d or the server crashes, forceloads can persist in the map_meta.txt and cause permanent lag. Always call forceload_free_block in your ia_fake_player.cleanup_entity or on_death methods.

