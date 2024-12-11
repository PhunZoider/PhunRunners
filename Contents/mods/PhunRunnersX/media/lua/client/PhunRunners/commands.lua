if not isClient() then
    return
end

local PR = PhunRunners

local Commands = {}
Commands[PR.commands.registerSprinter] = function(arguments)
    PR:registerSprinter(arguments.id, true)
end

Commands[PR.commands.unregisterSprinter] = function(arguments)
    if arguments.id then
        PR:unregisterSprinter(arguments.id, true)
    elseif arguments.ids then
        for _, id in ipairs(arguments.ids) do
            PR:unregisterSprinter(id, true)
        end
    end
end

return Commands
