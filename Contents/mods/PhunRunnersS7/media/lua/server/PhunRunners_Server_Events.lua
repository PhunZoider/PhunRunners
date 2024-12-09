if not isServer() then
    return
end
local Delay = require "PhunRunners_Delay"
local PhunRunners = PhunRunners

Events.EveryHours.Add(function()
    PhunRunners:clean()
end)

Events.OnZombieDead.Add(function(zed)
    PhunRunners:unregisterSprinter(PhunRunners:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PhunRunners:init()
end)

if PhunTools then
    PhunTools:RunOnceWhenServerEmpties(PhunRunners.name, function()
        PhunRunners:clean()
    end)
else

    local emptyServerTickCount = 0
    local emptyServerCalculate = false

    Events.EveryTenMinutes.Add(function()
        if getOnlinePlayers():size() > 0 then
            emptyServerCalculate = true
        end
    end)

    Events.OnTickEvenPaused.Add(function()
        if emptyServerCalculate and emptyServerTickCount > 100 then
            if getOnlinePlayers():size() == 0 then
                PhunRunners:clean()
            end
        elseif emptyServerTickCount > 100 then
            emptyServerTickCount = 0
        else
            emptyServerTickCount = emptyServerTickCount + 1
        end
    end)
end

function PhunRunners:serverSendUnregisters()
    local seconds = PhunRunners.settings.deferUnregistereSeconds
    if seconds and seconds > 0 then
        Delay:set(seconds, function()
            if #PhunRunners.toUnregister > 0 then
                -- PhunTools:printTable(PhunRunners.toUnregister)
                sendServerCommand(self.name, self.commands.unregisterSprinter, {
                    ids = PhunRunners.toUnregister
                })
            end
            PhunRunners:serverSendUnregisters()
        end, "transmitUnregisters")
    end
end

local function setup()
    Events.OnTick.Remove(setup)
    -- PhunRunners:serverSendUnregisters()
end

Events.OnTick.Add(setup)
