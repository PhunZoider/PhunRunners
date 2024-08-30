PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        createSprinter = "createSprinter",
        registerSprinter = "registerSprinter",
        unregisterSprinter = "unregisterSprinter"
    },
    lastUpdated = 0,
    lastTransmitted = 0,
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
    },
    baseOutfits = {
        christmas = {
            male = {
                Hat = {{
                    type = "AuthenticZClothing.Hat_SantaHatBluePattern"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHatGreen"
                }}
            },
            female = {
                Hat = {{
                    type = "AuthenticZClothing.Hat_SantaHatBluePattern"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHat"
                }, {
                    type = "Base.Hat_SantaHatGreen"
                }}
            }

        },
        party = {
            male = {
                Hat = {{
                    type = "AuthenticZClothing.Hat_ClownConeHead"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }}
            },
            female = {
                Hat = {{
                    type = "AuthenticZClothing.Hat_ClownConeHead"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }, {
                    type = "Base.Hat_PartyHat_TINT"
                }}
            }

        }
    },
    outfit = nil
}

local phunZones = nil
local phunStats = nil
local sandbox = SandboxVars.PhunRunners

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:getPlayerData(playerObj)
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

function PhunRunners:registerSprinter(zid, skipNotify)
    if zid and not self.registry[zid] then
        self.registry[zid] = getGameTime():getWorldAgeHours()
        print("Registered ", zid)

        if isClient() and not skipNotify then
            local p = getPlayer()
            sendClientCommand(p, self.name, self.commands.registerSprinter, {
                id = zid
            })
        elseif isServer() then
            print("Sending server command ", self.name, self.commands.registerSprinter, zid)
            sendServerCommand(self.name, self.commands.registerSprinter, {
                id = zid
            })
        end

    end
end

function PhunRunners:unregisterSprinter(zid, skipNotify)
    if zid and self.registry[zid] then
        self.registry[zid] = nil
        print("Unregistered ", zid)

        if isClient() and not skipNotify then
            sendClientCommand(getPlayer(), self.name, self.commands.unregisterSprinter, {
                id = zid
            })
        elseif isServer() and not skipNotify then
            print("Sending server command ", self.name, self.commands.unregisterSprinter, zid)
            sendServerCommand(self.name, self.commands.unregisterSprinter, {
                id = zid
            })
        end

    end
end

function PhunRunners:init()
    ModData.add(self.name, {})
    self.registry = ModData.getOrCreate(self.name)
    if phunZones == nil then
        phunZones = PhunZones or false
    end
    if phunStats == nil then
        phunStats = PhunStats or false
    end
end

function PhunRunners:getId(zedObj)
    if zedObj then
        if instanceof(zedObj, "IsoZombie") then
            if zedObj:isZombie() then
                if isClient() or isServer() then
                    return zedObj:getOnlineID()
                else
                    return zombie:getID()
                end
            end
        end
    end
end

local modifiers = {
    inied = false,
    hours = nil,
    sprinters = nil,
    difficulty = nil,
    moon = nil
}

function PhunRunners:debug(...)
    if PhunTools then
        PhunTools:debug(...)
    else
        print(...)
    end
end

function PhunRunners:printTable(t)
    if PhunTools then
        PhunTools:printTable(t)
    else
        print("PhunRunners:printTable: ", t)
    end
end

function PhunRunners:updatePlayer(playerObj)

    if not modifiers.inied then
        modifiers.inied = true
        modifiers.hours = nil
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
        local sb = sandbox
        for k, v in pairs(modifierMap) do
            local raw = sb[v.setting] or ""
            raw = luautils.split(raw, ";")
            if raw and #raw > 0 then
                if v.array then
                    modifiers[k] = raw
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

        self:printTable(modifiers)
    end

    if not playerObj or not playerObj:isLocalPlayer() then
        return
    end

    local name = playerObj:getUsername()
    local playerData = self:getPlayerData(name)
    local env = self.env
    local zone = phunZones and phunZones:updateLocation(playerObj) or {
        difficulty = 0
    }
    local pstats = phunStats and phunStats:getPlayerData(name) or {
        current = {
            hours = playerObj:getHoursSurvived()
        },
        total = {
            hours = playerObj:getHoursSurvived()
        }
    }

    local zoneDifficulty = zone.difficulty or 1
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
            if hours > k then
                sprinterKillRisk = v
                break
            end
        end
    end

    zoneDifficulty = modifiers and zoneDifficulty and zoneDifficulty > 0 and modifiers.difficulty and
                         modifiers.difficulty[zoneDifficulty] or 0
    moonPhaseModifierValue = (modifiers and env and env.mooon and env.moon.phase and modifiers.moon[env.moon.phase] or
                                 100) * .01
    local totalRisk = math.min(100, (zoneRisk + timerRisk + sprinterKillRisk) * moonPhaseModifierValue)

    if env.value < 30 then
        lightModifier = 0
    elseif env.value > 50 then
        lightModifier = 100
    else
        lightModifier = ((env.value - 30) / (50 - 30)) * 100
    end

    local grace = math.max(graceHours or 0, graceTotalHours or 0)

    local pd = {
        zone = zone,
        risk = totalRisk,
        modifier = lightModifier,
        env = env.value,
        spawnSprinters = lightModifier > 0 and grace == 0 and totalRisk > 0,
        restless = env.value > 30,
        difficulty = zoneDifficulty,
        zoneRisk = zoneRisk,
        timerRisk = timerRisk,
        sprinterKillRisk = sprinterKillRisk,
        moonMultiplier = moonPhaseModifierValue,
        grace = grace
    }

    if zoneDifficulty == 0 or charHours < self.settings.graceHours or hours < self.settings.graceTotalHours then
        pd.risk = 0
        pd.restless = false
        pd.spawnSprinters = false
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
