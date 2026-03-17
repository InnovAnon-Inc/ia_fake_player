-- ia_fake_player/core/personality.lua

--
--
--

function ia_fake_player.new_personality(self)
    return {
	    code   = nil,
	    status = nil,
	    cause  = nil,
	    error  = nil,
    }
end

function ia_fake_player.get_personality(self)
    return (self.personality or ia_fake_player.new_personality(self))
end

function ia_fake_player.set_personality(self, personality)
    self.personality = code
end

function ia_fake_player.clear_personality(self)
    self.personality = ia_fake_player.new_personality(self)
end

--
--
--

function ia_fake_player.get_personality_code(self)
    local personality = ia_fake_player.get_personality(self)
    return personality.code
end

function ia_fake_player.set_personality_code(self, code)
    local personality = ia_fake_player.get_personality(self)
    personality.code = code
end

function ia_fake_player.clear_personality_code(self)
    ia_fake_player.set_personality_code(self, nil)
end

function ia_fake_player.new_personality_code(self, code)
    ia_fake_player.clear_personality_status (self)
    ia_fake_player.clear_personality_cause  (self)
    ia_fake_player.clear_personality_error  (self)
    ia_fake_player.set_personality_code     (self, code)
end

--
--
--

function ia_fake_player.get_personality_status(self)
    local personality = ia_fake_player.get_personality(self)
    return personality.status
end

function ia_fake_player.set_personality_status(self, status)
    local personality = ia_fake_player.get_personality(self)
    personality.status = status
end

function ia_fake_player.clear_personality_status(self)
    ia_fake_player.set_personality_status(self, nil)
end

--
--
--

function ia_fake_player.get_personality_cause(self)
    local personality = ia_fake_player.get_personality(self)
    return personality.cause
end

function ia_fake_player.set_personality_cause(self, cause)
    local personality = ia_fake_player.get_personality(self)
    personality.cause = cause
end

function ia_fake_player.clear_personality_cause(self)
    ia_fake_player.set_personality_cause(self, nil)
end

--
--
--

function ia_fake_player.get_personality_error(self)
    local personality = ia_fake_player.get_personality(self)
    return personality.error
end

function ia_fake_player.set_personality_error(self, err)
    local personality = ia_fake_player.get_personality(self)
    personality.error = err
end

function ia_fake_player.clear_personality_error(self)
    ia_fake_player.set_personality_error(self, nil)
end
