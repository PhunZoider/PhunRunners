if isClient() then
    return
end
local Core = PhunRunners

local Commands = {}

Commands[Core.commands.requestState] = function(playerObj, arguments)
    sendServerCommand(playerObj, Core.name, Core.commands.stateChange, Core.data)
end

return Commands
