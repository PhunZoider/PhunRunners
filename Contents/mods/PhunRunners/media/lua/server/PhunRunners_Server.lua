if not isServer() then
    return
end
local PhunRunners = PhunRunners

function PhunRunners:setDoRun(value)
    self.doRun = value
end

local Commands = {}

Commands.updateStats = function(playerObj, args)
    local name = playerObj:getUsername()
    local data = PhunRunners.data[name]
    if not data then
        data = {
            hours = 0,
            totalHours = 0
        }
        PhunRunners.data[name] = data
    end
    data.hours = playerObj:getHoursSurvived()
end

Commands[PhunRunners.commands.requestData] = function(playerObj, args)
    local name = playerObj:getUsername()
    local data = PhunRunners.data[name] or {}
    if not data.totalHours then
        data.totalHours = 0
    end
    if not data.hours then
        data.hours = 0
    end
    sendServerCommand(playerObj, PhunRunners.name, PhunRunners.commands.requestData, {
        name = name,
        data = data
    })
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunRunners.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.EveryTenMinutes.Add(function()
    for i = 0, getOnlinePlayers():size() - 1 do
        local player = getOnlinePlayers():get(i)
        local name = player:getUsername()
        if not PhunRunners.data[name] then
            PhunRunners.data[name] = {
                hours = 0,
                totalHours = 0
            }
        end
        PhunRunners.data[name].hours = player:getHoursSurvived()
    end
end)

