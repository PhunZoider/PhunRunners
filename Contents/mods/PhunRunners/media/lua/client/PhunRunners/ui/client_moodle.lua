if isServer() then
    return
end
require "MF_ISMoodle"
local mf = MF
local PR = PhunRunners
mf.createMoodle(PR.name)

PR.moodles = {}
local inied = {}

local chevrons = {
    [50] = 3,
    [35] = 2,
    [20] = 1,
    [10] = 0,
    [5] = 3,
    [3] = 2,
    [1] = 1,
    [0] = 0

}

local function formatNumber(number, decimals)
    number = number or 0
    -- Round the number to remove the decimal part
    local roundedNumber = math.floor(number + (decimals and 0.005 or 0.5))
    -- Convert to string and format with commas
    local formattedNumber = tostring(roundedNumber):reverse():gsub("(%d%d%d)", "%1,")
    formattedNumber = formattedNumber:reverse():gsub("^,", "")
    return formattedNumber
end

local function getDescription(player)
    local pd = player:getModData().PhunRunners or {}
    local texts = {}
    local modifiers = PR:getModifiers()

    table.insert(texts, getText("IGUI_PhunRunners_Risk_Percentage", formatNumber(pd.risk, true)))
    table.insert(texts,
        getText("IGUI_PhunRunners_Risk_Area_Percentage", getText("IGUI_PhunRunners_Risk" .. pd.difficulty),
            formatNumber(pd.zoneRisk)))
    if pd.timerRisk + pd.sprinterKillRisk > 0 then
        table.insert(texts, getText("IGUI_PhunRunners_Risk_Stats_Percentage",
            formatNumber(pd.timerRisk + pd.sprinterKillRisk)))
    end
    local moon = (PR.data.moonMultiplier - 1) * 100
    if moon > 0 then
        table.insert(texts,
            getText("IGUI_PhunRunners_Risk_Moon_Percentage", getText("IGUI_PhunRunners_MoonPhase" .. PR.data.moon),
                formatNumber(moon)))
    end
    if pd.grace > 0 then
        table.insert(texts, getText("IGUI_PhunRunners_Grace_Remaining", formatNumber(pd.grace, true)))
    end

    if PR.data.value <= PR.settings.DarknessLevel then
        table.insert(texts, "Dark: " .. tostring(formatNumber(100 - PR.data.value)) .. "%")
        if PR.data.fog > 0 then
            table.insert(texts, " - Light level: " .. formatNumber(PR.data.light) .. "%")
            table.insert(texts, " - Fog density: " .. tostring(PR.data.fog) .. "%")
        end
    elseif PR.data.value <= PR.settings.SlowInLightLevel then
        table.insert(texts, "Dim: " .. formatNumber(100 - PR.data.value) .. "%")
        if PR.data.fog > 0 then
            table.insert(texts, " - Light level: " .. formatNumber(PR.data.light) .. "%")
            table.insert(texts, " - Fog: " .. tostring(PR.data.fog) .. "%")

        end
    end

    if isAdmin() or isDebugEnabled() then
        table.insert(texts, "Attributes")
        table.insert(texts, " - Char Hours: " .. formatNumber(pd.hours or 0))
        table.insert(texts, " - Total Hours: " .. formatNumber(pd.totalHours or 0))
        table.insert(texts, " - Total Kills: " .. tostring(pd.totalKills or 0))
        table.insert(texts, " - Sprinter Kills: " .. tostring(pd.totalSprinters or 0))
        table.insert(texts, " - Sprinters Killed: " .. tostring(pd.sprinterKillRisk) .. "%")
        table.insert(texts, " - Grace Hours Remaining: " .. tostring(pd.grace))
        table.insert(texts, " - Length of play: " .. tostring(pd.timerRisk) .. "%")
        table.insert(texts, "-----")
        table.insert(texts, "Env")
        table.insert(texts, " - Area Difficulty: " .. tostring(pd.difficulty))
        table.insert(texts, " - Value: " .. formatNumber(PR.data.value) .. "%")
        table.insert(texts, " - Moon Phase: " .. tostring(PR.data.moon))
        table.insert(texts, " - Moon Multiplier: " .. tostring(pd.moonMultiplier) .. "%")
        table.insert(texts, " - Light: " .. tostring(PR.data.light) .. "%")
        table.insert(texts, " - Fog: " .. tostring(PR.data.fog) .. "%")
        table.insert(texts, " - Dimness: " .. formatNumber(PR.data.dimness * 100) .. "%")
        table.insert(texts, "-----")
        table.insert(texts, "Spawning mode")
        table.insert(texts, " - create: " .. tostring(pd.create))
        table.insert(texts, " - run: " .. tostring(pd.run))
        table.insert(texts, "Settings")
        table.insert(texts, " - Darkness Level: " .. tostring(PR.settings.DarknessLevel))
        table.insert(texts, " - Slow In Light Level: " .. tostring(PR.settings.SlowInLightLevel))
        local modifiers = PR:getModifiers()
        table.insert(texts, "Modifiers")

        -- hours
        local hourModifierIndex = 0
        local hoursTable = {}
        for k, v in pairs(modifiers.hours) do
            if pd.timerRisk > k then
                hourModifierIndex = v
            end
            table.insert(hoursTable, tostring(k) .. "=" .. tostring(v))
        end
        local hoursLabel = " - Hours: "
        if hourModifierIndex > 0 then
            hoursTable[hourModifierIndex] = "*" .. hoursTable[hourModifierIndex]
            hoursLabel = hoursLabel .. " " .. tostring(hoursTable[hourModifierIndex])
        else
            hoursLabel = hoursLabel .. " none "
        end
        table.insert(texts, hoursLabel)
        table.insert(texts, "   - " .. table.concat(hoursTable, ", "))

        -- sprinters
        local sprintersModifierIndex = 0
        local sprintersTable = {}
        for k, v in pairs(modifiers.hours) do
            if pd.timerRisk > k then
                sprintersModifierIndex = v
            end
            table.insert(sprintersTable, tostring(k) .. "=" .. tostring(v))
        end
        local sprintersLabel = " - Sprinters: "
        if sprintersModifierIndex > 0 then
            sprintersTable[sprintersModifierIndex] = "*" .. sprintersTable[sprintersModifierIndex]
            sprintersLabel = sprintersLabel .. " " .. tostring(sprintersTable[sprintersModifierIndex])
        else
            sprintersLabel = sprintersLabel .. " none"
        end
        table.insert(texts, sprintersLabel)
        table.insert(texts, "   - " .. table.concat(sprintersTable, ", "))

        local modifierTable = {}
        local difficultyLabel = " - Area Difficulty: "
        for k, v in pairs(modifiers.difficulty) do
            table.insert(modifierTable, tostring(k) .. "=" .. tostring(v) .. (k == pd.difficulty and "*" or ""))
            if pd.difficulty == k then
                difficultyLabel = difficultyLabel .. " " .. tostring(v) .. "%"
            end
        end
        table.insert(texts, difficultyLabel)
        table.insert(texts, "   - " .. table.concat(modifierTable, ", "))

        -- local moonTable = {}
        -- local moonLabel = " - Moon: "
        -- for k, v in pairs(modifiers.moon) do
        --     table.insert(moonTable, tostring(k) .. "=" .. tostring(v) .. (k == (PR.data.moon) and "*" or ""))
        --     if PR.data.moon == k then
        --         moonLabel = moonLabel .. " " .. tostring(k) .. "=" .. tostring(v) .. "%"
        --     end
        -- end
        -- table.insert(texts, moonLabel)
        -- table.insert(texts, "   - " .. table.concat(moonTable, ", "))

    end

    if pd.run then
        table.insert(texts, getText("IGUI_PhunRunners_ZedsAreRestless"))
    else
        table.insert(texts, getText("IGUI_PhunRunners_ZedsAreSettling"))
    end

    return #texts > 0 and table.concat(texts, "\n") or ""
end

function PR.moodles:get(player)

    local moodle = mf.getMoodle(PR.name, player and player:getPlayerNum())

    if inied[tostring(player)] == nil then
        -- only show bad moodles
        moodle:setThresholds(0.6, 0.7, 0.8, 0.9999, 1.941, 1.97, 1.99, 2)
        local oldMoodleMouseover = moodle.mouseOverMoodle
        moodle.mouseOverMoodle = function(self, goodBadNeutral, moodleLevel)
            if self:isMouseOver() or self:isMouseOverMoodle() then
                self:setDescription(goodBadNeutral, moodleLevel, getDescription(player, goodBadNeutral, moodleLevel))
            end
            oldMoodleMouseover(self, goodBadNeutral, moodleLevel)
        end
        inied[tostring(player)] = 0
    end

    return moodle
end

function PR.moodles:update(player, data)

    if not data or not PR.data then
        return
    end

    local moodle = self:get(player)
    if not moodle or not PR.settings.ShowMoodle and not PR.settings.ShowMoodleOnlyWhenRunning then
        if moodle then
            moodle:setValue(2)
        end
        if not isAdmin() and not isDebugEnabled() then
            return
        end
    end

    local modData = player:getModData()
    local pd = data or modData.PhunRunners or {}

    if not pd.run and not pd.create and not isAdmin() and not PR.settings.ShowMoodleOnlyWhenRunning then
        moodle:setValue(2)
        if not isAdmin() and not isDebugEnabled() then
            return
        else
            moodle:setValue(2)
        end
    end

    local value = 1 - (data.risk * .01)

    moodle:setValue(value)

    local chevys = 0
    for k, v in pairs(chevrons) do
        if pd.risk >= k then
            chevys = v
            break
        end
    end

    moodle:setChevronCount(chevys)

    local now = getGameTime():getHoursSurvived()
    if now - (pd.riskChanged or 0) < 0.15 then
        for k, v in pairs(chevrons) do
            if pd.risk >= k then
                moodle:setChevronCount(v)
                break
            end
        end

        moodle:setChevronIsUp(pd.oldRisk and (pd.oldRisk < pd.risk))
    else
        moodle:setChevronCount(0)
    end

    inied[tostring(player)] = chevys

    -- if data.rate then
    --     if data.rate > 0 then
    --         moodle:setChevronCount(data.rate)
    --         moodle:setChevronIsUp(data.rate < 0)
    --     elseif data.rate < 0 then
    --         moodle:setChevronCount(math.abs(data.rate))
    --         moodle:setChevronIsUp(true)
    --     else
    --         moodle:setChevronCount(0)
    --     end
    -- else
    --     moodle:setChevronCount(0)
    -- end
    -- local tbl = {}
    -- if pd.iodineExp then
    --     table.insert(tbl, getText("IGUI_PhunRad_IodineStrength", PR.settings.IodineStrength))
    --     local expin = pd.iodineExp - math.floor(getGameTime():getWorldAgeHours() + 0.005)
    --     if expin < 0 then
    --         table.insert(tbl, getText("IGUI_PhunRad_IodineExpiresSoon"))
    --     elseif expin < 2 then
    --         table.insert(tbl, getText("IGUI_PhunRad_IodineExpiresInAnHour"))
    --     else
    --         table.insert(tbl, getText("IGUI_PhunRad_IodineExpiresInXHours", expin))
    --     end
    -- end
    -- if data.activeGeiger then
    --     table.insert(tbl, getText("IGUI_PhunRad_YourRadiation", formatNumber(pd.rads)))
    -- end
    -- if data.itemRads then
    --     table.insert(tbl, getText("IGUI_PhunRad_ItemRadiation", formatNumber(data.itemRads)))
    -- end
    -- if (#(data.clothingProtectionItems or {})) > 0 then
    --     table.insert(tbl, getText("IGUI_PhunRad_ClothingProtection", formatNumber(data.clothingProtection)))
    -- end
    -- for _, v in ipairs(data.clothingProtectionItems or {}) do
    --     table.insert(tbl, tostring(v.name) .. ": " .. tostring(v.protection))
    -- end
    if modData.PhunZones.subtitle then
        moodle:setTitle(moodle:getGoodBadNeutral(), moodle:getLevel(),
            modData.PhunZones.title .. " - " .. modData.PhunZones.subtitle)
    else
        moodle:setTitle(moodle:getGoodBadNeutral(), moodle:getLevel(), modData.PhunZones.title)
    end
    -- moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), #texts > 0 and table.concat(texts, "\n") or "")

end

