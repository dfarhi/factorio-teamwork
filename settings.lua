data:extend({
    {
        type = "double-setting",
        name = "tech-cost-factor",
        setting_type = "startup",
        default_value = 3.0,
        order = "mode-1",
    },
    {
        type = "string-setting",
        name = "num-teams",
        setting_type = "runtime-global",
        default_value = "four-player",
        allowed_values = {"two-player", "four-player"},
        order = "mode-2",
    },
    {
        type = "string-setting",
        name = "expand",
        setting_type = "runtime-global",
        default_value = "normal",
        allowed_values = {"none", "normal", "extreme"},
        order = "mode-3"
    },
    {
        type = "bool-setting",
        name = "teamwork-debug",
        setting_type = "startup",
        default_value = true,
        order = "Z-meta"
    },
})
