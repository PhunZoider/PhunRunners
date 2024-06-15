PhunRunnersUI = ISPanel:derive("PhunRunnersUI");
PhunRunnersUI.instance = nil;
local PhunRunners = PhunRunners

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14

function PhunRunnersUI.OnOpenPanel(playerObj, isRestless)

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 600 * FONT_SCALE
    local height = 200 * FONT_SCALE
    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    PhunRunnersUI.instance = PhunRunnersUI:new(x, 50, width, height, playerObj);
    PhunRunnersUI.instance:initialise();
    PhunRunnersUI.instance:instantiate();
    PhunRunnersUI.instance.player = playerObj
    PhunRunnersUI.instance.isRestless = isRestless
    PhunRunnersUI.instance:addToUIManager();
    triggerEvent(PhunRunners.events.OnPhunRunnersUIOpened, PhunRunnersUI.instance)
    return PhunRunnersUI.instance;

end

function PhunRunnersUI:initialise()
    ISPanel.initialise(self);
end

-- function PhunRunnersUI:createChildren()
--     ISPanel.createChildren(self);
--     local FONT_HGT = getTextManager():getFontHeight(UIFont.Medium);

--     local x = 10
--     local y = 10
--     local h = 20;
--     local w = self.width - 20;

-- end

function PhunRunnersUI:close()
    self:setVisible(false);
    self:removeFromUIManager();
    PhunRunnersUI.instance = nil
end

function PhunRunnersUI:render()

    if self.isRestless ~= nil then
        local data = self.player:getModData().PhunRunners;

        local txt = self.isRestless and getText("IGUI_PhunRunners_ZedsAreRestless") or
                        getText("IGUI_PhunRunners_ZedsAreSettling");
        self:drawTextCentre(txt, self.width / 2, 75, 255, 255, 240, self.alphaBits, UIFont.NewLarge);

        if getTimestamp() > self.autoCloseTimestamp then
            self.alphaBits = self.alphaBits - 0.05
            if self.alphaBits <= 0 then
                self:close()
            end
        else
            self.alphaBits = self.alphaBits + 0.05
            if self.alphaBits >= 1 then
                self.alphaBits = 1
            end
        end
    end
end

function PhunRunnersUI:new(x, y, width, height, player)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;
    o.autoCloseTimestamp = getTimestamp() + (5);
    o.alphaBits = 0
    o.variableColor = {
        r = 0.9,
        g = 0.55,
        b = 0.1,
        a = 1
    };
    o.borderColor = {
        r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.0
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o.moveWithMouse = false;
    o.isRestless = false;
    return o;
end
