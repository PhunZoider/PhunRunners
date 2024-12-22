if isServer() then
    return
end
require("ISUI/Maps/ISMiniMap")
local formatting = require("PhunRunners/formating")
local PR = PhunRunners
local sandbox = SandboxVars.PhunZones
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local profileName = "PhunRunnersWidgets"
PR.ui.widget = ISPanel:derive(profileName);
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
    UI.instances[playerIndex].minimap = getPlayerMiniMap(playerIndex)
    UI.instances[playerIndex]:setVisible(true);

    return UI.instances[playerIndex];

end

function UI:new(x, y, width, height, player, playerIndex)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

    o.borderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.0
    };
    o.normalBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.0
    };
    o.hoverBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };
    o.normalBackgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };
    o.hoverBackgroundColor = {
        r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.5
    };
    o.normalTextColor = {
        r = 0.2,
        g = 0.2,
        b = 0.2,
        a = 0.7
    };
    o.hoverTextColor = {
        r = 1,
        g = 1,
        b = 1,
        a = .9
    }
    o.data = PR:getPlayerData(player)

    o.moveWithMouse = true;
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

function UI:RestoreLayout(name, layout)

    ISLayoutManager.DefaultRestoreWindow(self, layout)
    if name == profileName then
        ISLayoutManager.DefaultRestoreWindow(self, layout)
        self.userPosition = layout.userPosition == 'true'
    end
    self:recalcSize();
end

function UI:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    if self.userPosition then
        layout.userPosition = 'true'
    else
        layout.userPosition = 'false'
    end
end

function UI:close()
    if not self.locked then
        ISPanel.close(self);
    end
end

function UI:createChildren()
    ISPanel.createChildren(self);
end

local calculatePips = function(risk)
    -- Ensure the risk is within the valid range
    if risk < 0 then
        risk = 0
    end
    if risk > 100 then
        risk = 100
    end

    -- Calculate the number of pips
    local pips = math.ceil(risk / 10)

    return pips
end

function UI:onMouseUp(x, y)
    ISPanel.onMouseUp(self, x, y)
    if not self.dragging then
        self:onClick()
    end
end

function UI:onMouseMove(dx, dy)
    ISPanel.onMouseMove(self, dx, dy)
    if self:isMouseOver() then
        self:doTooltip()
    end

end

local phunStats = nil

function UI:doTooltip()
    local x = self:getMouseX() + 20;
    local y = self:getMouseY() + 20;

    if phunStats == nil then
        phunStats = PhunStats
    end
    self.data = PR:updatePlayer(self.player)
    local titleHeight = FONT_HGT_MEDIUM;

    local texts = {}
    table.insert(texts, "Risk: " .. tostring(self.data.risk) .. "%")
    -- table.insert(texts, "Difficulty: " .. tostring(self.data.difficulty))
    table.insert(texts, "Char Hours: " .. formatting:formatWholeNumber(self.data.hours or 0))
    table.insert(texts, "Total Hours: " .. formatting:formatWholeNumber(self.data.totalHours or 0))
    table.insert(texts, "Total Kills: " .. tostring(self.data.totalKills or 0))
    table.insert(texts, "Sprinter Kills: " .. tostring(self.data.totalSprinters or 0))
    table.insert(texts, "Grace: " .. tostring(self.data.grace))
    table.insert(texts, "Modifier: " .. tostring(self.data.modifier) .. "%")
    table.insert(texts, "Fog: " .. tostring(self.data.env.fog) .. "%")
    table.insert(texts, "Light: " .. tostring(self.data.env.light) .. "%")
    table.insert(texts, "Moon: " .. tostring(self.data.env.moon) .. "%")
    table.insert(texts, "Moon Multiplier: " .. tostring(self.data.moonMultiplier) .. "%")
    table.insert(texts, "Value: " .. tostring(self.data.env.value) .. "%")
    table.insert(texts, "Restless: " .. tostring(self.data.restless))
    table.insert(texts, "Spawn Sprinters: " .. tostring(self.data.spawnSprinters))
    table.insert(texts, "Sprinters Killed: " .. tostring(self.data.sprinterKillRisk) .. "%")
    table.insert(texts, "Timer: " .. tostring(self.data.timerRisk) .. "%")
    table.insert(texts, "ZoneRisk: " .. tostring(self.data.zoneRisk) .. "%")
    -- table.insert(texts, "Zone Diff: " .. tostring(self.data.zone.diffifulty) .. "%")

    local text = table.concat(texts, "\n")

    local textWidth = getTextManager():MeasureStringX(UIFont.Small, text)
    local textHeight = getTextManager():MeasureStringY(UIFont.Small, text)

    x = self:getMouseX() - textWidth - 20;
    if x > getCore():getScreenWidth() then
        x = self:getMouseX() - textWidth - 20;
    end

    self:drawRect(x, y, textWidth + 20, textHeight + 20, 1.0, 0.0, 0.0, 0.0);
    self:drawRectBorder(x, y, textWidth + 20, textHeight + 20, 0.7, 0.4, 0.4, 0.4);
    self:drawText(text, x + 10, y + 10, 1, 1, 1, 1);

end

function UI:onClick()
    PR:reloadWidget(self.player)
end

function UI:render()
    if self:isMouseOver() then
        self:doTooltip()
    end
end

function UI:prerender()

    if (ISWorldMap_instance and ISWorldMap_instance:isVisible()) then
        return
    end

    ISPanel.prerender(self);

    local snapPosition = "clock" -- "topright" "minimap" or none?

    if snapPosition == "clock" then
        local clock = UIManager.getClock()
        if clock and clock:isVisible() then
            local clockx = clock:getX()
            local clocky = clock:getY()
            self:setX(clockx)
            self:setY(clocky + clock:getHeight() + 2)
        else
            self:setX(getCore():getScreenWidth() - self:getWidth() - 10)
            self:setY(2)
        end
    elseif snapPosition == "ninimap" then

        self:setX(self.minimap.x)
        self:setY(self.minimap.y)
        self:bringToTop()

        self:setWidth(0)
        self:setHeight(0)

        local title = self.minimap.titleBar

        if title:isVisible() then
            return
        end
    elseif snapPosition == "topright" then
        self:setX(getCore():getScreenWidth() - self:getWidth() - 10)
        self:setY(10)
    end

    local x = 2
    local y = 2
    local txtColor = self.normalTextColor

    local colors = {
        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 1.0
    }

    if self.data.risk <= 10 then
        colors.g = 0.9
        colors.r = 0.9
    else
        colors.r = 0.9
    end

    local pips = calculatePips(self.data.risk)
    for i = 1, pips do
        self:drawRect(x + ((i - 1) * 7), y, 5, 5, colors.a, colors.r, colors.g, colors.b);
    end

    for i = pips + 1, 10 do
        self:drawRectBorder(x + ((i - 1) * 7), y, 5, 5, 0.7, 0.4, 0.4, 0.4);
    end

end
