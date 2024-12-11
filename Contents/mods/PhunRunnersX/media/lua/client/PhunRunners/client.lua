if isServer() then
    return
end
local PR = PhunRunners
local PhunStats = PhunStats
local sandbox = SandboxVars.PhunRunners
local sandboxOptions = getSandboxOptions()
local world = getWorld()
local tickRate = sandbox.TickRate or 20
local SPRINT = 1
local NORMAL = 2
local diffText = {"min", "low", "moderate", "high", "extreme"}

-- Player is eligible for sprinters to start, but indiviual settings may prevent it
function PR:startSprintersSound(playerObj)
    local vol = (sandbox.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
end

function PR:stopSprintersSound(playerObj)
    local vol = (sandbox.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
end

function PR:normalSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
    zed:getModData().PhunRunners.sprinting = false
    zed:makeInactive(false);
end

function PR:sprintSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", SPRINT)
    zed:getModData().PhunRunners.sprinting = true
    zed:makeInactive(false);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
end

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
        self:testPlayers(zed, zData)
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

function PR:updateEnvironment()

    if self.env == nil then
        -- caches the current environment
        self.env = self:getEnvironment(true)
        return
    end

    local climate = getClimateManager()
    local lightIntensity = climate:getDayLightStrength()
    local fogIntensity = climate:getFogIntensity()

    if self.env.light == lightIntensity and self.env.fog == fogIntensity then
        -- no material change to env
        return
    end

    -- caches the current environment
    self.env = self:getEnvironment()
    return self.env

end

function PR:getEnvironment(refresh)

    if not refresh and self.env then
        return self.env
    end

    local climate = getClimateManager()

    -- get daylight intensity
    local lightIntensity = math.max(0, math.floor((climate:getDayLightStrength() * 100) + 0.5))
    -- get fog intensity
    local fogIntensity = math.floor((climate:getFogIntensity() * 100) + 0.5)

    -- adjust daylight intensity by fog intensity
    local adjustedLightIntensity = lightIntensity; --  math.max(0, lightIntensity - (lightIntensity * (fogIntensity * 0.01)))
    if fogIntensity > 0 then
        adjustedLightIntensity = math.max(0, lightIntensity - (lightIntensity * climate:getFogIntensity()))
    end

    -- get current moon phase
    local moonPhase = getClimateMoon():getCurrentMoonPhase()

    return {
        value = adjustedLightIntensity,
        light = lightIntensity,
        fog = fogIntensity,
        moon = getClimateMoon():getCurrentMoonPhase()
    }

end

function PR:printTable(t)
    if PhunTools then
        PhunTools:printTable(t)
    else
        print("PhunRunners:printTable: ", t)
    end
end

local modifiers = {
    inied = false,
    hours = nil,
    sprinters = nil,
    difficulty = nil,
    moon = nil
}

local phunStats = nil

function PR:updatePlayer(playerObj)

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

        self:printTable(modifiers)
    end

    if not playerObj or not playerObj:isLocalPlayer() then
        return
    end

    local name = playerObj:getUsername()
    local playerData = self:getPlayerData(name)
    local env = self:getEnvironment(true)

    if phunStats == nil then
        phunStats = PhunStats
    else
        phunStats = PhunStats or false
    end

    local pData = playerObj:getModData()

    local zone = pData.PhunRunnersZone or {
        difficulty = 0
    }

    local pstats = phunStats and phunStats:getData(name) or {
        current = {
            hours = playerObj:getHoursSurvived(),
            kills = pData.kills or 0,
            sprinterKills = pData.sprinterKills or 0
        },
        totals = {
            hours = playerObj:getHoursSurvived() + (pData.hours or 0),
            kills = pData.totalKills or 0,
            sprinterKills = pData.totalKills or 0
        }
    }

    local zoneDifficulty = zone.difficulty or 1
    local charHours = pstats.current.hours or 0
    local hours = (pstats.total.hours or 0) + charHours
    local totalKills = pstats.total.kills or 0
    local totalSprinters = pstats.total.sprinters or 0

    local gHours = sandbox or 1
    local gTotalHours = sandbox or 24
    local inGrace = charHours < gHours or hours < gTotalHours
    -- print("Player ", name, " is in grace: ", inGrace, " charHours: ", charHours, " hours: ", hours, " gHours: ", gHours,
    --     " gTotalHours: ", gTotalHours)
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
            if hours > k then
                sprinterKillRisk = v
                break
            end
        end
    end

    -- zoneDifficulty = modifiers and zoneDifficulty and zoneDifficulty > 0 and modifiers.difficulty and
    --                      modifiers.difficulty[zoneDifficulty] or 0
    local mods = modifiers
    local m = env.moon
    moonPhaseModifierValue = (mods and mods.moon and mods.moon[m] or 100) * .01
    -- print("Moon phase: ", m, " modifier: ", moonPhaseModifierValue)
    -- moonPhaseModifierValue = (modifiers and env and env.mooon and env.moon and modifiers.moon[env.moon] or 100) * .01
    local totalRisk = math.min(100, (zoneRisk + timerRisk + sprinterKillRisk) * moonPhaseModifierValue)
    local sb = sandbox

    if env.value > sb.SlowInLightLevel then
        -- too bright for sprinters (green)
        lightModifier = 0
    elseif env.value < sb.DarknessLevel then
        -- dark enough for sprinters (red)
        lightModifier = 100
    else
        -- somewhere in between (yellow)
        lightModifier = ((sb.SlowInLightLevel - sb.DarknessLevel) / (env.value - sb.DarknessLevel)) * 100
    end

    local graceHours = math.max(0, math.max((gHours or 1) - charHours, (gTotalHours or 24) - hours))
    local pd = {
        zone = zone,
        risk = totalRisk,
        modifier = lightModifier,
        env = env,
        spawnSprinters = lightModifier > 0 and graceHours == 0 and totalRisk > 0,
        restless = env.value > 30,
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

    if self.updateMoodle then
        self:updateMoodle(playerObj)
    end

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

function PR:getSummary(playerObj)

    local risk = PR:getPlayerData(playerObj)
    local riskDesc = {}
    local riskModifiers = {}

    local grace = math.floor(risk.grace or 0)

    local diffSuffix = "extreme"

    if diffText[tonumber((risk.difficulty or 0)) + 1] then
        diffSuffix = diffText[tonumber((risk.difficulty or 0)) + 1]
    end

    table.insert(riskDesc, getText("IGUI_PhunRunners_AreaRisk." .. diffSuffix))

    if grace > 1 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHours", grace) .. "\n")
    elseif grace > 0 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHour") .. "\n")
    end

    table.insert(riskDesc, getText("IGUI_PhunRunners_RiskLevel", math.floor(risk.risk + 0.5)))

    if risk.modifier and risk.modifier > 0 and risk.modifier < 100 then
        table.insert(riskModifiers,
            getText("IGUI_PhunRunners_Modifier.darkness", tostring(math.floor(risk.modifier + 0.5))))
    end

    if PR.env and PR.env.moon and risk.moonMultiplier then

        if risk.moonMultiplier < 1 then
            table.insert(riskDesc,
                getText("IGUI_PhunRunners_RiskFromMoon", "-" .. math.floor(((1 - risk.moonMultiplier) * 100) + .05),
                    getText("IGUI_PhunRunners_MoonPhase" .. PR.env.moon + 1)))
        elseif risk.moonMultiplier > 1 then
            table.insert(riskDesc,
                getText("IGUI_PhunRunners_RiskFromMoon", "+" .. math.floor(((risk.moonMultiplier) * 100) + .05),
                    getText("IGUI_PhunRunners_MoonPhase" .. PR.env.moon + 1)))
        end
    end

    if #riskModifiers > 0 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_Modifiers"))
        for _, v in ipairs(riskModifiers) do
            table.insert(riskDesc, " " .. v)
        end
    end

    if risk.modifier and risk.modifier > 0 then
        table.insert(riskDesc, "\n")
        if risk.modifier >= 100 then
            table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreRabid"))
        else
            table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreRestless"))
        end
    else
        table.insert(riskDesc, "\n" .. getText("IGUI_PhunRunners_ZedsAreSettling"))
    end

    local results = {
        risk = risk.risk,
        spawnSprinters = risk.spawnSprinters == true,
        restless = risk.restless == true,
        title = risk.zone and risk.zone.title or "Wilderness",
        subtitle = risk.zone and risk.zone.subtitle or nil,
        description = table.concat(riskDesc, "\n")

    }

    return results
end
