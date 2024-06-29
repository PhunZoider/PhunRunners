if not isServer() then
    return
end
local PhunRunners = PhunRunners

function PhunRunners:reload()
    self.cycles = PhunTools:loadTable("PhunRunners_Cycles.lua")
    ModData.add(self.name .. "_Cycles", self.cycles)
    self.timeModifiers = PhunTools:loadTable("PhunRunners_Modifiers.lua")
    ModData.add(self.name .. "_Modifiers", self.timeModifiers)
end

function PhunRunners:ini()
    if not self.inied then
        self.inied = true
        print("------------- SERVER INITIALIZING PHUNRUNNERS ---------------")
        self.timeModifiers = ModData.getOrCreate(self.name .. "_Modifiers")
        self.cycles = ModData.getOrCreate(self.name .. "_Cycles")
        triggerEvent(self.events.OnPunRunnersInitialized)
    end
end

local Commands = {}

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunRunners.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events[PhunRunners.events.OnPunRunnersInitialized].Add(function(playerObj, data)
    PhunRunners:reload()
end)

