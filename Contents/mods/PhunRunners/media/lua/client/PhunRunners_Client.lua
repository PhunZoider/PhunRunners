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

function PhunRunners:makeSprint(zed)
    self:sprintSpeed(zed)
    local soundName = "PhunRunners_" .. ZombRand(1, 6)
    zed:getModData().PhunRunners = {
        sprinting = true
    }

    triggerEvent(self.events.OnSprinterSpottedPlayer, zed)
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
function PhunRunners:updateZed(zed)

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

    if playerData.spawnSprinters then
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
                if ZombRand(100) <= playerData.risk then
                    self:makeSprint(zed)
                    zData.sprinting = true
                end
            end
        end
    else
        if zData.sprinting == true then
            self:makeNormal(zed)
            zData.sprinting = false
        end
        zData.PhunRunners = {
            ticks = 1
        }
    end
end
