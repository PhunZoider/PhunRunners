if isClient() then
    return
end
local PR = PhunRunners

local Commands = {}

Commands[PR.commands.registerSprinter] = function(playerObj, arguments)
    PR:registerSprinter(arguments.id)
end

Commands[PR.commands.unregisterSprinter] = function(playerObj, arguments)
    PR:unregisterSprinter(arguments.id)
end

return Commands
