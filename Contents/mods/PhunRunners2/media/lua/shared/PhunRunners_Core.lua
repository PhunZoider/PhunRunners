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

for _, event in pairs(PhunRunners.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRunners:registerSprinter(zid, skipNotify)
    if zid and not self.registry[zid] then
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

function PhunRunners:debug(...)
    if PhunTools then
        PhunTools:debug(...)
    else
        print(...)
    end
end

