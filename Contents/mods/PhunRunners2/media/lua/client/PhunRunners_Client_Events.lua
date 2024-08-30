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
        print("Registered Runners")
        PhunRunners:printTable(tableData)
        ModData.add(PhunRunners.name, tableData)
        PhunRunners.registry = ModData.getOrCreate(PhunRunners.name)
    end
end)
