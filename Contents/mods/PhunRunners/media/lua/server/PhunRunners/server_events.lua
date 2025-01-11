if isClient() then
    return
end
local Delay = require "PhunRunners/delay"
local Commands = require "PhunRunners/server_commands"
local PR = PhunRunners
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.EveryHours.Add(function()
    -- PR:clean()
end)

Events.OnZombieDead.Add(function(zed)
    PR:unregisterSprinter(PR:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PR:ini()
end)

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnTickEvenPaused.Add(function()
    if emptyServerCalculate and emptyServerTickCount > 100 then
        local players = PR:onlinePlayers(true)
        if players:size() == 0 then
            emptyServerCalculate = false
            print(PR.name .. ": Server is now empty")
            PR:clean()
        end
    elseif emptyServerTickCount > 100 then
        emptyServerTickCount = 0
    else
        emptyServerTickCount = emptyServerTickCount + 1
    end
end)

Events.EveryTenMinutes.Add(function()
    emptyServerCalculate = PR:onlinePlayers(true):size() > 0
end)

local function setup()
    Events.OnTick.Remove(setup)
    -- PhunRunners:serverSendUnregisters()
end

Events.OnTick.Add(setup)

Events[PhunZones.events.OnPhunZoneReady].Add(function(playerObj, zone)

    local nextCheck = 0

    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (PR.settings.updateInterval or 2)
            PR:updateEnv()
        end
    end)

end)
