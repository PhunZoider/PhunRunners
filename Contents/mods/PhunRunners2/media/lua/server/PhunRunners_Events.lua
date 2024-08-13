local PhunRunners = PhunRunners

local fieldsThatTriggerChange = {"lightRiskCategory", "lightRiskValue", "fogRiskCategory", "fogRiskValue",
                                 "moonRiskValue"}

if isClient() then

    local function setup()
        Events.EveryOneMinute.Remove(setup)

        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i)
            if player:isLocalPlayer() and isAdmin() then
                local window = PhunRunnersWidget.OnOpenPanel(player)
                if not window:isVisible() then
                    window:setVisible(true)
                end
            end
        end
    end
    Events.EveryOneMinute.Add(setup)

    Events.EveryOneMinute.Add(function()
        PhunRunners:updateEnvironment()
        PhunRunners:updatePlayers()
    end)

    Events.OnZombieUpdate.Add(function(zed)
        PhunRunners:updateZed(zed)
    end);

    -- Events.OnPlayerDeath.Add(function(playerObj)
    --     local data = PhunRunners:getPlayerData(playerObj)
    --     data = {}
    -- end)

    -- Events.OnZombieUpdate.Add(function(z)
    --     PhunRunners:updateZed(z)
    -- end);
else
    local ids = {}
    Events.OnZombieUpdate.Add(function(zed)
        if not ids[zed:getUID()] then
            ids[zed:getUID()] = true
            print(zed:getUID())
        end

    end);
end

Events.OnZombieDead.Add(function(zed)
    local data = zed:getModData()
    if data then
        PhunTools:debug("zed", data)
        local sprinter = false
        if data.PhunRunners then
            if data.PhunRunners.sprinting then
                sprinter = true
                triggerEvent(PhunRunners.events.OnPhunRunnersZedDied, zed)
            end
        end
        print(((sprinter == true and "Sprinter") or "Zed") .. " died ", tostring(zed:getOnlineID()), " ", zed:getUID())
    end
    -- PhunRunners.zeds[tostring(zed:getOnlineID())] = nil
end);

Events.OnInitGlobalModData.Add(function()
    -- local s = "\n-- EVENTS --\n"
    -- for k, _ in pairs(Events) do
    --     s = s .. k .. "\n "
    -- end
    -- print(s)
end)

-- Events.EveryTenMinutes.Add(function()

--     print("EveryTenMinutes")
--     for i = 0, getOnlinePlayers():size() - 1 do
--         local player = getOnlinePlayers():get(i)
--         print("player ", tostring(player))
--         local list = player:getCell()
--         print(player:getUsername(), " ", tostring(list:getMinX()), " ", tostring(list:getMinY()))
--         -- print("list ", tostring(list:size()))
--         -- for j = 0, list:size() - 1 do
--         --     local zed = list:get(j)
--         --     print("enemty ", tostring(zed))
--         -- end
--     end

--     -- local zombies = cell:getZombieList()
--     -- if not zombies then return end

--     -- for i=0, zombies:size()-1 do
--     --     ---@type IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
--     --     local zombie = zombies:get(i)
--     --     if zombie:getOnlineID()==ID then return zombie end
--     -- end
-- end)
