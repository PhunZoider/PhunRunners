if isClient() then
    return
end
local Delay = require "PhunRunners/delay"
local Commands = require "PhunRunners/server_commands"
local PR = PhunRunners
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.EveryHours.Add(function()
    -- PR:updateDawnDusk()
end)

Events.EveryDays.Add(function()
    print("--> PhunRunners: Updating Dawn/Dusk <--")
    PR:updateMoon()
    PR:updateDawnDusk()
end)

Events.OnZombieDead.Add(function(zed)
    -- PR:unregisterSprinter(PR:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PR:ini()
end)

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    PR:updateDawnDusk()
    PR:updateMoon()
    PR:updateEnv()
end)

Events.EveryTenMinutes.Add(function()
    emptyServerCalculate = PR:onlinePlayers(true):size() > 0
end)

local function setup()
    Events.OnTick.Remove(setup)
end

Events.OnTick.Add(setup)

Events[PhunZones.events.OnPhunZoneReady].Add(function(playerObj, zone)

    local nextCheck = 0

    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (PR.settings.FrequencyOfEnvUpdate or 2)
            PR:updateEnv()
        end
    end)

end)
