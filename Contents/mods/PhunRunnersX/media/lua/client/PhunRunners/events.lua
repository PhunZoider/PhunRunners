if not isClient() then
    return
end
local Commands = require("commands")
local PR = PhunRunners
local getOnlinePlayers = getOnlinePlayers
local iniedPhunStats = false
local iniedPhunZones = false

if PhunZones then
    local PZ = PhunZones
    Events[PZ.events.OnPhunZoneReady].Add(function()
        if not iniedPhunZones then
            iniedPhunZones = true
            if iniedPhunStats then
                PR:updateEnvironment()
                PR:updatePlayers()
                PR:recalcOutfits()
            end
        end
    end)

    Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
        PR:updatePlayer(playerObj, zone)
    end)
end

if PhunStats then
    Events[PhunStats.events.OnReady].Add(function()

        if not iniedPhunStats then
            iniedPhunStats = true
            if iniedPhunZones then
                PR:updateEnvironment()
                PR:updatePlayers()
                PR:recalcOutfits()
            end
        end
    end)
end

local function setup()
    Events.OnTick.Remove(setup)
    PR:init()
    ModData.request(PR.name)
    PR:updateEnvironment()
    PR:updatePlayers()
    PR:recalcOutfits()
end
Events.OnTick.Add(setup)

Events.EveryOneMinute.Add(function()
    PR:updateEnvironment()
    PR:updatePlayers()
end)

Events.OnDawn.Add(function()
    PR:updateEnvironment()
    PR:updatePlayers()
    PR:recalcOutfits()
end)

Events.OnDusk.Add(function()
    PR:updateEnvironment()
end)

Events.OnZombieUpdate.Add(function(zed)
    PR:updateZed(zed)
end);

Events.OnZombieDead.Add(function(zed)
    PR:unregisterSprinter(PR:getId(zed))
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PR.name and type(tableData) == "table" then
        ModData.add(PR.name, tableData)
        PR.data = ModData.getOrCreate(PR.name)
    end
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](arguments)
    end
end)

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoZombie") then
        -- zed died

        local data = playerObj:getModData()
        if data and data.brain then
            -- this is a bandit
            return
        end

        data = data and data.PhunRunners or {}

        local player = playerObj:getAttackedBy()
        if not player or not player:isLocalPlayer() then
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
                    triggerEvent(PR.events.OnSprinterDeath, playerObj, player, true)
                end
            end
        else
            if data and data.sprinting then
                triggerEvent(PR.events.OnSprinterDeath, playerObj, player)
            end
        end

    end

end)
