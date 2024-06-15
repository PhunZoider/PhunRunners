local phunStats = nil
PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        dataLoaded = "dataLoaded",
        reload = "reload",
        requestData = "requestPhunRunnersData",
        doRun = "doRun"
    },
    doRun = nil,
    ticks = 100,
    graceHours = 48,
    graceOnCharacterCreation = 1,
    data = {
        players = {}
    },
    currentCycle = nil,
    cycles = {{
        month = 1,
        day = 1,
        startHour = 8,
        endHour = 6
    }, {
        month = 4,
        day = 1,
        startHour = 22,
        endHour = 6
    }, {
        month = 6,
        day = 1,
        startHour = 23,
        endHour = 6
    }, {
        month = 8,
        day = 1,
        startHour = 22,
        endHour = 6
    }, {
        month = 9,
        day = 1,
        startHour = 21,
        endHour = 6
    }, {
        month = 11,
        day = 5,
        startHour = 20,
        endHour = 6
    }},
    timeModifiers = {{{
        hours = 0,
        modifier = 0
    }, -- 0 sprinters
    {
        hours = 48,
        modifier = 1
    }, {
        hours = 168,
        modifier = 2
    }, {
        hours = 336,
        modifier = 6
    }, {
        hours = 672,
        modifier = 10
    }, {
        hours = 1344,
        modifier = 15
    }}, {{
        hours = 0,
        modifier = 0
    }, {
        hours = 48,
        modifier = 1
    }, {
        hours = 168,
        modifier = 3
    }, {
        hours = 336,
        modifier = 6
    }, {
        hours = 672,
        modifier = 10
    }, {
        hours = 1344,
        modifier = 15
    }}, {{
        hours = 0,
        modifier = 0
    }, {
        hours = 48,
        modifier = 1
    }, {
        hours = 168,
        modifier = 3
    }, {
        hours = 336,
        modifier = 6
    }, {
        hours = 672,
        modifier = 10
    }, {
        hours = 1344,
        modifier = 15
    }}, {{
        hours = 0,
        modifier = 0
    }, {
        hours = 48,
        modifier = 1
    }, {
        hours = 168,
        modifier = 3
    }, {
        hours = 336,
        modifier = 6
    }, {
        hours = 672,
        modifier = 10
    }, {
        hours = 1344,
        modifier = 15
    }}},
    events = {
        OnPunRunnersInitialized = "OnPunRunnersInitialized",
        OnPhunRunnersStarting = "OnPhunRunnersStarting",
        OnPhunRunnersEnding = "OnPhunRunnersEnding",
        OnSprinterSpottedPlayer = "OnPhunRunnersSprinterSpottedPlayer",
        OnSprinterLostPlayer = "OnPhunRunnerSprinterLostPlayer",
        OnPhunRunnersZedDied = "OnPhunRunnersZedDied",
        OnPhunRunnersUIOpened = "OnPhunRunnersUIOpened",
        OnPhunRunnersCycleChange = "OnPhunRunnersCycleChange",
        OnPhunRunnersPlayerUpdated = "OnPhunRunnersPlayerUpdated",
    }
}

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:ini()
    if not self.inied then
        self.inied = true
        triggerEvent(self.events.OnPunRunnersInitialized)
    end

end

function PhunRunners:calculateCycle()

    local gt = getGameTime()
    local currentPhase = self.currentCycle
    local changed = false

    local hour = gt:getHour()
    local month = gt:getMonth() + 1
    local day = gt:getDay() + 1

    for _, v in ipairs(self.cycles) do
        if month >= v.month then
            if day >= v.day then
                if currentPhase == nil or currentPhase.month ~= self.currentCycle.month or currentPhase.day ~=
                    self.currentCycle.day then
                    changed = true
                    self.currentCycle = v
                end
            end
        elseif month < v.month then
            break
        end
    end

end

Events.OnZombieUpdate.Add(PhunRunners.updateZed);

Events.OnInitGlobalModData.Add(function()
    PhunRunners:ini()
    PhunRunners.data = ModData.getOrCreate(PhunRunners.name)
end)

