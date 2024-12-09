if not isClient() then
    return
end

local PhunRunners = PhunRunners

local Commands = {}
Commands[PhunRunners.commands.registerSprinter] = function(arguments)
    PhunRunners:registerSprinter(arguments.id, true)
end

Commands[PhunRunners.commands.unregisterSprinter] = function(arguments)
    if arguments.id then
        PhunRunners:unregisterSprinter(arguments.id, true)
    elseif arguments.ids then
        for _, id in ipairs(arguments.ids) do
            PhunRunners:unregisterSprinter(id, true)
        end
    end
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunRunners.name and Commands[command] then
        Commands[command](arguments)
    end
end)
