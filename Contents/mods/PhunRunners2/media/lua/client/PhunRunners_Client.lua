if isServer() then
    return
end
local PhunRunners = PhunRunners
local PhunZones = PhunZones
local PhunStats = PhunStats
local sandbox = SandboxVars.PhunRunners
local sandboxOptions = getSandboxOptions()
local world = getWorld()

local SPRINT = 1
local NORMAL = 2

function PhunRunners:sprintSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", SPRINT)
    zed:makeInactive(false);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
end

-- Player is eligible for sprinters to start, but indiviual settings may prevent it
function PhunRunners:startSprintersSound(playerObj)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
end

function PhunRunners:stopSprintersSound(playerObj)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
end

function PhunRunners:makeSprint(zed)
    self:sprintSpeed(zed)
    local soundName = "PhunRunners_" .. ZombRand(1, 5)
    zed:getModData().PhunRunners = {
        sprinting = true
    }
    triggerEvent(self.events.OnSprinterSpottedPlayer, zed)
    if zed:getEmitter():isPlaying(soundName) then
        return
    end

    local vol = (SandboxVars.PhunRunners and SandboxVars.PhunRunners.PhunRunnersSprinterVolume or 25) * .01
    local soundEmitter = getWorld():getFreeEmitter()
    local hnd = soundEmitter:playSound(soundName, zed:getX(), zed:getY(), zed:getZ())
    soundEmitter:setVolume(hnd, vol)

end

function PhunRunners:normalSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
    zed:makeInactive(false);
end

function PhunRunners:makeNormal(zed)
    print("makeNormal")
    self:normalSpeed(zed)
    zed:getModData().PhunRunners = nil
end
local ids = {}
local banditsIntegration = nil

function PhunRunners:updateZed(zed)

    if banditsIntegration == nil then
        banditsIntegration = getActivatedMods():contains("Bandits")
    end

    if banditsIntegration == true then
        local data = zed:getModData()
        if data and data.brain then
            -- this is a bandit
            return
        end
    end

    local id = tostring(zed:getOnlineID())

    local player = zed:getTarget()

    if player == nil or instanceof(player, "IsoPlayer") == false or not player:isLocalPlayer() then
        return
    end

    -- get zed modData
    if zed:getModData().PhunRunners == nil then

        -- player could have just logged, so need to test if the zed is already sprinter?

        zed:getModData().PhunRunners = {
            ticks = 0
        }
    end
    local zData = zed:getModData().PhunRunners

    -- only check every so x ticks
    if zData.ticks == nil or (zData.ticks > 0 and zData.ticks < self.settings.tickDeffer) then
        zData.ticks = (zData.ticks or 0) + 1
        return
    end

    -- reset ticks
    zData.ticks = 1

    local playerData = self:getPlayerData(player)

    if playerData.spawnSprinters and playerData.modifier > 0 and playerData.risk > 0 then

        -- if zData.modifier ~= playerData.modifier and zData.sprinting ~= true then
        --     if (zData.modifier or 0) > 0 and (zData.modifier or 0) < 100 and playerData.modifier > 0 then
        --         self:makeNormal(zed)
        --         zData.sprinting = nil
        --     end
        -- end
        zData.modifier = playerData.modifier

        if zData.sprinting == true then

            if self.settings.slowInLight > 0 then
                local zsquare = zed:getCurrentSquare()
                local light = zsquare:getLightLevel(player:getPlayerNum())

                if not zData.lightSupressed and light > self.settings.slowInLight then
                    -- its too bright, make them walk
                    print(string.format("its too bright: %.2f/%.2f, make them walk ", light, self.settings.slowInLight))
                    self:normalSpeed(zed)
                    zData.lightSupressed = true
                elseif zData.lightSupressed and light < self.settings.slowInLight then
                    -- its dark enough, make them run
                    print(string.format("its too dark: %.2f/%.2f, make them run ", light, self.settings.slowInLight))
                    self:sprintSpeed(zed)
                    zData.lightSupressed = false
                end
            end

            -- any other logic to revert them

        elseif zData.sprinting == nil then

            -- we haven't tested this zed yet
            zData.sprinting = false
            -- zData.location = PhunZones:getLocation(zed)
            if playerData.risk > 0 then
                local risk = playerData.risk * ((playerData.modifier or 0) * 0.01)
                print("risk is ", tostring(risk), " vs ", tostring(playerData.risk), " with modifier of ",
                    tostring(playerData.modifier))
                if risk > 0 and ZombRand(100) <= playerData.risk then
                    self:makeSprint(zed)
                end
            end
        end
    else
        if zData.sprinting == true then
            self:makeNormal(zed)
            zData.sprinting = false
        end
        zData = {
            ticks = 1
        }
    end
end

local diffText = {"minimal risk", "low risk", "moderate risk", "high risk", "extreme risk"}

function PhunRunners:getSummary(playerObj)

    local risk = PhunRunners:getPlayerData(playerObj)
    local riskDesc = {}

    local grace = math.floor(risk.grace or 0)

    if grace > 1 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHours", grace) .. "\n")
    elseif grace > 0 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHour") .. "\n")
    end

    table.insert(riskDesc, getText("IGUI_PhunRunners_RiskLevel", risk.risk))
    table.insert(riskDesc, "Area is " .. diffText[(risk.difficulty or 0) + 1])
    if risk.modifier and risk.modifier > 0 and risk.modifier < 100 then
        table.insert(riskDesc, "Darkness modifier: " .. tostring(risk.modifier))
    end
    if (risk.moonMultiplier or 0) > 1 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_RiskFromMoon", risk.moonMultiplier))
    end

    table.insert(riskDesc, "\n")

    if risk.modifier and risk.modifier > 0 then

        if risk.modifier >= 100 then
            table.insert(riskDesc, "Zombies are rabid")
        else
            table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreRestless"))
        end
        -- if risk.risk == 0 then
        --     table.insert(riskDesc, "But sprinters seem to be ignoring you")
        -- end
    else
        table.insert(riskDesc, getText("IGUI_PhunRunners_ZedsAreSettling"))
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
