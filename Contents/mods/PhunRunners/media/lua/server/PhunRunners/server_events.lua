if isClient() then
    return
end
local Delay = require "PhunRunners/delay"
local Commands = require "PhunRunners/server_commands"
local Core = PhunRunners
local PL = PhunLib
local PZ = PhunZones
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.EveryDays.Add(function()
    Core:updateMoon()
    Core:updateDawnDusk()
end)

Events.OnServerStarted.Add(function()
    Core:ini()
end)

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    Core:ini()
    Core:updateDawnDusk()
    Core:updateMoon()
    Core:updateEnv()
end)

Events.EveryTenMinutes.Add(function()
    emptyServerCalculate = PL.onlinePlayers(true):size() > 0
end)

Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)

    local nextCheck = 0

    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (Core.settings.FrequencyOfEnvUpdate or 2)
            Core:updateEnv()
        end
    end)

end)
