if isServer() then
    return
end
local Core = PhunRunners
local PhunStats = PhunStats
local PhunZones = PhunZones
local PL = PhunLib
local sandboxOptions = getSandboxOptions()
local world = getWorld()
local tickRate = Core.settings.TickRate or 20
local SPRINT = 1
local NORMAL = 2
local diffText = {"min", "low", "moderate", "high", "extreme"}

-- Trigger audio notification that sprinters will start running
function Core:startSprintersSound(playerObj)
    local vol = (self.settings.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
end

-- Trigger audio notification that sprinters will stop running
function Core:stopSprintersSound(playerObj)
    local vol = (self.settings.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
end

-- Make zed return to normal speed
function Core:normalSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
    zed:getModData().PhunRunners.sprinting = false
    zed:makeInactive(false);
end

-- Make zed run at sprint speed
function Core:sprintSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", SPRINT)
    zed:getModData().PhunRunners.sprinting = true
    zed:makeInactive(false);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
end

-- configure any themed outfits
function Core:recalcOutfits()
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

function Core:updateZed(zed)

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
    if zData.tick ~= nil and zData.tick < self.settings.TickRate then
        zData.tick = zData.tick + 1
        return
    end
    zData.tick = 1

    if zData.sprinter ~= false then
        if self:testPlayers(zed, zData) == false then
            -- out of sight of all players?
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

function Core:showWidgets()
    local players = PL.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if not self.settings.ShowMoodle then
            self:showWidget(p)
        end

    end
end

function Core:showWidget(playerObj)
    self.ui.widget.OnOpenPanel(playerObj)
end

function Core:reloadWidget(playerObj)
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

function Core:resetModifiers()
    modifiers.inied = false
end

function Core:getModifiers()
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
    return modifiers
end

-- update local db with players risk shit
function Core:updatePlayer(playerObj, zone)

    if not playerObj or not playerObj:isLocalPlayer() then
        return
    end

    local name = playerObj:getUsername()
    local modData = playerObj:getModData()
    if not modData.PhunRunners then
        modData.PhunRunners = {}
    end
    local modifiers = self:getModifiers()
    local playerData = self:getPlayerData(playerObj)
    local env = self.data
    zone = PhunZones:getPlayerData(name)

    local hoursSurvived = playerObj:getHoursSurvived()
    local pstats = PhunStats and PhunStats:getData(name) or {
        current = {
            hours = hoursSurvived or 0
        },
        total = {
            hours = hoursSurvived or 0
        }
    }

    local zoneDifficulty = zone.difficulty or 1

    local charHours = pstats.current.hours or hoursSurvived
    local hours = pstats.total.hours or hoursSurvived
    local totalKills = pstats.total.zombieKills or 0
    local totalSprinters = pstats.total.sprinterKills or 0

    local gHours = self.settings.GraceHours or 1
    local gTotalHours = self.settings.GraceTotalHours or 24
    local inGrace = charHours < gHours or hours < gTotalHours
    local sprinterKillRisk = 0
    local timerRisk = 0

    local zoneRisk = modifiers.difficulty[zoneDifficulty + 1] or 0
    local lightModifier = 0

    local mods = self:getModifiers()
    if mods and mods.hours then
        for k, v in pairs(mods.hours) do
            if hours > k then
                timerRisk = v
                break
            end
        end
    end

    if mods and mods.sprinters then
        for k, v in pairs(mods.sprinters) do
            if totalSprinters >= k then
                sprinterKillRisk = v
                break
            end
        end
    end

    local totalRisk = math.min(100, (zoneRisk + timerRisk + sprinterKillRisk) * (self.data.moonMultiplier or 1))

    local graceHours = math.max(0, math.max((gHours or 1) - charHours, (gTotalHours or 24) - hours))
    local pd = {
        hours = charHours,
        totalHours = hours,
        totalKills = totalKills,
        totalSprinters = totalSprinters,
        risk = totalRisk,
        -- spawnSprinters = self.data.dimness > 0 and graceHours == 0 and totalRisk > 0,
        create = graceHours == 0 and totalRisk > 0,
        run = self.data.run == true and graceHours == 0 and totalRisk > 0,
        difficulty = zoneDifficulty,
        zoneRisk = zoneRisk,
        timerRisk = timerRisk,
        sprinterKillRisk = sprinterKillRisk,
        grace = graceHours
    }

    if zoneDifficulty == 0 or inGrace then
        pd.risk = 0
        -- pd.restless = false
        pd.run = false
        pd.create = false
    end

    local oldRun = playerData.run
    local oldRisk = playerData.risk

    local zoneChanged = false
    local moonChanged = false

    if playerData.zone then
        if playerData.zone.region ~= zone.region or playerData.zone.zone ~= zone.zone then
            zoneChanged = true
        end
    end

    self.players[name] = pd
    modData.PhunRunners = pd

    if pd.run ~= oldRun then
        if pd.run then
            print("Player ", name, " is now spawning sprinters")
            triggerEvent(Core.events.OnPlayerStartSpawningSprinters, playerObj)
            self:startSprintersSound(playerObj)
        else
            print("Player ", name, " is no longer spawning sprinters")
            triggerEvent(Core.events.OnPlayerStopSpawningSprinters, playerObj)
            self:stopSprintersSound(playerObj)
        end
    end

    if pd.risk ~= oldRisk or zoneChanged or pd.run ~= oldRun then
        if pd.risk ~= oldRisk then
            pd.oldRisk = oldRisk
            pd.riskChanged = getGameTime():getWorldAgeHours()
        end
        triggerEvent(Core.events.OnPlayerRiskUpdate, playerObj, pd)

    end
    Core.moodles:update(playerObj, pd)
    return pd

end

function Core:getPlayerData(playerObj)
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

function Core:updatePlayers()
    local players = PL.onlinePlayers()
    for i = 1, players:size() do
        local p = players:get(i - 1)
        self:updatePlayer(p)
    end
end
