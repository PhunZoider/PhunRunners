if not isServer() then
    return
end

local PhunRunners = PhunRunners

local Commands = {}

Commands[PhunRunners.commands.registerSprinter] = function(playerObj, arguments)
    PhunRunners:registerSprinter(arguments.id)
end

Commands[PhunRunners.commands.unregisterSprinter] = function(playerObj, arguments)
    PhunRunners:unregisterSprinter(arguments.id)
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunRunners.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
