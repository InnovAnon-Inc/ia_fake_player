-- ia_dunce/tod.lua

--- Returns the raw float time of day (0.0 - 1.0).
function ia_dunce.get_time()
    return minetest.get_timeofday()
end

--- Predicate: Is it currently daytime (sun is up)?
function ia_dunce.is_day()
    local t = minetest.get_timeofday()
    return t > 0.2 and t < 0.8
end

--- Predicate: Is it currently nighttime (monsters out, low light)?
function ia_dunce.is_night()
    return not ia_dunce.is_day()
end

--- Predicate: Is it dawn (sunrise period)?
function ia_dunce.is_dawn()
    local t = minetest.get_timeofday()
    -- Roughly 4:30 AM to 6:00 AM
    return t >= 0.1875 and t <= 0.25
end

--- Predicate: Is it dusk (sunset period)?
function ia_dunce.is_dusk()
    local t = minetest.get_timeofday()
    -- Roughly 6:00 PM to 7:30 PM
    return t >= 0.75 and t <= 0.8125
end

--- Predicate: Is the sun at its peak?
function ia_dunce.is_noon()
    local t = minetest.get_timeofday()
    return t >= 0.45 and t <= 0.55
end

--- Predicate: Is it the middle of the night?
function ia_dunce.is_midnight()
    local t = minetest.get_timeofday()
    return t >= 0.95 or t <= 0.05
end

--- Returns a string representation of the time for debugging or labels.
-- Format: "Morning", "Afternoon", "Evening", "Night"
function ia_dunce.get_time_phase()
    local t = minetest.get_timeofday()
    if t < 0.2 then return "Night" end
    if t < 0.5 then return "Morning" end
    if t < 0.8 then return "Afternoon" end
    return "Evening"
end
