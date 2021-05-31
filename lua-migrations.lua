require "teamwork-utils"

local function change_passes(data, version)
    if data.mod_changes["teamwork"].old_version == nil then return true end
    return data.mod_changes["teamwork"].new_version >= version
           and
           data.mod_changes["teamwork"].old_version < version
end

script.on_configuration_changed(function(data)
    if (data.mod_changes and data.mod_changes["teamwork"]) then
        if data.mod_changes["teamwork"].old_version == nil then

        end
        if change_passes(data, "0.0.9") then
            printAllPlayers("Updating Teamwork to version " .. "0.0.9")
            global.divider_half_width = 6
            global.divider_generated_to = {
                min_x = 0,
                max_x = 0,
                min_y = 0,
                max_y = 0,
            }
            local period = ExpandPeriod(game.tick)
            global.next_expand_tick = game.tick + period
            printAllPlayers("First expansion will be in " .. math.floor(period / (60 * 60)) .. " minutes, at minute " .. math.floor(global.next_expand_tick / (60 * 60)))

        end
    end
end)
