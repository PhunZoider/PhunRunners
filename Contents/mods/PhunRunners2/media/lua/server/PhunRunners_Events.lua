local PhunRunners = PhunRunners

local fieldsThatTriggerChange = {"lightRiskCategory", "lightRiskValue", "fogRiskCategory", "fogRiskValue",
                                 "moonRiskValue"}

if isClient() then

    local function setup()
        Events.OnTick.Remove(setup)
        PhunRunners:init()
        ModData.request(PhunRunners.name)
        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i)
            if player:isLocalPlayer() and isAdmin() then
                local window = PhunRunnersWidget.OnOpenPanel(player)
                if not window:isVisible() then
                    window:setVisible(true)
                end
            end
        end
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

    Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
        if tableName == PhunRunners.name and type(tableData) == "table" then
            print("Registered Runners")
            PhunTools:printTable(tableData)
            ModData.add(PhunRunners.name, tableData)
            PhunRunners.registry = ModData.getOrCreate(PhunRunners.name)
        end
    end)

    local Commands = {}
    Commands[PhunRunners.commands.registerSprinter] = function(arguments)
        PhunRunners:registerSprinter(arguments.id, true)
    end

    Commands[PhunRunners.commands.unregisterSprinter] = function(arguments)
        PhunRunners:unregisterSprinter(arguments.id, true)
    end

    Events.OnServerCommand.Add(function(module, command, arguments)
        if module == PhunRunners.name and Commands[command] then
            print("OnClientCommand:" .. command .. " " .. tostring(arguments))
            Commands[command](arguments)
        end
    end)

    local iniedPhunStats = false
    local iniedPhunZones = false
    if PhunStats then
        Events[PhunStats.events.OnPhunStatsClientReady].Add(function()

            if not iniedPhunStats then
                print("PhunStats ready")
                iniedPhunStats = true
                if iniedPhunZones then
                    PhunRunners:updateEnvironment()
                    PhunRunners:updatePlayers()
                    PhunRunners:recalcOutfits()
                end
            end
        end)
    end

    if PhunZones then
        Events[PhunZones.events.OnPhunZoneReady].Add(function()

            if not iniedPhunZones then
                iniedPhunZones = true
                print("PhunZones ready")
                if iniedPhunStats then
                    PhunRunners:updateEnvironment()
                    PhunRunners:updatePlayers()
                    PhunRunners:recalcOutfits()
                end
            end
        end)
    end

else

    local Commands = {}

    Commands[PhunRunners.commands.registerSprinter] = function(playerObj, arguments)
        PhunRunners:registerSprinter(arguments.id)
    end

    Commands[PhunRunners.commands.unregisterSprinter] = function(playerObj, arguments)
        PhunRunners:unregisterSprinter(arguments.id)
    end

    Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
        if module == PhunRunners.name and Commands[command] then
            Commands[command](playerObj, arguments)
        end
    end)

    function PhunRunners:clean()

        local cells = {}
        local ids = {}

        local sids = {}
        local tids = {}

        for i = 0, getOnlinePlayers():size() - 1 do
            local p = getOnlinePlayers():get(i)
            local cell = p:getCell()
            local cellKey = tostring(cell:getWorldX()) .. "_" .. tostring(cell:getWorldY())
            if not cells[cellKey] then
                cells[cellKey] = true
                local list = p:getCell():getZombieList();
                if list ~= nil then
                    for j = 0, list:size() - 1 do
                        local zed = list:get(j)
                        local id = self:getId(zed)
                        if self.registry[id] then
                            ids[id] = true
                        end
                    end
                end
            end
        end

        for k, _ in pairs(self.registry) do
            table.insert(tids, k)
        end
        table.sort(tids, function(a, b)
            return a < b
        end)
        print("Registered zeds: ", #tids)
        for _, v in ipairs(tids) do
            print(" - ", v)
        end

        for k, _ in pairs(ids) do
            table.insert(sids, k)
        end
        table.sort(sids, function(a, b)
            return a < b
        end)
        print("Keeping zeds: ", #sids)
        for _, v in ipairs(sids) do
            print(" - ", v)
        end

        local changed = 0
        for k, v in pairs(self.registry) do
            if not ids[k] then
                print("cleaning zed ", k)
                changed = changed + 1
                self:unregisterSprinter(k, true)
            else
                print("keeping zed ", k)
            end
        end

        if changed > 0 then
            ModData.transmit(PhunRunners.name)
        end

        tids = {}
        for k, _ in pairs(self.registry) do
            table.insert(tids, k)
        end
        table.sort(tids, function(a, b)
            return a < b
        end)
        print("Remaining zeds: ", #tids)
        for _, v in ipairs(tids) do
            print(" - ", v)
        end

    end

    Events.EveryHours.Add(function()
        -- PhunRunners:clean()
    end)

    PhunTools:RunOnceWhenServerEmpties(PhunRunners.name, function()
        -- PhunRunners.registry = {}
    end)
end

Events.OnZombieDead.Add(function(zed)
    PhunRunners:unregisterSprinter(PhunRunners:getId(zed))
end)

Events.OnInitGlobalModData.Add(function()
    PhunRunners:init()
    -- local s = "\n-- EVENTS --\n"
    -- for k, _ in pairs(Events) do
    --     s = s .. k .. "\n "
    -- end
    -- print(s)
end)
