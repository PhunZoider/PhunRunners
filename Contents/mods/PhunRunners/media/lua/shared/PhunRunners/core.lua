local Delay = require("PhunRunners/delay")
local sandbox = SandboxVars.PhunRunners

PhunRunners = {
    inied = false,
    name = "PhunRunners",
    commands = {
        createSprinter = "PhunRunnersCreateSprinter",
        registerSprinter = "PhunRunnersRegisterSprinter",
        unregisterSprinter = "PhunRunnersUnregisterSprinter"
    },
    ui = {},
    players = {},
    data = {},
    events = {
        OnSprinterDeath = "OnPhunRunnersSprinterDeath",
        OnPlayerStartSpawningSprinters = "OnPhunRunnersPlayerStartSpawningSprinters",
        OnPlayerStopSpawningSprinters = "OnPhunRunnersPlayerStopSpawningSprinters",
        OnPlayerRiskUpdate = "OnPhunRunnersPlayerRiskUpdate",
        OnPlayerEnvUpdate = "OnPhunRunnersPlayerEnvUpdate"
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
        deferUnregistereSeconds = 240
    }
}

local Core = PhunRunners
Core.settings = SandboxVars[Core.name] or {}

for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    if self.settings.debug then
        local args = {...}
        for i, v in ipairs(args) do
            if type(v) == "table" then
                self:printTable(v)
            else
                print(tostring(v))
            end
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

function Core:registerSprinter(zid, skipNotify)
    if not self.data[zid] then
        self.data[zid] = 1
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

function Core:unregisterSprinter(zid)
    if zid and self.data[zid] then
        self.data[zid] = nil
        -- TODO: What if this guy is still running around? If we see he is a skele, do we just re set him up to sprint?
        table.insert(self.pendingRemovals, zid)
    end
end

function Core:processUnregister()

    if #self.pendingRemovals > 0 then
        if isClient() then
            print("PhunRunenrs: Notify server of " .. #self.pendingRemovals .. " removal(s)")
            sendClientCommand(getPlayer(), self.name, self.commands.unregisterSprinter, {
                ids = self.pendingRemovals
            })
        elseif isServer() then
            print("PhunRunenrs: Notify clients of " .. (#self.pendingRemovals) .. " removal(s)")
            sendServerCommand(self.name, self.commands.unregisterSprinter, {
                ids = self.pendingRemovals
            })
        end
        self.pendingRemovals = {}
    end

    -- reset delay
    Delay:set(sandbox.DeferUnregistereSeconds or 30, function()
        PhunRunners:processUnregister()
    end, "processUnregister")
    -- TODO: Maybe just do every dawn?

end

