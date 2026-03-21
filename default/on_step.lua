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

local function use_from_inv(self, stat_name, min_value)
    local inv = self:get_inventory()
    local main_list = inv:get_list("main")
    if not main_list then return false end

    for _, stack in ipairs(main_list) do
        local name = stack:get_name()
        local def = core.registered_items[name]
        local stats = def and def._hunger_ng
        if stats and (stats[stat_name] or 0) >= (min_value or 1) then
            ia_fake_player.actions.primitive.use_item(self, name)
            return true
        end
    end
    return false
end

function ia_fake_player.default_behavior_loop_hunger_ng(self)
    if not ia_util.has_hunger_ng_redo() then return false end
    local playername   = self:get_player_name()
    local info         = hunger_ng.get_hunger_information(playername)
    local max_health   = info.maximum.health
    local max_breath   = info.maximum.breath
    local max_thirst   = info.maximum.thirst
    local max_pee      = info.maximum.pee
    local max_hunger   = info.maximum.hunger
    local max_poop     = info.maximum.poop
    local max_sleep    = info.maximum.sleep
    local max_milk     = info.maximum.milk
    assert(max_health ~= nil)
    assert(max_breath ~= nil)
    assert(max_thirst ~= nil)
    assert(max_pee    ~= nil)
    assert(max_hunger ~= nil)
    assert(max_poop   ~= nil)
    assert(max_sleep  ~= nil)
    assert(max_milk   ~= nil)

    local heal_above   = info.effects.healing   .above
    local thirst_below = info.effects.dehydrate .below
    local pee_above    = info.effects.hydrage   .above
    local pee_below    = info.effects.hydrage   .below
    local starve_below = info.effects.starving  .below
    local poop_above   = info.effects.digesting .above
    local poop_below   = info.effects.digesting .below
    local sleep_below  = info.effects.sleeping  .below
    local milk_above   = info.effects.lactate   .above
    local milk_below   = info.effects.lactate   .below
    assert(heal_above   ~= nil)
    assert(thirst_below ~= nil)
    assert(pee_above    ~= nil)
    assert(pee_below    ~= nil)
    assert(starve_below ~= nil)
    assert(poop_above   ~= nil)
    assert(poop_below   ~= nil)
    assert(sleep_below  ~= nil)
    assert(milk_above   ~= nil)
    assert(milk_below   ~= nil)

    local heal_stat    = info.effects.healing  .status
    local thirst_stat  = info.effects.dehydrate.status
    local pee_stat     = info.effects.hydrate  .status
    local pee_able     = info.effects.hydrate  .able
    local starve_stat  = info.effects.starving .status
    local poop_stat    = info.effects.digesting.status
    local poop_able    = info.effects.digesting.able
    local sleep_stat   = info.effects.sleeping .status
    local milk_stat    = info.effects.lactate  .status
    local milk_able    = info.effects.lactate  .able
    assert(heal_stat   ~= nil)
    assert(thirst_stat ~= nil)
    assert(pee_stat    ~= nil)
    assert(pee_able    ~= nil)
    assert(starve_stat ~= nil)
    assert(poop_stat   ~= nil)
    assert(poop_able   ~= nil)
    assert(sleep_stat  ~= nil)
    assert(milk_stat   ~= nil)
    assert(milk_able   ~= nil)

    -- TODO check whether stats are enabled

    local hp           = self:get_hp()
    local breath       = self:get_breath()
    local hunger       = info.hunger.exact
    local poop         = info.poop  .exact
    local sleep        = info.sleep .exact
    local thirst       = info.thirst.exact
    local pee          = info.pee   .exact
    local milk         = info.milk  .exact
    assert(hp     ~= nil)
    assert(breath ~= nil)
    assert(hunger ~= nil)
    assert(poop   ~= nil)
    assert(sleep  ~= nil)
    assert(thirst ~= nil)
    assert(pee    ~= nil)
    assert(milk   ~= nil)

    -- TODO handle stats in critical ranges
    -- TODO handle stats above production thresholds
    -- TODO handle longer term concerns (i.e., sleep because ... better to "charge the battery" if we're not using it)

    -- TODO check health (heals)
    -- TODO check thirst (quenches)
    -- TODO check hunger (satiates)
    -- TODO check pee
    -- TODO check poop
    -- TODO check milk


    -- TODO search core.registered_items[...]._hunger_ng
--     {
--         heals     = n,
--         satiates  = n,
--         digests   = n|nil,
--         rests     = n,
--         quenches  = n,
--         hydrates  = n|nil,
--         weening   = n|nil,
--         returns   = 'id'
--     }
end
