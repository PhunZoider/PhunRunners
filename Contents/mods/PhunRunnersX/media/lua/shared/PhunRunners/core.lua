PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        createSprinter = "createSprinter",
        registerSprinter = "registerSprinter",
        unregisterSprinter = "unregisterSprinter"
    },
    ui = {},
    players = {},
    events = {
        OnSprinterDeath = "OnPhunRunnersSprinterDeath",
        OnPlayerStartSpawningSprinters = "OnPhunRunnersPlayerStartSpawningSprinters",
        OnPlayerStopSpawningSprinters = "OnPhunRunnersPlayerStopSpawningSprinters",
        OnPlayerRiskUpdate = "OnPhunRunnersPlayerRiskUpdate",
        OnPlayerEnvUpdate = "OnPhunRunnersPlayerEnvUpdate"
    },
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
        deferUnregistereSeconds = 240
    }
}

local Core = PhunRunners

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        -- load existing data
        self.data = ModData.getOrCreate(self.name)

        if isClient() then
            -- ask for any exceptions
            ModData.request(self.name)
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

