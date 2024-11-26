local PhunRunners = PhunRunners
local getOnlinePlayers = getOnlinePlayers
local sandbox = SandboxVars.PhunRunners
local slowInLightLevel = nil

local function getDistance(fromX, fromY, toX, toY)
    return math.sqrt((math.abs(fromX - toX)) ^ 2 + (math.abs(fromY - toY)) ^ 2)
end

function PhunRunners:getZedData(zed)

    if zed:isDead() then
        return
    end

    local data = zed:getModData()

    if data.brain then
        -- bandit
        return
    end

    local id = self:getId(zed)
    local reg = self.registry and self.registry[id]

    if data.PhunRunners == nil or data.PhunRunners.id ~= id or (data.PhunRunners.sprinter and reg == nil) then
        -- zed is not registered or it is being reused
        data.PhunRunners = {
            id = id
        }
    end

    local zData = data.PhunRunners

    if reg then
        -- in registry as a sprinter
        zData.sprinter = true
    end

    return zData

end

function PhunRunners:decorateZed(zed)

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

function PhunRunners:testPlayers(zed, zData)

    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        if p:isLocalPlayer() then

            local distance = getDistance(zed:getX(), zed:getY(), p:getX(), p:getY())
            if distance < 50 then

                local pData = self:getPlayerData(p)

                -- if p:getUsername() == "BBB" then
                --     pData.risk = 50
                --     -- pData.spawnSprinters = true
                -- else
                --     -- pData.risk = 20
                -- end

                if zData.sprinter == nil then
                    self:shouldSprint(zed, zData, pData)
                end

                if zData.sprinter and zed:getTarget() == p then
                    if pData.spawnSprinters then
                        self:adjustForLight(zed, zData, p)
                    elseif zData.sprinting then
                        self:normalSpeed(zed)
                    end
                end
            end
        end
    end

end

function PhunRunners:shouldSprint(zed, zData, playerData)
    zData.sprinter = false

    if playerData.risk > 0 then
        local risk = playerData.risk
        if playerData.modifier ~= 0 then
            -- adjust for modifier
            if playerData.modifier > 100 then
                playerData.modifier = 100
            end
            risk = risk * ((playerData.modifier or 0) * 0.01)
        end

        local rnd = ZombRand(100)
        if risk > 0 and rnd <= risk then
            self:registerSprinter(zData.id)
            zData.sprinter = true
        end
    end
end

function PhunRunners:adjustForLight(zed, zData, player)

    if slowInLightLevel == nil then
        slowInLightLevel = (sandbox.SlowInLightLevel or 74) * .01
    end

    local zsquare = zed:getCurrentSquare()

    local light = zsquare:getLightLevel(player:getPlayerNum())

    if zData.sprinting and light > slowInLightLevel then
        self:normalSpeed(zed)
    elseif not zData.sprinting and light < slowInLightLevel then
        self:sprintSpeed(zed)
    end
end

function PhunRunners:scream(zed, zData)

    zData.screamed = true
    local soundName = "PhunRunners_" .. ZombRand(1, 5)
    if not zed:getEmitter():isPlaying(soundName) then
        local vol = (SandboxVars.PhunRunners and SandboxVars.PhunRunners.PhunRunnersSprinterVolume or 25) * .01
        local soundEmitter = getWorld():getFreeEmitter()
        local hnd = soundEmitter:playSound(soundName, zed:getX(), zed:getY(), zed:getZ())
        soundEmitter:setVolume(hnd, vol)
    end

end
