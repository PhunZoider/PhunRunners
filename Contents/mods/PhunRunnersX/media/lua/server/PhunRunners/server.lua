if not isServer() then
    return
end

local PR = PhunRunners
local getOnlinePlayers = getOnlinePlayers

function PR:clean()

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
                    if self.data[id] then
                        ids[id] = true
                    end
                end
            end
        end
    end

    local changed = 0
    for k, v in pairs(self.data) do
        if not ids[k] then
            changed = changed + 1
            self:unregisterSprinter(k, true)
        end
    end

    if changed > 0 then
        ModData.transmit(self.name)
    end

end
