if isServer() then
    return
end
local PL = PhunLib
local Core = PhunRunners
local slowInLightLevel = nil

local function getDistance(fromX, fromY, toX, toY)
    return math.sqrt((math.abs(fromX - toX)) ^ 2 + (math.abs(fromY - toY)) ^ 2)
end

function Core:getZedData(zed)

    if zed:isDead() then
        return
    end

    local data = zed:getModData()

    if data.brain then
        -- bandit
        return
    end

    local id = self:getId(zed)
    -- local reg = self.data and self.data[id]
    if data[self.settings.VersionKey] == nil or data[self.settings.VersionKey].id ~= id or
        ((data[self.settings.VersionKey].exp or 0) < (self.delta or 0)) then
        -- zed is not registered or it is being reused

        if zed:isSkeleton() then
            zed:setSkeleton(false)
        end

        data[self.settings.VersionKey] = {
            exp = (self.delta or 0) + (self.settings.Exp or 300), -- dont test again for a good 5 mins or so
            id = id
        }

    end

    return data[self.settings.VersionKey]

end

function Core:decorateZed(zed)

    local visual = zed:getItemVisuals()
    local outfits = self.outfit

    if outfits == nil then
        return
    end

    local item = zed:isFemale() and outfits.female or outfits.male

    local parts = {}
    for i = 1, visual:size() - 1 do
        local item = visual:get(i)
        if not item then
            break
        end
        local bodyLocation = item:getScriptItem():getBodyLocation()

        parts[bodyLocation] = item
    end

    local doUpdate = false

    for k, v in pairs(item) do

        local garb = nil
        local garbs = nil
        if v.probability and (v.totalItemProbability or 0) > 0 and ZombRand(100) < v.probability then
            garbs = v.items
        end

        if garbs then
            local rnd = ZombRand(v.totalItemProbability)
            local total = 0
            for _, g in ipairs(garbs) do
                if g and g.probability > 0 then
                    total = total + g.probability
                    if rnd < total then
                        garb = g
                        break
                    end
                end
            end

            if garb then
                if parts[k] then
                    parts[k]:setItemType(garb.type)
                    doUpdate = true
                else
                    local iv = ItemVisual:new()
                    iv:setItemType(garb.type)
                    zed:getItemVisuals():add(iv)
                    doUpdate = true
                end

            end
        end

    end

    if doUpdate then
        zed:resetModel()
    end

end

function Core:testPlayers(zed, zData)

    local players = PL.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)

        local distance = getDistance(zed:getX(), zed:getY(), p:getX(), p:getY())
        if distance > 50 then
            return false
        end
        local pData = self:getPlayerData(p)

        if zData.sprinter == nil then
            zData.sprinter = self:shouldSprint(zed, zData, pData)
        end

        if zData.sprinter and zed:getTarget() == p then
            if pData.run then
                self:adjustForLight(zed, zData, p)
            elseif zData.sprinting then
                self:normalSpeed(zed)
            end
        end

    end

end

function Core:shouldSprint(zed, zData, playerData)

    if playerData.risk > 0 then
        local risk = playerData.risk
        return risk > 0 and ZombRand(100) <= risk
    end
    return false
end

function Core:adjustForLight(zed, zData, player)

    if slowInLightLevel == nil then
        slowInLightLevel = (self.settings.SlowInLightLevel or 74) * .01
    end

    local zsquare = zed:getCurrentSquare()

    local light = zsquare:getLightLevel(player:getPlayerNum())

    if zData.sprinting and light > slowInLightLevel then
        self:normalSpeed(zed)
    elseif not zData.sprinting and light < slowInLightLevel then
        self:sprintSpeed(zed)
    end
end

function Core:scream(zed, zData)

    zData.screamed = true
    local soundName = "PhunRunners_" .. ZombRand(5) + 1
    if not zed:getEmitter():isPlaying(soundName) then
        local vol = (self.settings.PhunRunnersSprinterVolume) or 15 * .01
        local soundEmitter = getWorld():getFreeEmitter()
        local hnd = soundEmitter:playSound(soundName, zed:getX(), zed:getY(), zed:getZ())
        soundEmitter:setVolume(hnd, vol)
    end

end
