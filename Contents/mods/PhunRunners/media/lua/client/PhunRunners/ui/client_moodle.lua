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

function PR.moodles:get(player)

    local moodle = mf.getMoodle(PR.name, player and player:getPlayerNum())

    if inied[tostring(player)] == nil then
        -- only show bad moodles
        moodle:setThresholds(0.6, 0.7, 0.8, 0.9999, 1.941, 1.97, 1.99, 2)
        inied[tostring(player)] = 0
    end

    return moodle
end

local function formatNumber(number, decimals)
    number = number or 0
    -- Round the number to remove the decimal part
    local roundedNumber = math.floor(number + (decimals and 0.005 or 0.5))
    -- Convert to string and format with commas
    local formattedNumber = tostring(roundedNumber):reverse():gsub("(%d%d%d)", "%1,")
    formattedNumber = formattedNumber:reverse():gsub("^,", "")
    return formattedNumber
end

local moonPhaseNames = {"New Moon", "Crescent Moon", "First Quarter", "Gibbous Moon", "Full Moon", "Gibbous Moon",
                        "Last Quarter", "Waning Crescent"}

local riskLevelNames = {"None", "Low", "Moderate", "High", "Extreme"}

function PR.moodles:update(player, data)

    local moodle = self:get(player)
    if not moodle or not PR.settings.ShowMoodle and not PR.settings.ShowMoodleOnlyWhenRunning then
        if moodle then
            moodle:setValue(2)
        end
        if not isAdmin() and not isDebugEnabled() then
            return
        end
    end

    local pd = data or player:getModData().PhunRunners or {}

    if not pd.restless and not isAdmin() and not PR.settings.ShowMoodleOnlyWhenRunning then
        moodle:setValue(2)
        if not isAdmin() and not isDebugEnabled() then
            return
        end
    end

    local value = 1 - (data.risk * .01)

    moodle:setValue(value)

    local texts = {}
    table.insert(texts, "Chance: " .. formatNumber(pd.risk, true) .. "%")
    table.insert(texts, " - Area: " .. riskLevelNames[pd.difficulty + 1] .. " " .. tostring(pd.zoneRisk) .. "%")

    local multiplier = (pd.moonMultiplier - 1) * 100
    if multiplier > 0 then
        multiplier = "" .. formatNumber(multiplier) .. "%"
        -- multiplier = multiplier - 100
    elseif multiplier < 0 then
        multiplier = "" .. formatNumber(multiplier) .. "%"
    else
        multiplier = ""
    end
    table.insert(texts, " - " .. moonPhaseNames[pd.env.moon + 1] .. " " .. tostring(multiplier))
    if pd.grace > 0 then
        table.insert(texts, " - Grace: " .. tostring(pd.grace))
    end

    if pd.env.value <= PR.settings.DarknessLevel then
        table.insert(texts, "Dark: " .. tostring(formatNumber(pd.env.value)) .. "%")
        if pd.env.fog > 0 then
            table.insert(texts, " - Light level: " .. formatNumber(pd.env.light) .. "%")
            table.insert(texts, " - Fog density: " .. tostring(pd.env.fog) .. "%")
        end
    elseif pd.env.value <= PR.settings.SlowInLightLevel then
        table.insert(texts, "Dim: " .. formatNumber(pd.env.value) .. "%")
        if pd.env.fog > 0 then
            table.insert(texts, " - Light level: " .. formatNumber(pd.env.light) .. "%")
            table.insert(texts, " - Fog: " .. tostring(pd.env.fog) .. "%")

        end
    end

    if isAdmin() or isDebugEnabled() then
        table.insert(texts, "Attributes")
        table.insert(texts, "Char Hours: " .. formatNumber(pd.hours or 0))
        table.insert(texts, "Total Hours: " .. formatNumber(pd.totalHours or 0))
        table.insert(texts, "Total Kills: " .. tostring(pd.totalKills or 0))
        table.insert(texts, "Sprinter Kills: " .. tostring(pd.totalSprinters or 0))
        table.insert(texts, "Grace: " .. tostring(pd.grace))
        table.insert(texts, "Sprinters Killed: " .. tostring(pd.sprinterKillRisk) .. "%")
        table.insert(texts, "Timer: " .. tostring(pd.timerRisk) .. "%")
        table.insert(texts, "-----")
        table.insert(texts, "Env")
        table.insert(texts, "Difficulty: " .. tostring(pd.difficulty))
        table.insert(texts, "Value: " .. tostring(pd.env.value) .. "%")
        table.insert(texts, "Moon Multiplier: " .. tostring(pd.moonMultiplier) .. "%")
        table.insert(texts, "Modifier: " .. tostring(pd.modifier) .. "%")
        table.insert(texts, "Fog1: " .. tostring(pd.env.fog) .. "%")
        table.insert(texts, "Light: " .. tostring(pd.env.light) .. "%")
        table.insert(texts, "-----")
        table.insert(texts, "Spawning mode")
        table.insert(texts, "Restless: " .. tostring(pd.restless))
        table.insert(texts, "Spawn Sprinters: " .. tostring(pd.spawnSprinters))
    end

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
    if pd.zone.subtitle then
        moodle:setTitle(moodle:getGoodBadNeutral(), moodle:getLevel(), pd.zone.title .. " - " .. pd.zone.subtitle)
    else
        moodle:setTitle(moodle:getGoodBadNeutral(), moodle:getLevel(), pd.zone.title)
    end
    moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), #texts > 0 and table.concat(texts, "\n") or "")

end

