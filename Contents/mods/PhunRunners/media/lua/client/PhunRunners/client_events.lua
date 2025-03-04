if isServer() then
    return
end
local Commands = require("PhuNRunners/client_commands")
local PR = PhunRunners
local PhunZones = PhunZones
local PhunStats = PhunStats
local iniedPhunStats = false
local iniedPhunZones = false

if PhunZones then
    local PZ = PhunZones
    Events[PZ.events.OnPhunZoneReady].Add(function()
        if not iniedPhunZones then
            iniedPhunZones = true
            if iniedPhunStats then
                PR:updatePlayers()
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
                PR:updatePlayers()
            end
        end
    end)
end

Events.EveryOneMinute.Add(function()
    PR.delta = getTimestamp()
end)

Events.OnCreatePlayer.Add(function(player)
    if PR.isLocal then
        PR:updateDawnDusk()
        PR:updateMoon()
        PR:updateEnv()
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    PR:ini()
    sendClientCommand(PR.name, PR.commands.requestState, {})
    ModData.request(PR.name)

    PR:recalcOutfits()
    PR:showWidgets()

    -- local nextCheck = 0
    -- local every = PR.settings.FrequencyOfEnvUpdate
    -- local getTimestamp = getTimestamp
    -- Events.OnTick.Add(function()
    --     PR.tocked = true
    --     -- if getTimestamp() >= nextCheck then
    --     --     nextCheck = getTimestamp() + every
    --     --     PR:caclculateEnv()
    --     -- end
    -- end)

    Events.EveryTenMinutes.Add(function()
        -- fallback for when env changes are not detected
        if PR.inied then
            PR:updatePlayers()
        end
    end)

end

Events.OnTick.Add(setup)

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    if isAdmin() or isDebugEnabled() then
        context:addOption("PhunRunners", worldobjects, function()
            local p = playerObj and getSpecificPlayer(playerObj) or getPlayer()
            PR.ui.widget.OnOpenPanel(p)
        end)
    end
end);

Events.OnDawn.Add(function()
    PR:recalcOutfits()
end)

Events.OnZombieUpdate.Add(function(zed)
    PR:updateZed(zed)
end);

Events.OnZombieDead.Add(function(zed)
    -- PR:unregisterSprinter(PR:getId(zed))
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PR.name and type(tableData) == "table" then
        ModData.add(PR.name, tableData)
        PR.data = ModData.getOrCreate(PR.name)
        -- PR:updateDawnDusk()
        -- PR:updateMoon()
        PR:updatePlayers()
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
