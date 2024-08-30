if not isClient() then
    return
end

local PhunRunners = PhunRunners

local Commands = {}
Commands[PhunRunners.commands.registerSprinter] = function(arguments)
    PhunRunners:registerSprinter(arguments.id, true)
end

Commands[PhunRunners.commands.unregisterSprinter] = function(arguments)
    PhunRunners:unregisterSprinter(arguments.id, true)
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunRunners.name and Commands[command] then
        Commands[command](arguments)
    end
end)
