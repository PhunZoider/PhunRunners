if isServer() then
    return
end
local PhunRunners = PhunRunners
local PhunZones = PhunZones

local MF = MF;
local SPRINT = 1
local NORMAL = 2

function PhunRunners:makeSprint(zed)
    zed:makeInactive(true);
    getSandboxOptions():set("ZombieLore.Speed", SPRINT)
    zed:makeInactive(false);
    getSandboxOptions():set("ZombieLore.Speed", NORMAL)
    zed:playSound("PhunRunners_" .. ZombRand(1, 6))
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

    local playerData = player:getModData().PhunRunners or {}

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
    local name = playerObj:getUsername()
    if self.data.players[name] then
        local cycle = self.currentCycle
        local location = PhunZones:getLocation(playerObj)
        local moon = getClimateMoon():getCurrentMoonPhase()
        local charHours = playerObj:getHoursSurvived()
        local totalHours = charHours + self.data.players[name].totalHours or 0
        local difficulty = location.difficulty
        local timeModifiers = self.timeModifiers[difficulty] or {}
        local timeModifier = nil
        for _, mod in pairs(timeModifiers) do
            if totalHours >= mod.hours then
                timeModifier = mod
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

        if not playerObj:getModData().PhunRunners then
            playerObj:getModData().PhunRunners = {}
        end
        local currentData = playerObj:getModData().PhunRunners

        currentData.location = location
        currentData.timeModifier = timeModifier
        currentData.charHours = charHours
        currentData.totalHours = totalHours
        currentData.spawnSprinters = spawnSprinters
        currentData.risk = risk
        currentData.moon = moon
        currentData.difficulty = difficulty
        triggerEvent(self.events.OnPhunRunnersPlayerUpdated, playerObj, currentData)
        self:updateMoodle(playerObj)
    end
end

-- determins if sprinters should be active or not
function PhunRunners:updateState()
    local currentState = self.doRun
    local gt = getGameTime()
    local hour = gt:getHour()
    local cycle = self.currentCycle
    if not (hour <= cycle.startHour and hour >= cycle.endHour) then
        if not self.doRun then
            self.doRun = true
            triggerEvent(self.events.OnPhunRunnersStarting)
            PhunRunners:updatePlayers()
        end
    else
        -- should now be inactive. Are we?
        if self.doRun then
            self.doRun = false
            triggerEvent(self.events.OnPhunRunnersEnding)
            PhunRunners:updatePlayers()
        end
    end
end

local function requestDataOnce()
    Events.EveryOneMinute.Remove(requestDataOnce)
    for i = 0, getOnlinePlayers():size() - 1 do
        local player = getOnlinePlayers():get(i)
        PhunRunnersUI.OnOpenPanel(player)
        sendClientCommand(player, PhunRunners.name, PhunRunners.commands.requestData, {})
    end
end
Events.EveryOneMinute.Add(requestDataOnce)

local Commands = {}

Commands[PhunRunners.commands.requestData] = function(data)
    if not PhunRunners.data then
        PhunRunners.data = {}
    end
    if not PhunRunners.data.players then
        PhunRunners.data.players = {}
    end
    PhunRunners.data.players[data.name] = data.data
    PhunRunners:refresh()
    Events.EveryHours.Add(function()
        PhunRunners:refresh()
    end)
end

function PhunRunners:refresh()
    self:updateCycle()
    self:updatePlayers()
    self:updateState()
end

Events[PhunRunners.events.OnPhunRunnersCycleChange].Add(function()
    PhunRunners:updatePlayers()
    PhunRunners:updateState()
end)

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

local function extract_number(str)
    -- Normalize the string by removing spaces around commas and ensuring proper decimal points
    str = string.gsub(str, "%s*,%s*", ",")
    -- Match the pattern for a number with commas and optional decimal part
    local number = string.match(str, "[%d,]+%.?%d*")
    if number then
        -- Optional: Validate the number format if necessary
        -- Convert to a number by removing commas
        number = tonumber(string.gsub(number, ",", ""))
    end
    return number
end

Events.OnPlayerDeath.Add(function(playerObj)
    local name = playerObj:getUsername()
    local data = PhunRunners.data[name] or {}
    if not data.totalHours then
        data.totalHours = 0
    end
    if not data.hours then
        data.hours = 0
    end
    if not data.kills then
        data.kills = 0
    end
    if not data.totalKills then
        data.totalKills = 0
    end
    data.totalHours = data.totalHours + data.hours
    local gt = getGameTime()
    local txt = gt:getZombieKilledText(playerObj)
    local kills = tonumber(string.gsub(txt, "[^%d]", "") or "0")

    data.totalKills = data.totalKills + kills
    data.hours = 0
    data.kills = 0
    sendClientCommand(playerObj, PhunRunners.name, PhunRunners.commands.requestData, data)
end)

Events.OnZombieUpdate.Add(function(z)
    PhunRunners:updateZed(z)
end);

Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
    function(playerObj, location, old)
        PhunRunners:updatePlayer(playerObj)
    end)

Events[PhunRunners.events.OnPhunRunnersStarting].Add(function()
    for i = 1, getOnlinePlayers():size() do
        local playerObj = getOnlinePlayers():get(i - 1)
        PhunRunners:updatePlayer(playerObj)
        getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(0.25);
        -- show moodle?
        PhunRunnersUI.OnOpenPanel(playerObj, true)
        if MF and MF.getMoodle then
            MF.getMoodle(PhunRunners.name, playerObj:getPlayerNum()):activate()
        end
    end
end)

Events[PhunRunners.events.OnPhunRunnersEnding].Add(function()
    for i = 1, getOnlinePlayers():size() do
        local playerObj = getOnlinePlayers():get(i - 1)
        PhunRunners:updatePlayer(playerObj)
        getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(0.25);
        -- hide moodle?
        PhunRunnersUI.OnOpenPanel(playerObj, false)
        if MF and MF.getMoodle then
            MF.getMoodle(PhunRunners.name, playerObj:getPlayerNum()):suspend()
        end
    end
end)
