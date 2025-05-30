if isServer() then
    return
end
local Commands = require("PhuNRunners/client_commands")
local Core = PhunRunners
local PhunZones = PhunZones
local PhunStats = PhunStats
local PL = PhunLib
local iniedPhunStats = false
local iniedPhunZones = false

if PhunZones then
    local PZ = PhunZones
    Events[PZ.events.OnPhunZoneReady].Add(function()
        if not iniedPhunZones then
            iniedPhunZones = true
            if iniedPhunStats then
                Core:updatePlayers()
            end
        end
    end)

    Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
        Core:updatePlayer(playerObj, zone)
    end)
end

-- if PhunStats then
--     Events[PhunStats.events.OnReady].Add(function()
--         if not iniedPhunStats then
--             iniedPhunStats = true
--             if iniedPhunZones then
--                 Core:updatePlayers()
--             end
--         end
--     end)
-- end

Events.EveryOneMinute.Add(function()
    Core.delta = getTimestamp()
end)

Events.OnCreatePlayer.Add(function(player)
    if Core.isLocal then
        Core:updateDawnDusk()
        Core:updateMoon()
        Core:updateEnv()
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    Core:ini()
    sendClientCommand(Core.name, Core.commands.requestState, {})
    ModData.request(Core.name)

    Core:recalcOutfits()
    Core:showWidgets()

    Events.EveryTenMinutes.Add(function()
        -- fallback for when env changes are not detected
        if Core.inied then
            Core:updatePlayers()
        end
    end)

end

Events.OnTick.Add(setup)

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    if isAdmin() or isDebugEnabled() then
        context:addOption("PhunRunners", worldobjects, function()
            local p = playerObj and getSpecificPlayer(playerObj) or getPlayer()
            Core.ui.widget.OnOpenPanel(p)
        end)
    end
end);

Events.OnDawn.Add(function()
    Core:recalcOutfits()
end)

Events.OnZombieUpdate.Add(function(zed)
    Core:updateZed(zed)
end);

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == Core.name and type(tableData) == "table" then
        ModData.add(PR.name, tableData)
        Core.data = ModData.getOrCreate(Core.name)
        Core:updatePlayers()
    end
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](arguments)
    end
end)

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoZombie") then

        local data = playerObj:getModData()
        if data and data.brain then
            -- this is a bandit
            return
        end

        data = data and data.PhunRunners or {}

        -- zed died
        local killer = playerObj:getAttackedBy()
        if killer and instanceof(killer, "IsoPlayer") and killer:isLocalPlayer() then
            local doRecord = false
            local vehicle = killer and killer.getVehicle and killer:getVehicle()
            if vehicle then

                if vehicle:getDriver() == killer then
                    doRecord = true
                end
            else
                doRecord = true

            end

            if doRecord then
                local modData = killer:getModData()
                if not modData.PhunRunners then
                    modData.PhunRunners = {}
                end
                modData.PhunRunners.kills = (modData.PhunRunners.kills or 0) + 1
                modData.PhunRunners.PhunRunners.totalKills = (modData.PhunRunners.totalKills or 0) + 1
                if data and data.sprinting then
                    modData.PhunRunners.sprinterKills = (modData.PhunRunners.sprinterKills or 0) + 1
                    modData.PhunRunners.totalSprinterKills = (modData.PhunRunners.totalSprinterKills or 0) + 1
                    triggerEvent(Core.events.OnSprinterDeath, playerObj, killer, true)
                end
            end

        end
    elseif instanceof(playerObj, "IsoPlayer") then
        -- player died
        if playerObj:isLocalPlayer() then
            local modData = playerObj:getModData()
            if not modData.PhunRunners then
                modData.PhunRunners = {}
            end
            modData.PhunRunners.deaths = (modData.PhunRunners.deaths or 0) + 1
            modData.PhunRunners.PhunRunners.totalDeaths = (modData.PhunRunners.PhunRunners.totalDeaths or 0) + 1
            modData.PhunRunners.totalHours = (modData.PhunRunners.totalHours or 0) + playerObj:getHoursSurvived()
            modData.PhunRunners.hours = 0
        end
    end

end)

Events.EveryTenMinutes.Add(function()

    local players = PL.onlinePlayers()
    for i = 0, players:size() - 1 do
        local playerObj = players:get(i)

        local modData = playerObj:getModData()
        if not modData.PhunRunners then
            modData.PhunRunners = {}
        end
        modData.PhunRunners.hours = playerObj:getHoursSurvived()
    end

end)
