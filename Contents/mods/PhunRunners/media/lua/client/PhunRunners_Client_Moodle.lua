if not isClient() then
    return
end
require "MF_ISMoodle"
local MF = MF;
if MF then
    local PhunRunners = PhunRunners
    local inied = false
    MF.createMoodle("PhunRunners");
    local moodle = nil

    local function iniMoodle()
        moodle = MF.getMoodle("PhunRunners")
        -- 0 = neutral 1 = good, 2 = bad
        -- moodle level = 1-4

        -- moodle:setPicture(0, 1, getTexture("media/textures/phunrunners_icon.png"))
        -- moodle:setPicture(0, 2, getTexture("media/textures/phunrunners_icon.png"))
        -- moodle:setPicture(0, 3, getTexture("media/textures/phunrunners_icon.png"))
        -- moodle:setPicture(0, 4, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(1, 1, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(1, 2, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(1, 3, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(1, 4, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(2, 1, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(2, 2, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(2, 3, getTexture("media/textures/phunrunners_icon.png"))
        moodle:setPicture(2, 4, getTexture("media/textures/phunrunners_icon.png"))

    end

    function PhunRunners:updateMoodles()
        if moodle == nil then
            iniMoodle()
        end
        for i = 0, getWorld():getPlayers():size() - 1 do
            local playerObj = getWorld():getPlayers():get(i)
            if playerObj:isLocalPlayer() then
                self:updateMoodle(playerObj)
            end
        end
    end

    -- shows/hides/updates the danger moodle for a player
    -- Should be called whenever a player is updated
    function PhunRunners:updateMoodle(playerObj)

        if moodle == nil then
            iniMoodle()
        end

        local playerNumber = playerObj:getPlayerNum()
        local moodle = MF.getMoodle(PhunRunners.name, playerObj:getPlayerNum())

        if not SandboxVars.PhunRunners.ShowMoodle then
            moodle:suspend()
            return
        end
        local data = self:getSummary(playerObj)

        if not data then
            return
        end

        -- local t = getTexture("media/textures/phunrunners_icon.png")
        -- moodle:setPicture(2, 4, t)
        local riskTitle = data.title
        local riskDesc = data.description
        for t = 1, 2 do
            for i = 1, 4 do
                moodle:setTitle(2, 4, riskTitle)
                moodle:setDescription(2, 4, riskDesc)
            end
        end

        -- local riskTitle = data.title
        -- local riskDesc = data.description

        -- moodle:setTitle(2, 4, riskTitle)
        -- moodle:setDescription(2, 4, riskDesc)

        -- moodle:setThresholds(10, 20, 30, 40, 50, 60, 70, 80, 90)
        moodle:setValue((100 - data.risk) * 0.01)

        -- if self.doRun then
        --     moodle:activate()
        -- else
        --     moodle:suspend()
        -- end
    end

end
