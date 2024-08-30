if not isClient() then
    return
end
require "ISUI/ISCollapsableWindowJoypad"
PhunRunnersWidget = ISCollapsableWindowJoypad:derive("PhunRunnersWidget");
PhunRunnersWidget.instances = {}
local PhunRunners = PhunRunners
local PhunZones = PhunZones
local PhunStats = PhunStats
local sandbox = SandboxVars.PhunRunners

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14

function PhunRunnersWidget.OnOpenPanel(playerObj)

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local width = 200 * FONT_SCALE
    local height = 50 * FONT_SCALE
    local x = (core:getScreenWidth() - width) / 2
    local y = 20
    local pIndex = playerObj:getPlayerNum()
    local instances = PhunRunnersWidget.instances
    if instances[pIndex] then
        local instance = instances[pIndex]
        if not instance:isVisible() then
            instances[pIndex]:addToUIManager();
            instances[pIndex]:setVisible(true);
        end
        return instance
    end
    PhunRunnersWidget.instances[pIndex] = PhunRunnersWidget:new(x, y, width, height, playerObj);
    local instance = PhunRunnersWidget.instances[pIndex]
    instance:initialise();
    instance:addToUIManager();

    ISLayoutManager.RegisterWindow('PhunRunnersWidget', PhunRunnersWidget, instance)

    return instance;

end

function PhunRunnersWidget:close()
    self:setVisible(false);
    self:removeFromUIManager();
    PhunRunnersWidget.instances[self.pIndex] = nil
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

local emptyColors = {
    r = 0.4,
    g = 0.4,
    b = 0.4,
    a = 1.0
}

local greenPips = {
    r = 0.0,
    g = 1,
    b = 0.0,
    a = 1.0
}

local yellowPips = {
    r = 1,
    g = 1,
    b = 0,
    a = 1.0
}

local redPips = {
    r = 1,
    g = 0,
    b = 0,
    a = 1.0
}

local lineY = 0
function PhunRunnersWidget:printLine(text)

    self:drawText(text, 10, lineY, 0.7, 0.7, 0.7, 1.0, UIFont.Small);
    lineY = lineY + FONT_HGT_SMALL + 1

end

function PhunRunnersWidget:prerender()

    ISCollapsableWindowJoypad.prerender(self);
    lineY = 25
    local risk = PhunRunners:getPlayerData(self.player)
    local env = PhunRunners.env or {
        light = {},
        fog = {},
        moon = {},
        info = {}
    }
    -- local zone = PhunZones.players[self.player:getUsername()] or {}

    -- local riskLevel = math.floor(((risk.value / risk.total) * 100) + 0.5)

    local x = 10
    local y = 25

    -- self:drawText(risk.season or "Unknown Season", x, y, 0.7, 0.7, 0.7, 1.0, UIFont.Medium);

    -- y = y + FONT_HGT_SMALL + 1
    self:printLine("PhunRunner");
    self:printLine(string.format("    Risk: %.2f", risk.risk or 0))
    self:printLine(string.format("    val: %.2f", env.value or 0))
    self:printLine(string.format("    Spawn Sprinters: %s", risk.spawnSprinters == true and "True" or "False"));
    self:printLine(string.format("    Restless: %s", risk.restless == true and "True" or "False"));

    self:printLine(string.format("    Season: %s", env.season or "Unknown Season"));
    self:printLine(string.format("    Darkness Modifier: %i%%", env.value or 0));
    self:printLine("Light")
    self:printLine(string.format("    adjustedLightIntensity: %.2f", env.light.adjustedLightIntensity or 0));
    self:printLine(string.format("    intensity: %.2f", env.light.intensity or 0));

    self:printLine("Fog")
    self:printLine(string.format("    intensity: %.2f", env.fog.intensity or 0));

    self:printLine("Moon")
    self:printLine(string.format("    phase: %s", env.moon.phase or 0));
    self:printLine(string.format("    category: %s", env.moon.category or 0));

    self:printLine("Info")
    self:printLine(string.format("    night: %i", env.info.night or 0));
    self:printLine(string.format("    time: %i:%i", env.info.hour or 0, env.info.minute or 0));
    self:printLine(string.format("    dusk: %i", env.info.dusk or 0));
    self:printLine(string.format("    dawn: %i", env.info.dawn or 0));
    self:printLine(string.format("    timeToDusk: %i", env.info.timeToDusk or 0));
    self:printLine(string.format("    timeToDawn: %i", env.info.timeToDawn or 0));

    y = y + FONT_HGT_SMALL + 1

end

function PhunRunnersWidget:new(x, y, width, height, player)
    local o = {};
    o = ISCollapsableWindowJoypad:new(x, y, width, height, player);
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
        a = 0.5
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
    o.cached = {}
    o.pIndex = player:getPlayerNum()
    o.player = player
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o.downX = nil;
    o.downY = nil;
    o.title = "Climate Sensor"
    return o;
end
