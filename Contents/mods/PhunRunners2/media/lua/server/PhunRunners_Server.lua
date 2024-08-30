if not isServer() then
    return
end

local PhunRunners = PhunRunners
local getOnlinePlayers = getOnlinePlayers

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
