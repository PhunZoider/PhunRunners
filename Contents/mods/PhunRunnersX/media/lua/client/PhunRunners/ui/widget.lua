if not isClient() then
    return
end
require("ISUI/Maps/ISMiniMap")
local PR = PhunRunners
local sandbox = SandboxVars.PhunZones
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local profileName = "PhunRunnersWidget"
PR.ui.widget = ISPanel:derive(profileName);
PR.ui.widget.instances = {}
local UI = PR.ui.widget

function UI.OnOpenPanel(playerObj, playerIndex)

    playerIndex = playerIndex or playerObj:getPlayerNum()

    if not UI.instances[playerIndex] then
        local core = getCore()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local width = 200 * FONT_SCALE
        local height = 20 * FONT_SCALE

        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2

        UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        UI.instances[playerIndex]:initialise();
        ISLayoutManager.RegisterWindow(profielName, PR.ui.widget, PR.ui.widget.instances[playerIndex])
    end

    UI.instances[playerIndex]:addToUIManager();
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
    o.data = {}

    o.moveWithMouse = true;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)

    return o;
end

function UI:RestoreLayout(name, layout)

    ISLayoutManager.DefaultRestoreWindow(self, layout)
    if name == profielName then
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

local calculatPips = function(risk)
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

function UI:setData(data)

    if data.zone then

        if data.zone.title then
            self.data.title = data.zone.title
            self.data.titleWidth = getTextManager():MeasureStringX(UIFont.Medium, data.zone.title) + 20
            if self.data.titleWidth > self.width then
                self.data.titleWidth.width = self.width
            end
            self.data.titleHeight = FONT_HGT_MEDIUM
        else
            self.data.title = nil
            self.data.titleWidth = 0
            self.data.titleHeight = 0
        end

        if data.zone.subtitle then
            self.data.subtitle = data.zone.subtitle
            self.data.subtitleWidth = getTextManager():MeasureStringX(UIFont.Small, data.zone.subtitle) + 20
            if self.data.subtitleWidth > self.width then
                self.data.subtitleWidth = self.width
            end
            self.data.subtitleHeight = FONT_HGT_SMALL
        else
            self.data.subtitle = nil
            self.data.subtitleWidth = 0
            self.data.subtitleHeight = 0
        end

        if data.zone.pvp then
            self.pvpTexture = getTexture("media/ui/pvpicon_on.png")
        else
            self.pvpTexture = nil
        end
    end

end

function UI:prerender()

    if (ISWorldMap_instance and ISWorldMap_instance:isVisible()) then
        return
    end

    ISPanel.prerender(self);

    local clock = UIManager.getClock()
    if clock and clock:isDateVisible() then
        -- print("clock is visible")
    end
    local x = 2
    local y = 2
    local txtColor = self.normalTextColor

    -- if sandbox.PhunZones_Widget and PhunRunners then
    --     local riskData = nil -- PhunZones:getRiskInfo(self.player, zone)

    --     if riskData then
    --         local colors = {
    --             r = 0.4,
    --             g = 0.4,
    --             b = 0.4,
    --             a = 1.0
    --         }
    --         if riskData then
    --             if riskData.modifier == nil then
    --                 -- assert old version
    --                 if riskData.restless == false or riskData.risk == 0 then
    --                     colors.g = 0.9
    --                 elseif riskData.risk <= 10 then
    --                     colors.g = 0.9
    --                     colors.r = 0.9
    --                 else
    --                     colors.r = 0.9
    --                 end
    --             else
    --                 -- new version which includes modifier
    --                 if riskData.modifier == 0 or riskData.risk == 0 then
    --                     colors.g = 0.9
    --                 elseif riskData.modifier and riskData.modifier < 90 then
    --                     colors.g = 0.9
    --                     colors.r = 0.9
    --                 else
    --                     colors.r = 0.9
    --                 end
    --             end

    --             for i = 1, riskData.pips do
    --                 self:drawRect(x + ((i - 1) * 7), y, 5, 5, colors.a, colors.r, colors.g, colors.b);
    --             end

    --             if self:isMouseOver() then
    --                 for i = riskData.pips + 1, 10 do
    --                     self:drawRectBorder(x + ((i - 1) * 7), y, 5, 5, 0.7, 0.4, 0.4, 0.4);
    --                 end
    --             end
    --         end
    --     end
    -- end
end
