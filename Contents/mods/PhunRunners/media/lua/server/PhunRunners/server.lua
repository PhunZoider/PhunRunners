if isClient() then
    return
end

local PR = PhunRunners

local climateManager
local gt
local duskTime
local dawnTime
local lastTime = 0
local isNight = nil
local updateFields = {"value", "light", "restless", "fog"}
function PR:updateEnv()

    local climate = getClimateManager()
    local season = climateManager:getSeason()

    local lastAdjustedLightIntensity = self.env and self.env.value or 0

    local lastMoon = self.env and self.env.moon or 0
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

    local time = getGameTime():getTimeOfDay()

    local env = {
        value = adjustedLightIntensity,
        light = lightIntensity,
        fog = fogIntensity,
        moon = getClimateMoon():getCurrentMoonPhase(),
        dawnTime = season:getDawn(),
        duskTime = season:getDusk(),
        restless = time > season:getDusk() or time < season:getDawn()
    }

    local notify = false
    for _, v in ipairs(updateFields) do
        if self.env[v] ~= env[v] then
            notify = true
            break
        end
    end
    self.env = env
    if notify then
        sendServerCommand(PR.name, PR.commands.stateChange, self.env)
    end

end

-- hmm, I think we are trying to reset all zeds in playerless chunks?
function PR:clean()

    local cells = {}
    local ids = {}

    local sids = {}
    local tids = {}
    local players = self:onlinePlayers(true)
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        local cell = p:getCell()
        local cellKey = tostring(cell:getWorldX()) .. "_" .. tostring(cell:getWorldY())
        if not cells[cellKey] then
            cells[cellKey] = true
            local list = p:getCell():getZombieList();
            if list ~= nil then
                for j = 0, list:size() - 1 do
                    local zed = list:get(j)
                    local id = self:getId(zed)
                    if self.data[id] then
                        ids[id] = true
                    end
                end
            end
        end
    end

    -- TODO: Don't think this is doing what we think it is doing. 
    -- Can we get zedids of those not in same cell as a player and reset that way?

    local changed = 0
    for k, v in pairs(self.data) do
        if not ids[k] then
            changed = changed + 1
            self:unregisterSprinter(k, true)
        end
    end

    if changed > 0 then
        ModData.transmit(self.name)
    end

end
