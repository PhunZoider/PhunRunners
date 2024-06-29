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

-- shows/hides/updates the danger moodle for a player
-- Should be called whenever a player is updated
function PhunRunners:updateMoodle(playerObj)

    if not MF then
        return
    end

    local playerNumber = playerObj:getPlayerNum()
    local moodle = MF.getMoodle(PhunRunners.name, playerObj:getPlayerNum())

    if not SandboxVars.PhunRunnersShowMoodle then
        moodle:suspend()
        return
    end
    local data = self:getSummary(playerObj)

    if not data then
        return
    end

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
