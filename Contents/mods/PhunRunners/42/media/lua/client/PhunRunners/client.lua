if isServer() then
    return
end
local PR = PhunRunners
local PhunStats = PhunStats
local PhunZones = PhunZones
local sandboxOptions = getSandboxOptions()
local world = getWorld()
local tickRate = sandbox.TickRate or 20
local SPRINT = 1
local NORMAL = 2
local diffText = {"min", "low", "moderate", "high", "extreme"}

-- Trigger audio notification that sprinters will start running
function PR:startSprintersSound(playerObj)
    local vol = (self.settings.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
end

-- Trigger audio notification that sprinters will stop running
function PR:stopSprintersSound(playerObj)
    local vol = (self.settings.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
end

-- Make zed return to normal speed
function PR:normalSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
    zed:getModData().PhunRunners.sprinting = false
    zed:makeInactive(false);
end

-- Make zed run at sprint speed
function PR:sprintSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", SPRINT)
    zed:getModData().PhunRunners.sprinting = true
    zed:makeInactive(false);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
end

-- configure any themed outfits
function PR:recalcOutfits()
    local total = 0
    local month = getGameTime():getMonth()
    local day = getGameTime():getDay()

    local items = {}

    self.outfit = nil

    if month == 11 and day < 28 then
        -- christmas
        self.outfit = self.baseOutfits.christmas
    elseif month == 11 and day >= 28 then
        -- nye
        self.outfit = self.baseOutfits.party
    elseif month == 9 then
        -- halloween
        self.outfit = self.baseOutfits.halloween
    elseif month == 4 then
        -- easter
        self.outfit = self.baseOutfits.easter
    end

    if self.outfit ~= nil then

        local genders = {"male", "female"}

        for k, v in pairs(self.outfit) do -- eg, party or christmas
            for _, partVal in pairs(v) do -- eg male or female
                -- for _, partVal in pairs(v[g]) do -- eg, Hat or Top
                local itotals = 0
                for _, vv in ipairs(partVal.items or {}) do
                    if not vv.mod or getActivatedMods():contains(vv.mod) then
                        if not vv.probability then
                            vv.probability = 10
                        end
                        itotals = itotals + vv.probability
                    else
                        vv.probability = 0
                    end
                end
                partVal.totalItemProbability = itotals
                -- end

            end
        end

    end

end

function PR:updateZed(zed)

    local zData = self:getZedData(zed)
    if zData == nil then
        return
    end

    if zData.sprinter == true and zData.dressed == nil and zed:isSkeleton() then
        -- cannot change to skeleton and dress in same update
        -- so we dress them after we convert to sprinter
        zData.dressed = true
        self:decorateZed(zed)
    end

    -- throttle checks. First time will pass because its nil
    if zData.tick ~= nil and zData.tick < tickRate then
        zData.tick = zData.tick + 1
        return
    end
    zData.tick = 1

    if zData.sprinter ~= false then
        if not self:testPlayers(zed, zData) then
            -- out of sight of all players?
            -- TODO: use to reset zed?
            -- well, this is just for local players - so maybe not useful?
            -- Could maybe reset the scream?
            return
        end
    end

    -- is a sprinter, but not changed visual yet
    if zData.sprinter and not zed:isSkeleton() then
        zed:setSkeleton(true)
    elseif not zData.sprinter and zed:isSkeleton() then
        zed:setSkeleton(false)
    end

    if zData.sprinter and zData.sprinting and not zData.screamed and instanceof(zed:getTarget(), "IsoPlayer") then
        self:scream(zed, zData)
    end

end

function PR:caclculateEnv()

    local climate = getClimateManager()

    -- get daylight intensity
    local lightIntensity = math.max(0, math.floor((climate:getDayLightStrength() * 100) + 0.5))
    -- get fog intensity
    local fogIntensity = math.floor((climate:getFogIntensity() * 100) + 0.5)

    -- adjust daylight intensity by fog intensity
    local adjustedLightIntensity = lightIntensity;
    if fogIntensity > 0 then
        -- TODO: Why recalc this?
        adjustedLightIntensity = math.max(0, lightIntensity - (lightIntensity * climate:getFogIntensity()))
    end

    self.env = {
        value = adjustedLightIntensity,
        light = lightIntensity,
        fog = fogIntensity,
        moon = getClimateMoon():getCurrentMoonPhase()
    }

    return self.env
end

-- Will return a cache of the env if refresh is not true
function PR:getEnvironment(refresh)

    if not refresh and self.env then
        return self.env
    else
        return self:caclculateEnv()
    end

end

function PR:showWidgets()
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        if p:isLocalPlayer() then
            self:showWidget(p)
        end
    end
end

function PR:showWidget(playerObj)
    self.ui.widget.OnOpenPanel(playerObj)
end

function PR:reloadWidget(playerObj)
    local w = self.ui.widget.instances[playerObj:getPlayerNum()]
    if w then
        w:close()
        w:removeFromUIManager()
        self.ui.widget.instances[playerObj:getPlayerNum()] = nil
    end
    self:showWidget(playerObj)
end

local modifiers = {
    inied = false,
    hours = nil,
    sprinters = nil,
    difficulty = nil,
    moon = nil
}

function PR:resetModifiers()
    modifiers.inied = false
end

-- update local db with players risk shit
function PR:updatePlayer(playerObj, zone)

    if not playerObj or not playerObj:isLocalPlayer() then
        return
    end

    if not modifiers.inied then

        modifiers.inied = true
        modifiers.hours = nil

        -- calculate modifiers from server settings
        local modifierMap = {
            ["hours"] = {
                setting = "TotalHoursModifier"
            },
            ["sprinters"] = {
                setting = "TotalSprintersModifier"
            },
            ["difficulty"] = {
                setting = "TotalDifficultyModifier",
                array = true
            },
            ["moon"] = {
                setting = "TotalMoonModifier",
                array = true
            }
        }

        for k, v in pairs(modifierMap) do
            local raw = self.settings[v.setting] or ""
            raw = luautils.split(raw, ";")
            if raw and #raw > 0 then
                if v.array then
                    modifiers[k] = {}
                    for i = 1, #raw do
                        modifiers[k][i] = tonumber(raw[i])
                    end
                else
                    modifiers[k] = {}
                    for i = 1, #raw do
                        local raw = luautils.split(raw[i], "=")
                        if raw and #raw == 2 then
                            modifiers[k][tonumber(raw[1])] = tonumber(raw[2])
                        end
                    end
                end
            end
        end
    end

    local name = playerObj:getUsername()
    local playerData = self:getPlayerData(name)
    local env = self:getEnvironment()
    local pData = playerObj:getModData()

    if not zone and PhunZones then
        zone = PhunZones:updateModData(playerObj)
    end
    local pstats = PhunStats and PhunStats:getData(name)

    local zoneDifficulty = zone.difficulty or 1
    local charHours = pstats.current.hours or 0
    local hours = pstats.total.hours or 0
    local totalKills = pstats.total.zombieKills or 0
    local totalSprinters = pstats.total.sprinterKills or 0

    local gHours = self.settings.GraceHours or 1
    local gTotalHours = self.settings.GraceTotalHours or 24
    local inGrace = charHours < gHours or hours < gTotalHours
    local sprinterKillRisk = 0
    local timerRisk = 0

    local zoneRisk = modifiers and modifiers.difficulty and modifiers.difficulty[zoneDifficulty] or 0
    local moonPhaseModifierValue = 100
    local lightModifier = 0

    if modifiers and modifiers.hours then
        for k, v in pairs(modifiers.hours) do
            if hours > k then
                timerRisk = v
                break
            end
        end
    end

    if modifiers and modifiers.sprinters then
        for k, v in pairs(modifiers.sprinters) do
            if totalSprinters >= k then
                sprinterKillRisk = v
                break
            end
        end
    end

    local mods = modifiers
    local m = env.moon
    moonPhaseModifierValue = (mods and mods.moon and mods.moon[m] or 100) * .01
    local totalRisk = math.min(100, (zoneRisk + timerRisk + sprinterKillRisk) * moonPhaseModifierValue)

    if env.value > self.settings.SlowInLightLevel then
        -- too bright for sprinters (green)
        lightModifier = 0
    elseif env.value < self.settings.DarknessLevel then
        -- dark enough for sprinters (red)
        lightModifier = 100
    else
        -- somewhere in between (yellow)
        -- TODO: Alternatively, maybe just leave as warning. Don't need to particularly adjust speeds on this
        lightModifier = ((self.settings.SlowInLightLevel - self.settings.DarknessLevel) /
                            (env.value - self.settings.DarknessLevel)) * 100
    end

    local graceHours = math.max(0, math.max((gHours or 1) - charHours, (gTotalHours or 24) - hours))
    local pd = {
        zone = zone,
        hours = charHours,
        totalHours = hours,
        totalKills = totalKills,
        totalSprinters = totalSprinters,
        risk = totalRisk,
        modifier = lightModifier,
        env = env,
        spawnSprinters = lightModifier > 0 and graceHours == 0 and totalRisk > 0,
        restless = env.value > 30, -- ?
        difficulty = zoneDifficulty,
        zoneRisk = zoneRisk,
        timerRisk = timerRisk,
        sprinterKillRisk = sprinterKillRisk,
        moonMultiplier = moonPhaseModifierValue,
        grace = graceHours
    }

    if zoneDifficulty == 0 or inGrace then
        pd.risk = 0
        pd.restless = false
        pd.spawnSprinters = false
    end

    if pd.spawnSprinters ~= playerData.spawnSprinters then
        if pd.spawnSprinters then
            print("Player ", name, " is now spawning sprinters")
            triggerEvent(PR.events.OnPlayerStartSpawningSprinters, playerObj)
            self:startSprintersSound(playerObj)
        else
            print("Player ", name, " is no longer spawning sprinters")
            triggerEvent(PR.events.OnPlayerStopSpawningSprinters, playerObj)
            self:stopSprintersSound(playerObj)
        end
    elseif pd.risk ~= playerData.risk then
        triggerEvent(PR.events.OnPlayerRiskUpdate, playerObj, pd)
    end

    self.players[name] = pd
    return pd

end

function PR:getPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    elseif playerObj then
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

function PR:updatePlayers()
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        if p:isLocalPlayer() then
            self:updatePlayer(p)
        end
    end
end
