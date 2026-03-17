-- ia_fake_player/default/on_step.lua

function ia_fake_player.on_step_default(self, dtime)
    --core.log('ia_fake_player.on_step_default(dtime='..tostring(dtime)..')')
    -- Initialize the coroutine table if it doesn't exist
    self._behavior_coro = self._behavior_coro or nil

    -- If no coroutine is running, start the default "Idle" behavior
    if not self._behavior_coro or coroutine.status(self._behavior_coro) == "dead" then
        self._behavior_coro = coroutine.create(ia_fake_player.default_behavior_loop)
    end

    -- Resume the behavior
    local success, err = coroutine.resume(self._behavior_coro, self, dtime)
    if not success then
        core.log("error", "Behavior coro failed for " .. (self.mob_name or "??") .. ": " .. tostring(err))
    end
end

function ia_fake_player.default_behavior_loop(self)
    --core.log('ia_fake_player.default_behavior_loop()')
    local briefly =  1
    local a_while = 10
    while true do
	if ia_fake_player.default_behavior_loop_dispatch(self) then
		ia_util.coro_sleep(briefly)
	else
		ia_util.coro_sleep(a_while) -- nothing to do
	end
        coroutine.yield() -- always yield
    end
end

ia_fake_player.default_behavior_loop_dispatch_table = {
	ia_fake_player.default_behavior_loop_ra_llm,
	ia_fake_player.default_behavior_loop_builtin,
	ia_fake_player.default_behavior_loop_missionary,
	ia_fake_player.default_behavior_loop_immediate,
	ia_fake_player.default_behavior_loop_hunger_ng,
}

function ia_fake_player.default_behavior_loop_dispatch(self)
	for _, cb in ipairs(ia_fake_player.default_behavior_loop_dispatch_table) do
		if cb(self) then return true end
	end
	return false
end

--
-- llm stuff (one-shot code execution)
--

function ia_fake_player.default_behavior_loop_ra_llm(self)
    core.log('ia_fake_player.default_behavior_loop_ra_llm()')
    -- TODO write a mod that exposes an ra api
    -- TODO if we have a response from the llm, then we execute it
    -- TODO otherwise, when it's this mob's ra-turn, send prompt to llm
end

--
-- personality
--

function ia_fake_player.default_behavior_loop_builtin(self)
    core.log('ia_fake_player.default_behavior_loop_builtin()')
    local personality = ia_fake_player.get_personality(self)
    local code        = personality.code
    local status      = personality.status
    local cause       = personality.cause
    local err         = personality.error
    if status ~= '' then
	    --ia_fake_player.clear_personality(self)
	    return false
    end
    if (not code or code == "") then return false end
    local res         = ia_fake_player.execute_script(self, code)
    if res.status then return true end
    core.log('cause: '..tostring(res.cause))
    core.log('error: '..tostring(res.error))
    ia_fake_player.set_personality_status(self, 'failed')
    ia_fake_player.set_personality_cause (self, res.cause)
    ia_fake_player.set_personality_error (self, res.error)
    return false
end

--
-- immediate concerns
--

function ia_fake_player.default_behavior_loop_immediate(self)
	if ia_fake_player.default_behavior_loop_immediate_falling(self) then return true end
	if ia_fake_player.default_behavior_loop_immediate_breath (self) then return true end
	if ia_fake_player.default_behavior_loop_immediate_hp     (self) then return true end
	if ia_fake_player.default_behavior_loop_immeidate_lava   (self) then return true end
    	-- 3. ENVIRONMENT (Lava/Fire/Void)
	-- TODO radiant damage mod
    	return false
end

function ia_fake_player.default_behavior_loop_immediate_falling(self)
	if not ia_fake_player.actions.primitive.is_falling(self) then return false end
	local cliff = ia_fake_player.actions.atomic.find_and_use_cliff(self)
	return (cliff ~= nil)
end

function ia_fake_player.default_behavior_loop_immediate_breath(self)
    	local air        = self.object:get_breath()
	if (air >= 5) then return false end
	ia_fake_player.actions.primitive.panic_jump(self, "drowning")
        return true
end

function ia_fake_player.default_behavior_loop_immediate_hp(self)
    	local hp         = self.object:get_hp()
    	self._last_hp    = (self._last_hp or hp)
    	if (hp >= self._last_hp) then return false end
        self._last_hp    = hp
	ia_fake_player.actions.primitive.panic_jump(self, "injury")
        return true
end

function ia_fake_player.default_behavior_loop_immediate_lava(self)
    	local pos        = self.object:get_pos()
    	local node_at    = core.get_node(pos).name
    	local node_below = core.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name
	local in_lava    = (core.get_item_group(node_at,    'lava') > 0)
	local above_lava = (core.get_item_group(node_below, 'lava') > 0)
	if in_lava then
		ia_fake_player.actions.primitive.panic_jump(self, "in lava")
		return true
	end
	if above_lava then
		ia_fake_player.actions.primitive.panic_jump(self, "above lava")
		return true
	end
	return false
end

--
-- hunger_ng
--

function ia_fake_player.default_behavior_loop_hunger_ng(self)
    if not core.get_modpath('hunger_ng') then return false end
    -- TODO temperature
    -- TODO thirst
    -- TODO hunger
    -- TODO poop
    -- TODO pee
    -- TODO sleep
end
