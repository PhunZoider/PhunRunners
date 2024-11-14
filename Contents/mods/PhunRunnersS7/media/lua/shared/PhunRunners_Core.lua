PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        createSprinter = "createSprinter",
        registerSprinter = "registerSprinter",
        unregisterSprinter = "unregisterSprinter"
    },
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
    outfit = nil
}

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:registerSprinter(zid, skipNotify)
    if zid and self.registry and not self.registry[zid] then
        self.registry[zid] = getGameTime():getWorldAgeHours()

        if isClient() and not skipNotify then
            local p = getPlayer()
            -- tell server (and all other players) about this sprinter
            sendClientCommand(p, self.name, self.commands.registerSprinter, {
                id = zid
            })
        elseif isServer() then
            -- tell others about this sprinter
            sendServerCommand(self.name, self.commands.registerSprinter, {
                id = zid
            })
        end
    end
end

function PhunRunners:unregisterSprinter(zid, skipNotify)
    if zid and self.registry[zid] then
        self.registry[zid] = nil
        if isClient() and not skipNotify then
            -- tell server (and all other players) to forget about this sprinter
            sendClientCommand(getPlayer(), self.name, self.commands.unregisterSprinter, {
                id = zid
            })
        elseif isServer() and not skipNotify then
            -- tell others to forget about this sprinter
            sendServerCommand(self.name, self.commands.unregisterSprinter, {
                id = zid
            })
        end
    end
end

function PhunRunners:init()
    if not self.inied then
        self.inied = true
        ModData.add(self.name, {})
        self.registry = ModData.getOrCreate(self.name)
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

function PhunRunners:debug(...)
    if PhunTools then
        PhunTools:debug(...)
    else
        print(...)
    end
end

