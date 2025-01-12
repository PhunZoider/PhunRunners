if isClient() then
    return
end

local PR = PhunRunners

function PR:updateEnv()

    local climate = getClimateManager()

    local lastAdjustedLightIntensity = self.data and self.data.value or nil
    local oldRun = self.data and self.data.run or nil

    -- get daylight intensity
    local lightIntensity = math.max(0, math.floor((climate:getDayLightStrength() * 100) + 0.5))
    -- get fog intensity
    local fogIntensity = math.floor((climate:getFogIntensity() * 100) + 0.5)
    -- adjust daylight intensity by fog intensity
    local adjustedLightIntensity = lightIntensity;

    if fogIntensity > 0 then
        -- adjust for fog
        adjustedLightIntensity = math.max(0, lightIntensity - (lightIntensity * climate:getFogIntensity()))
    end

    local time = getGameTime():getTimeOfDay()

    self.data.value = adjustedLightIntensity
    self.data.light = lightIntensity
    self.data.fog = fogIntensity
    self.data.run = time > (self.data.duskTime or 0) or time < (self.data.dawnTime or 0)
    self.data.dimness = (self.settings.SlowInLightLevel - self.settings.DarknessLevel)
    local dimness = 0
    if adjustedLightIntensity <= self.settings.DarknessLevel then
        dimness = 1
    elseif adjustedLightIntensity < self.settings.SlowInLightLevel then
        dimness = (adjustedLightIntensity - self.settings.DarknessLevel) /
                      (self.settings.SlowInLightLevel - self.settings.DarknessLevel)

    end
    self.data.dimness = dimness

    if lastAdjustedLightIntensity ~= adjustedLightIntensity or oldRun ~= self.data.run then
        if isServer() then
            ModData.transmit(self.name)
        else
            self:updatePlayers()
        end
    end
end
