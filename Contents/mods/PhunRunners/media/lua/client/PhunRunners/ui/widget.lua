if isServer() then
    return
end
local formatting = require("PhunRunners/formating")
local PR = PhunRunners
local PhunStats = PhunStats
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local profileName = "PhunRunnersWidgets"
PR.ui.widget = ISCollapsableWindowJoypad:derive(profileName);
PR.ui.widget.instances = {}
local UI = PR.ui.widget

function UI.OnOpenPanel(playerObj, playerIndex)

    playerIndex = playerIndex or playerObj:getPlayerNum()

    if not UI.instances[playerIndex] then
        local core = getCore()
        local width = 50 * FONT_SCALE
        local height = 20 * FONT_SCALE

        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2

        UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        UI.instances[playerIndex]:initialise();
        -- ISLayoutManager.RegisterWindow(profileName, PR.ui.widget, PR.ui.widget.instances[playerIndex])
    end

    UI.instances[playerIndex]:addToUIManager();
    UI.instances[playerIndex]:setVisible(true);

    return UI.instances[playerIndex];

end

function UI:new(x, y, width, height, player, playerIndex)
    local o = {};
    o = ISCollapsableWindowJoypad:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.playerName = player:getUsername()
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)

    return o;
end

function UI:render()
    ISCollapsableWindowJoypad.render(self);
    local x = 10;
    local y = 10;

    local modData = self.player:getModData()
    local data = modData.PhunRunners or {}
    local pz = modData.PhunZones or {}
    local titleHeight = FONT_HGT_MEDIUM;

    local texts = {}
    table.insert(texts,
        (pz.region or "Unknown") .. " (" .. (pz.zone or "Unknown") .. ") - " .. (pz.difficulty or "Unknown"))
    table.insert(texts, "Risk: " .. tostring(data.risk) .. "%")
    table.insert(texts, "Light: " .. tostring(PR.data.value) .. "%")
    table.insert(texts, "Spawning: " .. tostring(PR.data.create))
    table.insert(texts, "Running: " .. tostring(PR.data.run))

    table.insert(texts, "-----")
    table.insert(texts, "Base Light: " .. tostring(PR.data.light) .. "%")
    table.insert(texts, "Fog: " .. tostring(PR.data.fog) .. "%")
    table.insert(texts, "Light: " .. tostring(PR.data.value) .. "%")

    table.insert(texts, "Modifier: " .. tostring(data.modifier) .. "%")
    table.insert(texts, "Moon Multiplier: " .. tostring(data.moonMultiplier) .. "%")
    table.insert(texts, "Risk: " .. tostring(data.risk) .. "%")

    table.insert(texts, "-----")
    table.insert(texts, "Char Hours: " .. formatting:formatWholeNumber(data.hours or 0))
    table.insert(texts, "Total Hours: " .. formatting:formatWholeNumber(data.totalHours or 0))
    table.insert(texts, "Total Kills: " .. tostring(data.totalKills or 0))
    table.insert(texts, "Sprinter Kills: " .. tostring(data.totalSprinters or 0))
    table.insert(texts, "Grace: " .. tostring(data.grace))
    table.insert(texts, "Sprinters Killed: " .. tostring(data.sprinterKillRisk) .. "%")
    table.insert(texts, "Timer: " .. tostring(data.timerRisk) .. "%")

    local text = table.concat(texts, "\n")

    local textWidth = getTextManager():MeasureStringX(UIFont.Small, text)
    local textHeight = getTextManager():MeasureStringY(UIFont.Small, text)

    self:drawRect(x, y, textWidth + 20, textHeight + 20, 1.0, 0.0, 0.0, 0.0);
    self:drawRectBorder(x, y, textWidth + 20, textHeight + 20, 0.7, 0.4, 0.4, 0.4);
    self:drawText(text, x + 10, y + 10, 1, 1, 1, 1);
end

