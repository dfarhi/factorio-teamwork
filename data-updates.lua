require "teamwork-utils"

local function copy(thing)
    if type(thing) == 'table' then
        local result = {}
        for key, value in pairs(thing) do
            result[key] = copy(value)
        end
        return result
    else
        return thing
    end
end

-- Add a duplicate of each tech that's more expensive.
local all_techs = {}
for name, tech in pairs(data.raw.technology) do
    if isSharedTech(tech) then
        all_techs[name] = tech
    else
        -- Make non-shared techs cheaper since they have to be researched twice (once by each player).
        if tech.unit.count ~= nil then
            tech.unit.count = tech.unit.count / 2
        elseif tech.unit.count_formula ~= nil then
            tech.unit.count_formula = tech.unit.count_formula .. "*0.5"
        else
            error(table.tostring(tech))
        end

    end
end
for name, tech in pairs(all_techs) do
    local new_tech = copy(tech)
    new_tech.name = backtechName(new_tech.name)
    if new_tech.unit.count then
        new_tech.unit.count = new_tech.unit.count * settings.startup["tech-cost-factor"].value
    end
    new_tech.localised_name = {"technology-name.backtech", {"technology-name." .. name}}
    new_tech.localised_description = {"technology-description." .. name}

    data:extend({new_tech})
end


require('prototypes.divider-technologies')