-- ia_fake_player/default/missionary.lua

function ia_fake_player.default_behavior_loop_missionary(self)
	core.log('ia_fake_player.default_behavior_loop_missionary()')
	if not core.get_modpath('ia_missionary') then return false end
	local bible = ia_fake_player.get_bible_stack(self)
	return ((bible and ia_fake_player.read_or_discard_bible(self, bible)) or ia_fake_player.actions.atomic.find_bible(self))
end

function ia_fake_player.get_bible_stack(self) -- TODO namespacing
    assert(core.get_modpath('ia_missionary') ~= nil)
    local inv = self:get_inventory()
    if not inv or inv:get_size("bible") == 0 then return nil end
    local stack = inv:get_stack("bible", 1)
    return (not stack:is_empty()) and stack or nil
end

function ia_fake_player.actions.atomic.find_bible(self) -- TODO move to correct file
    core.log("action", self.mob_name .. " is looking for a book...")

    -- Use the sensor to find reachable items
    local target = ia_fake_player.actions.primitive.find_reachable_item(self, 10, function(stack)
        -- Fix: Don't go after blank books
	assert(ia_fake_player.actions.atomic.is_book_item)
        local is_book  = ia_fake_player.actions.atomic.is_book_item(stack:get_name())
	--core.log('is_book: '..tostring(is_book))
	if not is_book then return false end
	local meta     = stack:get_meta()
        local status   =             meta:get_string ('ia_fake_player:read_bible.status', '')  -- TODO
        local cause    =             meta:get_string ('ia_fake_player:read_bible.cause',  '')
        local err      =             meta:get_string ('ia_fake_player:read_bible.error',  '')
	--core.log('status : '..tostring(status))
	--core.log('cause  : '..tostring(cause))
	--core.log('error  : '..tostring(err))
	--if not status then return false end
	if status ~= '' then return false end -- TODO
	return (meta:get_string("text") ~= "")
    end)

    if target then
        ia_fake_player.actions.primitive.face_pos(self, target.pos) -- TODO expand bible-/trinket- inventory api to mirror others (e.g., armor)
        if ia_fake_player.actions.primitive.pickup_item(self, target.object) then
            -- Internal Inventory Transfer
            local inv = self:get_inventory()
            local main_list = inv:get_list("main")
            for i, stack in ipairs(main_list) do
                if ia_fake_player.actions.atomic.is_book_item(stack:get_name()) then
                    inv:set_stack("bible", 1, stack)
                    inv:set_stack("main", i, ItemStack(""))
                    return true
                end
            end
        end
    end
    return false
end

function ia_fake_player.read_or_discard_bible(self, bible) -- TODO namespacing
    --core.log('ia_fake_player.read_or_discard_bible(bible='..tostring(bible)..')')
    local meta   = bible:get_meta()
    local status =             meta:get_string ('ia_fake_player:read_bible.status', '')  -- TODO
    local cause  =             meta:get_string ('ia_fake_player:read_bible.cause',  '')
    local err    =             meta:get_string ('ia_fake_player:read_bible.error',  '')
    --if not status then
    if status ~= '' then -- TODO
	    return ia_fake_player.discard_bible(self, bible)
    end
    local res    = ia_fake_player.read_bible(self, bible)
    assert(res        ~= nil)
    assert(res.status ~= nil)
    assert(res.cause  ~= nil)
    if res.status then return true end
    --meta:set_string ('ia_fake_player:read_bible.status', tostring(res.status))
    --meta:set_string ('ia_fake_player:read_bible.status',        ((res.status and 'yes') or 'no')) -- TODO
    meta:set_string ('ia_fake_player:read_bible.status',        'failed')
    meta:set_string ('ia_fake_player:read_bible.cause',           res.cause)
    meta:set_string ('ia_fake_player:read_bible.error',  tostring(res.error or ''))
    meta:set_string("description", "A Discarded Book")
    return ia_fake_player.discard_bible(self, bible)
end

function ia_fake_player.read_bible(self, bible) -- TODO namespacing
    --core.log('ia_fake_player.read_bible(bible='..tostring(bible)..')')
    local meta   = bible:get_meta()
    local code   = meta:get_string("text")
    if (not code or code == "") then
	    return {
		    status=false,
		    cause ='empty book',
		    error =nil,
	    }
    end
    core.log("action", self.mob_name .. " is reading the book.")
    return ia_fake_player.execute_script(self, code)
end

function ia_fake_player.discard_bible(self, bible)
    --core.log('ia_fake_player.discard_bible(bible='..tostring(bible)..')')
    local pos  = self:get_pos()
    local item = bible:peek_item()
    --local obj = core.add_item({x=pos.x, y=pos.y+1.5, z=pos.z}, bible)
    local obj = core.add_item({x=pos.x, y=pos.y+1.5, z=pos.z}, item)
    if not obj then
	    return false
    end
    local chk  = bible:take_item()
    assert(item == chk)
    local v    = 3
    obj:set_velocity({x=math.random(-v,v), y=v, z=math.random(-v,v)})
    --self:get_inventory():set_stack("bible", 1, ItemStack("")) -- TODO testing
    self:get_inventory():set_stack("bible", 1, bible)
    return true
end

--function ia_fake_player.execute_script(self, code) -- TODO namespacing
--    core.log('ia_fake_player.execute_script()')
--    -- Create an environment for the book code
--    local env = {
--        self = self,           -- The mob object (with its bridge/proxy)
--        minetest = minetest,   -- Access to world
--        vector = vector,       -- Math helpers
--        ia_fake_player = ia_fake_player, -- Access to its own species API
--        print = function(txt) log("action", "["..self.mob_name.."] Reading: "..tostring(txt)) end
--    }
--    -- Inherit global read-only table
--    setmetatable(env, { __index = _G })
--
--    local func, err = load(code, "=(Script)", "t", env)
--    if not func then
--        log("error", "Script Load Error: " .. tostring(err))
--        return false
--    end
--
--    local success, run_err = pcall(func)
--    if not success then
--        log("error", "Script Runtime Error: " .. tostring(run_err))
--	return nil -- main-loop will fall through to next handler
--    end
--
--    return true
--end
function ia_fake_player.execute_script(self, code) -- TODO namespacing
    --core.log('ia_fake_player.execute_script()')
    -- Create an environment for the book code
    local env = {
        self        = self,
        --minetest = minetest,
        --core = minetest,
	core        = core,
	minetest    = minetest,
        vector      = vector,
        -- Expose the full action suite
        fake_player = ia_fake_player,
        actions     = ia_fake_player.actions,
	atomic      = ia_fake_player.actions.atomic,
	primitive   = ia_fake_player.actions.primitive,
        print       = function(...)  -- TODO would be better to capture this ?
            local args = {...}
            for i, v in ipairs(args) do args[i] = tostring(v) end
            core.log("action", "["..self.mob_name.."] " .. table.concat(args, " ")) 
        end
    }
    
    -- Inherit global read-only table for standard Lua functions (pairs, ipairs, etc.)
    setmetatable(env, { __index = _G })

    -- Use loadstring for Lua 5.1/JIT compatibility
    local func, err = loadstring(code, "=(Script)")
    
    if not func then
        core.log("error", "Script Load Error: " .. tostring(err))
        return {
		status=false,
		cause ='loadstring',
		error =err,
	}
    end

    -- Apply the sandbox environment to the function
    setfenv(func, env)

    local success, run_err = pcall(func)
    if not success then
        core.log("error", "Script Runtime Error: " .. tostring(run_err))
	return {
		status=false,
		cause ='pcall',
		error =run_err,
	}
    end
    return {
	    status=true,
	    cause ='',
	    --cause ='pcall',
	    error =nil,
	    --output=...  -- TODO
    }
end

