local green_unit = {
    count = 200,
    ingredients = {
        {
            "automation-science-pack",
            1
        },
        {
            "logistic-science-pack",
            1
        },
    },
    time = 30
}
local blue_unit = {
    count = 200,
    ingredients = {
        {
            "automation-science-pack",
            1
        },
        {
            "logistic-science-pack",
            1
        },
        {
            "chemical-science-pack",
            1
        },
    },
    time = 30
}
local blue_black_unit = {
    count = 200,
    ingredients = {
        {
            "automation-science-pack",
            1
        },
        {
            "logistic-science-pack",
            1
        },
        {
            "chemical-science-pack",
            1
        },
        {
            "military-science-pack",
            1
        },
    },
    time = 30
}

local function add_divider_tech(name, tech_unit, prereq)
    data:extend({
    {
        effects = {},
        icon_size = 128,
        icon = "__teamwork__/graphics/"..name..".png",
        name = name,
        prerequisites = {prereq},
        type = "technology",
        unit = tech_unit
    }
})
end

add_divider_tech("teamwork-divider-belts", green_unit, "logistics-2")
add_divider_tech("teamwork-divider-fluids", green_unit, "fluid-handling")
add_divider_tech("teamwork-divider-inserters", green_unit, "stack-inserter")
add_divider_tech("teamwork-divider-rail-signals", green_unit, "rail-signals")
add_divider_tech("teamwork-divider-chests", blue_unit, "logistic-robotics")
add_divider_tech("teamwork-divider-military", blue_black_unit, "gate")