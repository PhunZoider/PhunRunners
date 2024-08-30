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

-- Player is eligible for sprinters to start, but indiviual settings may prevent it
function PhunRunners:startSprintersSound(playerObj)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_Start", false, 0):setVolume(vol);
end

function PhunRunners:stopSprintersSound(playerObj)
    local vol = (SandboxVars.PhunRunners.PhunRunnersVolume or 15) * .01
    getSoundManager():PlaySound("PhunRunners_End", false, 0):setVolume(vol);
end

function PhunRunners:normalSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
    zed:getModData().PhunRunners.sprinting = false
    zed:makeInactive(false);
end

function PhunRunners:sprintSpeed(zed)
    zed:makeInactive(true);
    sandboxOptions:set("ZombieLore.Speed", SPRINT)
    zed:getModData().PhunRunners.sprinting = true
    zed:makeInactive(false);
    sandboxOptions:set("ZombieLore.Speed", NORMAL)
end

local tickRate = 20

function PhunRunners:recalcOutfits()
    local total = 0
    local month = getGameTime():getMonth()
    local day = getGameTime():getDay()

    local items = {}

    if month == 11 then
        if day <= 27 then
            self.outfit = self.baseOutfits.christmas
        else
            self.outfit = self.baseOutfits.party
        end
    end

end

function PhunRunners:updateZed(zed)

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

    -- print(tostring(zData.id), tostring(zed:isSkeleton()), tostring(zed:getVisual():isSkeleton()))

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

local diffText = {"min", "low", "moderate", "high", "extreme"}

function PhunRunners:getSummary(playerObj)

    local risk = PhunRunners:getPlayerData(playerObj)
    local riskDesc = {}

    local grace = math.floor(risk.grace or 0)

    table.insert(riskDesc, getText("IGUI_PhunRunners_AreaRisk." .. diffText[(risk.difficulty or 0) + 1]))

    if grace > 1 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHours", grace) .. "\n")
    elseif grace > 0 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_IgnoringYouForAnotherXHour") .. "\n")
    end

    table.insert(riskDesc, getText("IGUI_PhunRunners_RiskLevel", math.floor(risk.risk + 0.5)))

    local riskd1 = table.concat(riskDesc, "\n")

    riskDesc = {}

    if risk.modifier and risk.modifier > 0 and risk.modifier < 100 then
        table.insert(riskDesc, getText("IGUI_PhunRunners_Modifier.darkness", tostring(math.floor(risk.modifier + 0.5))))
    end
    if PhunRunners.env and PhunRunners.env.moon.category and risk.moonMultiplier then

        if risk.moonMultiplier < 1 then
            table.insert(riskDesc,
                getText("IGUI_PhunRunners_RiskFromMoon", "-" .. math.floor(((1 - risk.moonMultiplier) * 100) + .05),
                    PhunRunners.env.moon.category))
        elseif risk.moonMultiplier > 1 then
            table.insert(riskDesc,
                getText("IGUI_PhunRunners_RiskFromMoon", "+" .. math.floor(((risk.moonMultiplier) * 100) + .05),
                    PhunRunners.env.moon.category))
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

    if #riskDesc > 0 then
        riskd1 = riskd1 .. "\n" .. getText("IGUI_PhunRunners_Modifiers") .. ":\n " .. table.concat(riskDesc, "\n ")
    end

    local results = {
        risk = risk.risk,
        spawnSprinters = risk.spawnSprinters == true,
        restless = risk.restless == true,
        title = risk.zone and risk.zone.title or "Wilderness",
        subtitle = risk.zone and risk.zone.subtitle or nil,
        description = riskd1

    }

    return results
end
