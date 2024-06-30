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
    players = {},
    currentCycle = nil,
    cycles = {},
    timeModifiers = {},
    events = {
        OnPunRunnersInitialized = "OnPunRunnersInitialized",
        OnPhunRunnersStarting = "OnPhunRunnersStarting",
        OnPhunRunnersEnding = "OnPhunRunnersEnding",
        OnSprinterSpottedPlayer = "OnPhunRunnersSprinterSpottedPlayer",
        OnSprinterLostPlayer = "OnPhunRunnerSprinterLostPlayer",
        OnPhunRunnersZedDied = "OnPhunRunnersZedDied",
        OnPhunRunnersUIOpened = "OnPhunRunnersUIOpened",
        OnPhunRunnersCycleChange = "OnPhunRunnersCycleChange",
        OnPhunRunnersPlayerUpdated = "OnPhunRunnersPlayerUpdated"
    }
}

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:getPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    else
        key = playerObj:getUsername()
    end
    if key and string.len(key) > 0 then
        if not self.players then
            self.players = {}
        end
        if not self.players[key] then
            self.players[key] = {
                risk = 0,
                spawnSprinters = false,
                restless = false,
                location = nil
            }
        end
        return self.players[key]
    end
end

function PhunRunners:getSummary(playerObj)

    local playerNumber = playerObj:getPlayerNum()
    local currentData = self:getPlayerData(playerObj)
    if not currentData or not currentData.location then
        return
    end

    local riskTitle = currentData.location.title or "Wilderness"
    if currentData.location.subtitle then
        riskTitle = riskTitle .. "\n" .. currentData.location.subtitle .. "\n"
    else
        riskTitle = riskTitle .. "\n"
    end
    local riskDesc = {};
    if currentData.location and currentData.location.title then
        table.insert(riskDesc, getText("IGUI_PhunRunners_RiskLevel", currentData.risk))
        table.insert(riskDesc, getText("IGUI_PhunRunners_RiskFromArea", currentData.difficulty))
        if currentData.moon > 1 then
            table.insert(riskDesc, getText("IGUI_PhunRunners_RiskFromMoon", (currentData.moon + 1) / 2))
        end
        if currentData.timeModifier then
            table.insert(riskDesc, getText("IGUI_PhunRunners_RiskFromTime", currentData.timeModifier.modifier))
        end
    end
    table.insert(riskDesc, "")
    if currentData.restless then
        table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreRestless"))
    else
        table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreSettling"))
    end

    return {
        title = riskTitle,
        description = table.concat(riskDesc, "\n"),
        spawnSprinters = currentData.spawnSprinters == true,
        risk = currentData.risk,
        difficulty = currentData.difficulty,
        restless = currentData.spawnSprinters and self.doRun
    }
end

-- Player is eligible for sprinters to start, but indiviual settings may prevent it
function PhunRunners:startSprinters(playerObj, skipNotification)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
    -- show moodle?
    PhunRunnersUI.OnOpenPanel(playerObj)
    if MF and MF.getMoodle then
        MF.getMoodle(self.name, playerObj:getPlayerNum()):activate()
    end
    -- end
end

function PhunRunners:stopSprinters(playerObj, skipNotification)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
    -- show moodle?
    PhunRunnersUI.OnOpenPanel(playerObj)
    if MF and MF.getMoodle then
        MF.getMoodle(self.name, playerObj:getPlayerNum()):activate()
    end
    -- end
end

function PhunRunners:getPlayersRiskofSprinters(playerObj)
    local currentData = playerObj:getModData().PhunRunners

    if not currentData or not currentData.location then
        return {
            risk = 0
        }
    end
end

function PhunRunners:getPlayerRisk(playerObj)

    local currentData = playerObj:getModData().PhunRunners

    if not currentData or not currentData.location then
        return 0
    end

    return currentData.risk or 0

end

function PhunRunners:canSpawnSprinters(playerObj)

    local currentData = playerObj:getModData().PhunRunners

    if not currentData or not currentData.location then
        return 0
    end

    return currentData.spawnSprinters == true

end

Events.OnZombieUpdate.Add(PhunRunners.updateZed);

Events.OnInitGlobalModData.Add(function()
    PhunRunners:ini()
end)

