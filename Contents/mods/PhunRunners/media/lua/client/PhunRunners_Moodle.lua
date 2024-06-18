if not isClient() then
    return
end
require "MF_ISMoodle"
local PhunRunners = PhunRunners
local MF = MF;
if MF then
    MF.createMoodle("PhunRunners");
end

function PhunRunners:updateMoodles()
    if not MF then
        return
    end
    for i = 0, getWorld():getPlayers():size() - 1 do
        local playerObj = getWorld():getPlayers():get(i)
        self:updateMoodle(playerObj)
    end
end

function PhunRunners:getSummary(playerObj)

    local playerNumber = playerObj:getPlayerNum()
    local currentData = getSpecificPlayer(playerNumber):getModData().PhunRunners
    if not currentData or not currentData.location then
        return
    end

    local riskTitle = currentData.location.title
    if currentData.location.subtitle then
        riskTitle = riskTitle .. " (" .. currentData.location.subtitle .. ")\n"
    else
        riskTitle = riskTitle .. "\n"
    end
    local riskDesc = "";
    if currentData.location and currentData.location.title then
        riskDesc = getText("IGUI_PhunRunners_RiskLevel", currentData.risk) .. "\n"
        riskDesc = riskDesc .. getText("IGUI_PhunRunners_RiskFromArea", currentData.difficulty) .. "\n"
        if currentData.moon > 1 then
            riskDesc = riskDesc .. getText("IGUI_PhunRunners_RiskFromMoon", (currentData.moon + 1) / 2) .. "\n"
        end
        if currentData.timeModifier then
            riskDesc = riskDesc .. getText("IGUI_PhunRunners_RiskFromTime", currentData.timeModifier.modifier) .. "\n"
        end
    end
    if currentData.spawnSprinters and self.doRun then
        riskDesc = riskDesc .. "\n" .. getText("IGUI_PhunRunners_ZedsAreRestless") .. "\n"
    else
        riskDesc = riskDesc .. "\n" .. getText("IGUI_PhunRunners_ZedsAreSettling") .. "\n"
    end

    return {
        title = riskTitle,
        description = riskDesc,
        spawnSprinters = currentData.spawnSprinters == true,
        risk = currentData.risk,
        difficulty = currentData.difficulty,
        restless = currentData.spawnSprinters and self.doRun
    }
end

-- shows/hides/updates the danger moodle for a player
-- Should be called whenever a player is updated
function PhunRunners:updateMoodle(playerObj)

    if not MF then
        return
    end

    local data = self:getSummary(playerObj)

    if not data then
        return
    end

    local playerNumber = playerObj:getPlayerNum()
    local moodle = MF.getMoodle(PhunRunners.name, playerObj:getPlayerNum())

    local riskTitle = data.title
    local riskDesc = data.description

    if data.risk < 1 then
        -- should really hide this?
        moodle:setTitle(2, 4, riskTitle)
        moodle:setDescription(2, 4, riskDesc)
        moodle:setPicture(2, 4, getTexture("media/ui/PhunRunners0.png"))
    elseif data.risk < 6 then
        moodle:setTitle(2, 4, riskTitle)
        moodle:setDescription(2, 4, riskDesc)
        moodle:setPicture(2, 4, getTexture("media/ui/PhunRunners1.png"))
    elseif data.risk < 16 then
        moodle:setTitle(2, 4, riskTitle)
        moodle:setDescription(2, 4, riskDesc)
        moodle:setPicture(2, 4, getTexture("media/ui/PhunRunners2.png"))
    elseif data.risk < 31 then
        moodle:setTitle(2, 4, riskTitle)
        moodle:setDescription(2, 4, riskDesc)
        moodle:setPicture(2, 4, getTexture("media/ui/PhunRunners3.png"))
    else
        moodle:setTitle(2, 4, riskTitle)
        moodle:setDescription(2, 4, riskDesc)
        moodle:setPicture(2, 4, getTexture("media/ui/PhunRunners4.png"))
    end

    moodle:setThresholds(.01, nil, nil, nil, nil, nil, nil, nil)
    moodle:setValue(data.risk - 100)

    if self.doRun then
        moodle:activate()
    else
        moodle:suspend()
    end
end
