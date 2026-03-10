-- ia_fake_player/namegen.lua
-- Procedural name generation for fake players.

local log = ia_util.get_logger(minetest.get_current_modname())
local assert = ia_util.get_assert(minetest.get_current_modname())

---------------------------
-- 1. Configuration
---------------------------

local function init_name_generator()
    local namegen_path = minetest.get_modpath("name_generator")
    if not namegen_path then
        --log("warning", "name_generator mod not found. Using fallback naming.") -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
        return
    end

    local cfg_path = namegen_path .. "/data/creatures.cfg"
    local file = io.open(cfg_path, "r")
    if file then
        -- Only parse if the library is available
        if name_generator and name_generator.parse_lines then
            name_generator.parse_lines(file:lines())
            file:close()
        else
            --log("error", "name_generator global table not found!") -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
        end
    else
        --log("error", "Could not open name_generator data: " .. cfg_path) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
    end
end

-- Run initialization on load
init_name_generator()

---------------------------
-- 2. Generation Logic
---------------------------

--- Generates a unique, gendered human name
-- @param gender "male" or "female"
-- @return string unique_name
function ia_fake_player.generate_random_name(gender)
    assert(gender ~= nil, "generate_random_name: gender is required")
    
    local first, last
    local success = pcall(function()
        -- Attempt to use the name_generator mod logic
        if name_generator and name_generator.generate then
            first = name_generator.generate("human " .. gender)
            last = name_generator.generate("human surname")
        end
    end)

    -- Fallback if name_generator fails or is missing
    if not success or not first or not last then
        first = (gender == "female") and "Jane" or "John"
        last = "Doe_" .. math.random(1000, 9999)
        --log("warning", "Name generation failed, using fallback: " .. first .. " " .. last) -- 2026-03-05 17:27:36: ERROR[Main]: /home/frederick/.minetest/mods/ia_util/init.lua:22: /home/frederick/.minetest/mods/ia_util/logging.lua:40: attempt to compare number with string
    end

    local base_name = first .. " " .. last
    local final_name = base_name
    local suffix = 1

    -- Ensure uniqueness using the registry in names.lua
    -- We use ia_fake_player.is_name_available which we just fixed
    while not ia_fake_player.is_name_available(final_name) do
        final_name = base_name .. " " .. suffix
        suffix = suffix + 1
    end

    -- Reserve it immediately to prevent race conditions during activation
    local reserved = ia_fake_player.reserve_name(final_name)
    assert(reserved, "Failed to reserve generated name: " .. final_name)

    return final_name
end

--- Simple helper for gender generation if ia_gender isn't present
-- @return string "male" or "female"
function ia_fake_player.generate_gender()
    if ia_gender and ia_gender.generate_human_gender then
        return ia_gender.generate_human_gender()
    end
    return (math.random() > 0.5) and "male" or "female"
end
