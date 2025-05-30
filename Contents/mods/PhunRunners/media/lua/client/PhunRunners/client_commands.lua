if isServer() then
    return
end

local Core = PhunRunners

local Commands = {}

Commands[Core.commands.stateChange] = function(arguments)
    Core.data = arguments
    ModData.add(Core.name, arguments)
    Core:updatePlayers()
end

return Commands
