function printAllPlayers(text)
    for i, player in pairs(game.players) do
        player.print(text)
    end
end

function debugPrint(text, even_if_not_debug_mode)
    if (settings.startup["teamwork-debug"].value or even_if_not_debug_mode) then
        printAllPlayers(text)
    end
end

function backtechName(tech_name)
    return "backtech-" .. tech_name
end

function string.startswith(s, start)
    return s.sub(s, 1, s.len(start)) == start
end

function isBackfillTech(tech_name)
    return string.startswith(tech_name, "backtech-")
end

local OVERRIDE_SHARED_TECHS = {
    ['stack-inserter'] = true,
    ['speed-module'] = true,
    ['speed-module-2'] = true,
    ['speed-module-3'] = true,
    ['effectivity-module'] = true,
    ['effectivity-module-2'] = true,
    ['effectivity-module-3'] = true,
    ['productivity-module'] = true,
    ['productivity-module-2'] = true,
    ['productivity-module-3'] = true,
}

local OVERRIDE_NONSHARED_TECHS = {
    ['toolbelt'] = true,
    ['steel-axe'] = true,
    ['auto-character-logistic-trash-slots'] = true,
}


function isSharedTech(tech)
	if not tech.name then error("Invalid tech argument: " .. tech) end
	if OVERRIDE_SHARED_TECHS[tech.name] then return true end
	if OVERRIDE_NONSHARED_TECHS[tech.name] then return false end
	if tech.upgrade then return false end
	if isBackfillTech(tech.name) then return false end
	return true
end

function printForce(force, text)
    for i, player in pairs(force.players) do
        player.print(text)
    end
end

function chunk_bounding_box(chunk_position)
    return {
        left_top={x=chunk_position.x * 32, y=chunk_position.y * 32},
        right_bottom={x=chunk_position.x * 32 + 32, y=chunk_position.y * 32 + 32}
    }
end


TICKS_PER_SECOND = 60
TICKS_PER_MINUTE = 60 * TICKS_PER_SECOND
TICKS_PER_HOUR = 60 * TICKS_PER_MINUTE
EXPAND_TIMINGS = {
    normal = {
        INITIAL_EXPAND_PERIOD = 30 * TICKS_PER_MINUTE,
        EXPAND_PERIOD_E_LIFE = 6 * TICKS_PER_HOUR,
        MIN_EXPAND_PERIOD = 2 * TICKS_PER_MINUTE,  -- occurs at 16 hours
    },
    extreme = {
        INITIAL_EXPAND_PERIOD = 20 * TICKS_PER_MINUTE,
        EXPAND_PERIOD_E_LIFE = 4 * TICKS_PER_HOUR,
        MIN_EXPAND_PERIOD = 1 * TICKS_PER_MINUTE,  -- occurs at 13.6 hours
    },
}
DEBUG_EXPAND_TIMINGS = {
    INITIAL_EXPAND_PERIOD = 15 * TICKS_PER_SECOND,
    EXPAND_PERIOD_E_LIFE = 7 * TICKS_PER_HOUR,
    MIN_EXPAND_PERIOD = 2 * TICKS_PER_SECOND,
}
NUM_PLAYERS_FACTORS = {
    ["two-player"] = 1,
    ["four-player"] = 0.5,
}

function ExpandPeriod(time, settings)

    local num_players_factor = NUM_PLAYERS_FACTORS[settings.global["num-teams"].value]
    local difficulty

    local timings
    if settings.startup["teamwork-debug"].value then
        timings = DEBUG_EXPAND_TIMINGS
    else
        local difficulty = settings.global["expand"].value
        if difficulty == "none" then debugPrint("Difficulty was none!", true) end

        timings = EXPAND_TIMINGS[difficulty]
    end

	local exponential = math.exp(- time / timings.EXPAND_PERIOD_E_LIFE)
	local result = math.max(timings.MIN_EXPAND_PERIOD, exponential * timings.INITIAL_EXPAND_PERIOD)

    result = num_players_factor * result
    return result
end


function table.tostring(t)
    if type(t) ~= "table" then return tostring(t) end
    local bits = {}
    for k, v in pairs(t) do
        table.insert(bits, k .. ": " .. table.tostring(v))
    end
    return "{" .. table.concat(bits, ", ") .. "}"
end



function starts_with(str, start)
   return str:sub(1, #start) == start
end

function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function table.random_sample(table)
    return table[math.random(#table)]
end