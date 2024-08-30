if not isServer() then
    return
end

local PhunRunners = PhunRunners

Events.EveryHours.Add(function()
    PhunRunners:clean()
end)

Events.OnZombieDead.Add(function(zed)
    PhunRunners:unregisterSprinter(PhunRunners:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PhunRunners:init()
end)

if PhunTools then
    PhunTools:RunOnceWhenServerEmpties(PhunRunners.name, function()
        PhunRunners:clean()
    end)
end

if PhunZones and PhunZones.events.OnPhunZonesPlayerLocationChanged then
    Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
        PhunRunners:updatePlayer(playerObj, zone)
    end)
end
