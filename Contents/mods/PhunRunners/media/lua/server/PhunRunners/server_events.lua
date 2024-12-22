if isClient() then
    return
end
local Delay = require "PhunRunners/delay"
local Commands = require "PhunRunners/server_commands"
local PR = PhunRunners

Events.EveryHours.Add(function()
    -- PR:clean()
end)

Events.OnZombieDead.Add(function(zed)
    PR:unregisterSprinter(PR:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PR:ini()
end)

PhunTools:RunOnceWhenServerEmpties(PR.name, function()
    PR:clean()
end)

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

function PR:serverSendUnregisters()
    local seconds = PR.settings.deferUnregistereSeconds
    if seconds and seconds > 0 then
        Delay:set(seconds, function()
            if #PR.toUnregister > 0 then
                -- PhunTools:printTable(PhunRunners.toUnregister)
                sendServerCommand(self.name, self.commands.unregisterSprinter, {
                    ids = PR.toUnregister
                })
            end
            PR:serverSendUnregisters()
        end, "transmitUnregisters")
    end
end

local function setup()
    Events.OnTick.Remove(setup)
    -- PhunRunners:serverSendUnregisters()
end

Events.OnTick.Add(setup)
