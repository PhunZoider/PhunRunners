if isServer() then
    return
end
local PhunRunners = PhunRunners
local PhunZones = PhunZones
local PhunStats = PhunStats
local sandbox = SandboxVars.PhunRunners

local receivedCycles = false
local receievedModified = false
local receivedAllData = false

local MF = MF;
local SPRINT = 1
local NORMAL = 2

function PhunRunners:makeSprint(zed)
    zed:makeInactive(true);
    getSandboxOptions():set("ZombieLore.Speed", SPRINT)
    zed:makeInactive(false);
    getSandboxOptions():set("ZombieLore.Speed", NORMAL)
    local soundName = "PhunRunners_" .. ZombRand(1, 6)

    -- zed:playSound(soundName):setVolume(vol);
    if zed:getEmitter():isPlaying(soundName) then
        return
    end

    local vol = (sandbox.PhunRunnersSprinterVolume or 25) * .01
    local soundEmitter = getWorld():getFreeEmitter()
    local hnd = soundEmitter:playSound(soundName, zed:getX(), zed:getY(), zed:getZ())
    soundEmitter:setVolume(hnd, vol)

    triggerEvent(self.events.OnSprinterSpottedPlayer, zed, target)
end

function PhunRunners:makeNormal(zed)
    if string.find(zed:getVariableString("zombiewalktype"), "sprint") then
        -- now its morning, turn it off
        zed:makeInactive(true);
        getSandboxOptions():set("ZombieLore.Speed", NORMAL)
        zed:makeInactive(false);
        zed:getModData().PhunRunners = nil
        triggerEvent(self.events.OnSprinterLostPlayer, zed, target)
        return
    end
end

function PhunRunners:updateZed(zed)

    -- get zed modData
    if zed:getModData().PhunRunners == nil then
        zed:getModData().PhunRunners = {}
    end
    local zData = zed:getModData().PhunRunners or {}

    -- if it isn't time to run and zed isn't already sprinting, exit out
    if self.doRun ~= true and zData.sprinting ~= true then
        zData = {}
        return
    elseif self.doRun == true and zData.sprinting ~= nil then
        -- we are running (or not) and zed is already sprinting
        return
    end

    zData.ticks = zData.ticks or 0;
    if zData.ticks < self.ticks then
        zData.ticks = zData.ticks + 1
        return
    end
    zData.ticks = 0

    local target = zed:getTarget()
    local player
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        if p == target then
            player = p
            break
        end
    end
    if not player then
        -- just ignore it
        return
    end

    local playerData = self:getPlayerData(player)

    if (not self.doRun and zData.sprinting) or (zData.sprinting and not playerData.spawnSprinters) then
        -- globally, its morning so stop sprinting
        -- or player is not longer eligible for sprinters
        self:makeNormal(zed)
        return
    end

    if not playerData.spawnSprinters or not self.doRun or not playerData.timeModifier or
        playerData.timeModifier.difficulty == 0 then
        return
    end

    -- this zed isnt running. Should it?
    if zData.sprinting == nil and playerData.spawnSprinters and playerData.risk > 0 then
        -- we haven't tested this zed yet
        zData.sprinting = false
        zData.location = PhunZones:getLocation(zed)

        local chance = ZombRand(100)
        if chance <= playerData.risk then
            self:makeSprint(zed)
            zData.sprinting = true
        end
    end

end

-- Sets the times that runners are active for
-- Shouldnt need to be called more than once a day and at startup
function PhunRunners:updateCycle()
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

    if changed then
        triggerEvent(self.events.OnPhunRunnersCycleChange, self.currentCycle)
        self:updatePlayers()
    end
end

function PhunRunners:updatePlayers()
    for i = 1, getOnlinePlayers():size() do
        local playerObj = getOnlinePlayers():get(i - 1)
        self:updatePlayer(playerObj)
    end
end

-- Updates the variables for specific player
-- Should be called when a player first joins, when a cycle changes, when a location changes or once per day
function PhunRunners:updatePlayer(playerObj)
    if not playerObj or not playerObj.getUsername then
        return
    end
    if not self.data then
        self.data = {}
    end
    if not self.data.players then
        self.data.players = {}
    end
    local data = PhunRunners:getPlayerData(playerObj)

    local wasSprinting = data.spawnSprinters == true
    local wasRestless = data.restless == true

    local cycle = self.currentCycle
    local location = nil
    local difficulty = 1

    if PhunZones then
        location = PhunZones:getLocation(playerObj)
        difficulty = location.difficulty
    end

    local moon = getClimateMoon():getCurrentMoonPhase()
    local charHours = playerObj:getHoursSurvived()
    local totalHours = charHours
    if PhunStats then
        local ps = PhunStats:getPlayerData(playerObj) or {}
        totalHours = (ps.total or {}).hours or charHours
    end

    local timeModifiers = self.timeModifiers[difficulty] or {}
    local timeModifier = nil
    for _, mod in pairs(timeModifiers) do
        if totalHours >= (mod or {}).hours or 0 then
            timeModifier = mod
        else
            break
        end
    end
    local spawnSprinters = true
    local risk = 0
    if difficulty == 0 or charHours < self.graceOnCharacterCreation or totalHours < self.graceHours or
        timeModifier.modifier == 0 then
        -- 0 risk. end of
        spawnSprinters = false
    else
        risk = ((moon + 1) / 2) * difficulty + timeModifier.modifier
    end

    data.location = location
    data.timeModifier = timeModifier
    data.charHours = charHours
    data.totalHours = totalHours
    data.risk = risk
    data.moon = moon
    data.difficulty = difficulty
    data.spawnSprinters = spawnSprinters

    local gt = getGameTime()
    local hour = gt:getHour()
    local cycle = self.currentCycle
    data.restless = not (hour <= (cycle.startHour or 0) and hour >= (cycle.endHour or 0))
    if data.restless == false then
        data.spawnSprinters = false
    end

    print("PhunRunners: " .. playerObj:getUsername() .. " is now " ..
              (data.spawnSprinters and "eligible" or "not eligible") .. " for sprinters. Restless = " ..
              tostring(data.restless) .. " Risk = " .. tostring(risk))

    if data.spawnSprinters ~= wasSprinting then
        if data.spawnSprinters then
            print("Notifying of start")
            self:startSprinters(playerObj)
        else
            print("Notifying of stop")
            self:stopSprinters(playerObj)
        end
    end

end

function PhunRunners:ini()
    if not self.inied then
        ModData.request(self.name .. "_Modifiers")
        ModData.request(self.name .. "_Cycles")
    end
end

local function setup()
    Events.EveryOneMinute.Remove(setup)
    PhunRunners:ini()
    for i = 0, getOnlinePlayers():size() - 1 do
        local player = getOnlinePlayers():get(i)
        PhunRunnersUI.OnOpenPanel(player)
        sendClientCommand(player, PhunRunners.name, PhunRunners.commands.requestData, {})
    end
end
Events.EveryOneMinute.Add(setup)

local Commands = {}

function PhunRunners:refresh()
    if receievedModified and receivedCycles then
        self:updateCycle()
        -- self:updatePlayers()
    end
end

Events.OnServerCommand.Add(function(module, command, arguments)
    local p = PhunRunners
    local c = Commands
    if module == p.name and c[command] then
        Commands[command](arguments)
    end
end)

Events.OnZombieDead.Add(function(zed)
    local data = zed:getModData().PhunRunners
    if data then
        if data.sprinting then
            triggerEvent(PhunRunners.events.OnPhunRunnersZedDied, zed)
        end
    end
end);

Events.OnPlayerDeath.Add(function(playerObj)
    local data = PhunRunners:getPlayerData(playerObj)
    data = {}
end)

Events.OnZombieUpdate.Add(function(z)
    PhunRunners:updateZed(z)
end);

Events[PhunRunners.events.OnPunRunnersInitialized].Add(function(playerObj, data)

    Events[PhunRunners.events.OnPhunRunnersCycleChange].Add(function()
        print("PhunRunners: OnPhunRunnersCycleChange")

        PhunRunners:updatePlayers()
        -- PhunRunners:updateState()
    end)

    Events.OnGameStart.Add(function()
        print("PhunRunners: OnGameStart")
        PhunRunners:calculateCycle()
        -- PhunRunners:refresh()
    end)

    if PhunZones and PhunZones.events then
        Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
            function(playerObj, location, old)
                print("PhunRunners: OnPhunZonesPlayerLocationChanged")
                PhunRunners:updatePlayer(playerObj)
            end)
    end

    Events.EveryHours.Add(function()
        print("PhunRunners: EveryHours")
        PhunRunners:refresh()
    end)

end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)

    if tableName == PhunRunners.name .. "_Cycles" and type(tableData) == "table" then
        PhunRunners.cycles = tableData
        receivedCycles = true
        PhunRunners:refresh()
    elseif tableName == PhunRunners.name .. "_Modifiers" and type(tableData) == "table" then
        PhunRunners.timeModifiers = tableData
        receievedModified = true
        PhunRunners:refresh()
    end
    if receievedModified and receivedCycles and receivedAllData == false then
        receivedAllData = true
        triggerEvent(PhunRunners.events.OnPunRunnersInitialized)
    end

end)
