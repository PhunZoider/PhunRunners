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
else

    local emptyServerTickCount = 0
    local emptyServerCalculate = false

    Events.EveryTenMinutes.Add(function()
        if getOnlinePlayers():size() > 0 then
            emptyServerCalculate = true
        end
    end)

    Events.OnTickEvenPaused.Add(function()
        if emptyServerCalculate and emptyServerTickCount > 100 then
            if getOnlinePlayers():size() == 0 then
                PhunRunners:clean()
            end
        elseif emptyServerTickCount > 100 then
            emptyServerTickCount = 0
        else
            emptyServerTickCount = emptyServerTickCount + 1
        end
    end)
end
