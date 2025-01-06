if isClient() then
    return
end

local PR = PhunRunners

-- hmm, I think we are trying to reset all zeds in playerless chunks?
function PR:clean()

    local cells = {}
    local ids = {}

    local sids = {}
    local tids = {}
    local players = self:onlinePlayers(true)
    for i = 0, players:size() - 1 do
        local p = players:get(i)
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

    -- TODO: Don't think this is doing what we think it is doing. 
    -- Can we get zedids of those not in same cell as a player and reset that way?

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
