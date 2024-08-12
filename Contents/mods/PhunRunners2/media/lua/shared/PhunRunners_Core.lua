PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {},
    settings = {
        tickDeffer = 50,
        graceTotalHours = 24,
        graceHours = 1,
        slowInLight = 0.7,
        zones = {{
            intensity = 2
        }, {
            intensity = 5
        }, {
            intensity = 10
        }, {
            intensity = 15
        }},
        moon = {0.5, 0.8, 0.9, 1.1, 2, 1.1, 0.9, 0.8}

    },
    zeds = {},
    players = {},
    events = {
        OnSprinterSpottedPlayer = "OnPhunRunnerSprinterSpottedPlayer",
        OnPhunRunnersZedDied = "OnPhunRunnersZedDied",
        OnPhunRunnersPlayerUpdated = "OnPhunRunnersPlayerUpdated"
    }
}

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:getZedData(zed)

    if not self.zeds[tostring(zed:getOnlineID())] then
        self.zeds[tostring(zed:getOnlineID())] = {
            sprinting = false,
            tested = false,
            created = getTimestamp(),
            modified = getTimestamp(),
            targetName = nil,
            isSupressed = false,
            ticks = nil
        }
    end
    return self.zeds[tostring(zed:getOnlineID())]
end

function PhunRunners:cleanZedData()

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

function PhunRunners:updateEnvironment()

    if self.env == nil then
        -- caches the current environment
        self.env = self:getEnvironment()
        return
    end

    local climate = getClimateManager()
    local lightIntensity = climate:getDayLightStrength()
    local fogIntensity = climate:getFogIntensity()

    if self.env.light.intensity == lightIntensity and self.env.fog.intensity == fogIntensity then
        -- no material change to env
        return
    end

    -- caches the current environment
    self.env = self:getEnvironment()
    return self.env

end

local moonPhaseNames = {"New Moon", "Crescent Moon", "First Quarter", "Gibbous Moon", "Full Moon", "Gibbous Moon",
                        "Last Quarter", "Waning Crescent"}
function PhunRunners:getEnvironment(refresh)

    local climate = getClimateManager()
    local gameTime = getGameTime()

    local lightStrength = climate:getDayLightStrength()
    local fogStrength = climate:getFogIntensity()

    local settings = SandboxVars.PhunRunners
    local season = climate:getSeason()

    local fogIntensity = math.floor((fogStrength * 100) + 0.5)

    -- convert to whole number after offsetting for fog
    local lightIntensity = math.floor((lightStrength * 100) + 0.5)

    if lightIntensity < 0 then
        lightIntensity = 0
    end

    local adjustedLightIntensity = lightIntensity - fogIntensity
    if adjustedLightIntensity < 0 then
        adjustedLightIntensity = 0
    end

    local lightValue = 0

    local m = getClimateMoon()
    local moonPhase = m:getCurrentMoonPhase()
    local moonPhaseName = moonPhaseNames[moonPhase + 1]

    local hours, minutes = gameTime:getHour(), gameTime:getMinutes()
    local toMins = (hours * 60) + minutes
    local dusk = gameTime:getDusk()
    local toDusk = (dusk * 60)
    local dawn = gameTime:getDawn()
    local toDawn = (dawn * 60)
    local timeToDusk = toDusk - toMins
    local timeToDawn = toDawn - toMins
    if timeToDusk < 0 then
        timeToDusk = 1440 + timeToDusk
    end
    if timeToDawn < 0 then
        timeToDawn = 1440 + timeToDawn
    end

    local results = {
        season = climate:getSeasonName(),
        value = (100 - adjustedLightIntensity),
        light = {
            adjustedLightIntensity = adjustedLightIntensity,
            intensity = lightIntensity
        },
        fog = {
            intensity = fogIntensity
        },
        moon = {
            phase = moonPhase,
            category = moonPhaseName
        },
        info = {
            night = gameTime:getNightsSurvived(),
            hour = hours,
            minute = minutes,
            dusk = dusk,
            dawn = dawn,
            timeToDusk = timeToDusk,
            timeToDawn = timeToDawn
        }
    }
    return results
end

function PhunRunners:updatePlayer(playerObj)

    if not playerObj or not playerObj:isLocalPlayer() then
        return
    end

    local name = playerObj:getUsername()
    local playerData = self:getPlayerData(name)
    local env = self.env
    local zone = PhunZones.players[name] or {
        difficulty = 0
    }
    local pstats = PhunStats:getPlayerData(name) or {
        total = {
            hours = 0
        }
    }

    local zoneDifficulty = zone.difficulty
    local hours = pstats.total.hours or 0
    local totalKills = pstats.total.kills or 0
    local totalSprinters = pstats.total.sprinters or 0
    local totalDeaths = pstats.total.deaths or 0
    local charHours = pstats.current.hours or 0
    local graceHours = charHours < self.settings.graceHours and self.settings.graceHours - charHours or 0
    local graceTotalHours = hours < self.settings.graceTotalHours and self.settings.graceTotalHours - hours or 0
    local sprinterKillRisk = 0
    local timerRisk = 0
    local zoneRisk = 0

    if hours > 1000 then
        timerRisk = 18
    elseif hours > 500 then
        timerRisk = 12
    elseif hours > 250 then
        timerRisk = 8
    elseif hours > 100 then
        timerRisk = 4
    elseif hours > 50 then
        timerRisk = 2
    end

    if totalSprinters > 100 then
        sprinterKillRisk = 12
    elseif totalSprinters > 50 then
        sprinterKillRisk = 8
    elseif totalSprinters > 25 then
        sprinterKillRisk = 6
    elseif totalSprinters > 10 then
        sprinterKillRisk = 4
    elseif totalSprinters > 5 then
        sprinterKillRisk = 2
    end

    if zoneDifficulty > 4 then
        zoneRisk = 100
    elseif zoneDifficulty > 3 then
        zoneRisk = 15
    elseif zoneDifficulty > 2 then
        zoneRisk = 10
    elseif zoneDifficulty > 1 then
        zoneRisk = 5
    end

    local totalRisk = (zoneRisk + timerRisk + sprinterKillRisk) * self.settings.moon[env.moon.phase + 1]
    totalRisk = totalRisk > 100 and 100 or totalRisk

    local modifier = 0
    if env.value < 30 then
        modifier = 0
    elseif env.value > 50 then
        modifier = 100
    else
        modifier = ((env.value - 30) / (50 - 30)) * 100
    end

    local grace = math.max(graceHours or 0, graceTotalHours or 0)

    local pd = {
        zone = zone,
        risk = totalRisk,
        modifier = modifier,
        env = env.value,
        spawnSprinters = modifier > 0 and grace == 0 and totalRisk > 0,
        restless = env.value > 30,
        difficulty = zoneDifficulty,
        zoneRisk = zoneRisk,
        timerRisk = timerRisk,
        sprinterKillRisk = sprinterKillRisk,
        moonMultiplier = self.settings.moon[env.moon.phase + 1],
        grace = grace
    }

    if zoneDifficulty == 0 or charHours < self.settings.graceHours or hours < self.settings.graceTotalHours then
        pd.risk = 0
        pd.restless = false
        pd.spawnSprinters = false
        -- else

        --     local zoneRisk = 0
        --     if zoneDifficulty > 4 then
        --         zoneRisk = 100
        --     elseif zoneDifficulty > 3 then
        --         zoneRisk = 15
        --     elseif zoneDifficulty > 2 then
        --         zoneRisk = 10
        --     elseif zoneDifficulty > 1 then
        --         zoneRisk = 5
        --     end

        --     local timerRisk = 0
        --     if hours > 1000 then
        --         timerRisk = 18
        --     elseif hours > 500 then
        --         timerRisk = 12
        --     elseif hours > 250 then
        --         timerRisk = 8
        --     elseif hours > 100 then
        --         timerRisk = 4
        --     elseif hours > 50 then
        --         timerRisk = 2
        --     end

        --     local sprinterKillRisk = 0
        --     if totalSprinters > 100 then
        --         timerRisk = 12
        --     elseif totalSprinters > 50 then
        --         timerRisk = 8
        --     elseif totalSprinters > 25 then
        --         timerRisk = 6
        --     elseif totalSprinters > 10 then
        --         timerRisk = 4
        --     elseif totalSprinters > 5 then
        --         timerRisk = 2
        --     end

        --     if zoneRisk == 0 or timerRisk == 0 then
        --         -- no risk
        --         pd.risk = 0
        --         pd.spawnSprinters = false
        --         pd.restless = false

        --     elseif zoneRisk == 100 then
        --         -- always on area
        --         pd.risk = 100
        --         pd.spawnSprinters = true
        --         pd.restless = true
        --     else

        --         pd.risk = (zoneRisk + timerRisk + sprinterKillRisk) * self.settings.moon[env.moon.phase + 1]
        --         pd.spawnSprinters = env.value > 30

        --     end

    end

    if pd.spawnSprinters ~= playerData.spawnSprinters then
        if pd.spawnSprinters then
            print("Player ", name, " is now spawning sprinters")
            self:startSprintersSound(playerObj)
        else
            print("Player ", name, " is no longer spawning sprinters")
            self:stopSprintersSound(playerObj)
        end
    end

    self.players[name] = pd

end

function PhunRunners:updatePlayers()
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        if p:isLocalPlayer() then
            self:updatePlayer(p)
        end
    end
end
