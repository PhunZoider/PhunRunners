if not isClient() then
    return
end

local PhunRunners = PhunRunners
local getOnlinePlayers = getOnlinePlayers
local iniedPhunStats = false
local iniedPhunZones = false

if PhunZones then
    Events[PhunZones.events.OnPhunZoneReady].Add(function()
        if not iniedPhunZones then
            iniedPhunZones = true
            if iniedPhunStats then
                PhunRunners:updateEnvironment()
                PhunRunners:updatePlayers()
                PhunRunners:recalcOutfits()
            end
        end
    end)

    Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
        PhunRunners:updatePlayer(playerObj, zone)
    end)
end

if PhunStats then
    Events[PhunStats.events.OnPhunStatsClientReady].Add(function()

        if not iniedPhunStats then
            iniedPhunStats = true
            if iniedPhunZones then
                PhunRunners:updateEnvironment()
                PhunRunners:updatePlayers()
                PhunRunners:recalcOutfits()
            end
        end
    end)
end

local function setup()
    Events.OnTick.Remove(setup)
    PhunRunners:init()
    ModData.request(PhunRunners.name)
    PhunRunners:updateEnvironment()
    PhunRunners:updatePlayers()
    PhunRunners:recalcOutfits()
end
Events.OnTick.Add(setup)

Events.EveryOneMinute.Add(function()
    PhunRunners:updateEnvironment()
    PhunRunners:updatePlayers()
    PhunRunners:recalcOutfits()
end)

Events.OnDawn.Add(function()
    PhunRunners:recalcOutfits()
end)

Events.OnZombieUpdate.Add(function(zed)
    PhunRunners:updateZed(zed)
end);

Events.OnZombieDead.Add(function(zed)
    PhunRunners:unregisterSprinter(PhunRunners:getId(zed))
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PhunRunners.name and type(tableData) == "table" then
        PhunRunners:printTable(tableData)
        ModData.add(PhunRunners.name, tableData)
        PhunRunners.registry = ModData.getOrCreate(PhunRunners.name)
    end
end)

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        -- a player died. If its local, record the stats
        if playerObj:isLocalPlayer() then
            local pdata = playerObj:getModData()
            if not pdata.PhunRunners then
                pdata.PhunRunners = {}
            end
            if pdata.PhunRunners then
                pdata.PhunRunners.deaths = (pdata.PhunRunners.deaths or 0) + 1
                pdata.PhunRunners.hours = (pdata.PhunRunners.hours or 0) + playerObj:getHoursSurvived()
            end
        end
    elseif instanceof(playerObj, "IsoZombie") then
        -- zed died

        local data = playerObj:getModData()
        if data and data.brain then
            -- this is a bandit
            return
        end

        data = data and data.PhunRunners or {}

        local player = playerObj:getAttackedBy()
        if not player:isLocalPlayer() then
            return
        end
        local pdata = player:getModData()
        if not pdata.PhunRunners then
            pdata.PhunRunners = {}
        end

        local vehicle = player and player.getVehicle and player:getVehicle()
        if vehicle then
            if vehicle:getDriver() == player then
                if data and data.sprinting then
                    -- was a sprinter
                    pdata.PhunRunners.sprinterKills = (pdata.PhunRunners.sprinterKills or 0) + 1
                    pdata.PhunRunners.totalSprinterKills = (pdata.PhunRunners.totalSprinterKills or 0) + 1
                    triggerEvent(PhunRunners.events.OnSprinterDeath, playerObj, player, true)
                else
                    -- was a normal
                    pdata.PhunRunners.kills = (pdata.PhunRunners.kills or 0) + 1
                    pdata.PhunRunners.totalKills = (pdata.PhunRunners.totalKills or 0) + 1
                end
            end
        else
            if data and data.sprinting then
                -- was a sprinter
                pdata.PhunRunners.sprinterKills = (pdata.PhunRunners.sprinterKills or 0) + 1
                pdata.PhunRunners.totalSprinterKills = (pdata.PhunRunners.totalSprinterKills or 0) + 1
                triggerEvent(PhunRunners.events.OnSprinterDeath, playerObj, player)
            else
                -- was a normal
                pdata.PhunRunners.kills = (pdata.PhunRunners.kills or 0) + 1
                pdata.PhunRunners.totalKills = (pdata.PhunRunners.totalKills or 0) + 1
            end
        end

    end

end)
