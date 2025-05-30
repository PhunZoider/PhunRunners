local Delay = require("PhunRunners/delay")

PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        createSprinter = "PhunRunnersCreateSprinter",
        registerSprinter = "PhunRunnersRegisterSprinter",
        unregisterSprinter = "PhunRunnersUnregisterSprinter",
        stateChange = "PhunRunnersStateChange",
        requestState = "PhunRunnersRequestState"
    },
    env = {
        risk = 0,
        value = 0,
        moon = 0,
        run = false
    },
    ui = {},
    players = {},
    data = {},
    events = {
        OnSprinterDeath = "OnPhunRunnersSprinterDeath",
        OnPlayerStartSpawningSprinters = "OnPhunRunnersPlayerStartSpawningSprinters",
        OnPlayerStopSpawningSprinters = "OnPhunRunnersPlayerStopSpawningSprinters",
        OnPlayerRiskUpdate = "OnPhunRunnersPlayerRiskUpdate",
        OnPlayerEnvUpdate = "OnPhunRunnersPlayerEnvUpdate",
        OnReady = "OnPhunRunnersReady"
    },
    pendingRemovals = {},
    resetIds = {},
    baseOutfits = {
        christmas = {
            male = {
                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.Hat_SantaHatBluePattern",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_SantaHat",
                        probability = 50

                    }, {
                        type = "Base.Hat_SantaHatGreen",
                        probability = 10
                    }}
                }
            },
            female = {
                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.Hat_SantaHatBluePattern",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_SantaHat",
                        probability = 50

                    }, {
                        type = "Base.Hat_SantaHatGreen",
                        probability = 10
                    }}
                }

            }
        },
        easter = {
            male = {
                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.BunnyEars",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_BunnyEarsBlack",
                        probability = 50

                    }, {
                        type = "Base.Hat_BunnyEarsWhite",
                        probability = 10
                    }}
                }
            },
            female = {
                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.BunnyEars",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_BunnyEarsBlack",
                        probability = 50

                    }, {
                        type = "Base.Hat_BunnyEarsWhite",
                        probability = 10
                    }}
                }

            }
        },
        halloween = {
            male = {
                FullHelmet = {
                    probability = 100,
                    items = {{
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Angry",
                        mod = "HallweensPumpkinHelmets",
                        probability = 10
                    }, {
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Pirate",
                        mod = "HallweensPumpkinHelmets",
                        probability = 1

                    }, {
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Surprised",
                        mod = "HallweensPumpkinHelmets",
                        probability = 5
                    }}
                }
            },
            female = {
                FullHelmet = {
                    probability = 100,
                    items = {{
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Angry",
                        mod = "HallweensPumpkinHelmets",
                        probability = 10
                    }, {
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Pirate",
                        mod = "HallweensPumpkinHelmets",
                        probability = 1

                    }, {
                        type = "HallweensPumpkinHelmets.Hat_Pumpkin_Helmet_Surprised",
                        mod = "HallweensPumpkinHelmets",
                        probability = 5
                    }}
                }

            }
        },
        party = {
            male = {

                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.Hat_ClownConeHead",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_PartyHat_TINT",
                        probability = 80

                    }}
                }
            },
            female = {
                Hat = {
                    probability = 100,
                    items = {{
                        type = "AuthenticZClothing.Hat_ClownConeHead",
                        mod = "Authentic Z - Current",
                        probability = 10
                    }, {
                        type = "Base.Hat_PartyHat_TINT",
                        probability = 80

                    }}
                }
            }

        }

    },
    outfit = nil,
    registry = {},
    toUnregister = {},
    settings = {
        DeferUnregisterSeconds = 240
    }
}

local Core = PhunRunners
Core.settings = SandboxVars[Core.name] or {}
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            self:printTable(v)
        else
            print(tostring(v))
        end
    end
end

function Core:printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core:printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        -- load existing data
        self.data = ModData.getOrCreate(self.name)

        if self.isLocal then
            self:updateDawnDusk()
            self:updateMoon()
            self:updateEnv()
        end
    end
end

function Core:updateDawnDusk()
    print("===========")
    print("UPDATING DAWNDUSK")
    print("===========")
    print("UPDATING DAWNDUSK")
    if getClimateManager and getClimateManager().getSeason then
        local season = getClimateManager():getSeason()
        if season and season.getDusk then
            self.data.dawnTime = season:getDawn()
            self.data.duskTime = season:getDusk()
        else
            print("CANNOT CALC SEASON")
        end
    else
        print("CANNOT CALCULTATE DAWNDUSK")
        if not getClimateManager then
            print("NO CLIMATE MANAGER")
        else
            print("NO SEASON")
        end
    end
end

function Core:updateMoon()
    print("===========")
    print("UPDATING MOON")
    print("===========")
    local values = luautils.split(self.settings.TotalMoonModifier, ";")
    self.data.moon = getClimateMoon():getCurrentMoonPhase()
    local existing = self.data.moonMultiplier
    self.data.moonMultiplier = (values[getClimateMoon():getCurrentMoonPhase() + 1] or 100) * .01
    if existing ~= self.data.moonMultiplier then
        ModData.add(self.name, self.data)
        if isServer() then
            ModData.transmit(self.name)
        else
            self:updatePlayers()
        end
    end
end

function Core:getId(zedObj)
    if zedObj then
        if instanceof(zedObj, "IsoZombie") then
            if zedObj:isZombie() then
                if isClient() or isServer() then
                    return zedObj:getOnlineID()
                else
                    return zedObj:getID()
                end
            end
        end
    end
end
