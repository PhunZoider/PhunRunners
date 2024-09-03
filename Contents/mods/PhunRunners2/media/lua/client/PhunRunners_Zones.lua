local defaultZones = { -- Void
{
    x = 21000,
    y = 6000,
    x2 = 24899,
    y2 = 13499,
    difficulty = 0,
    title = "The Void"
} -- West Point
, {
    x = 11100,
    y = 6580,
    x2 = 13199,
    y2 = 7499,
    difficulty = 2,
    title = "West Point"
} -- March Ridge
, {
    x = 9600,
    y = 12600,
    x2 = 10499,
    y2 = 13199,
    difficulty = 2,
    title = "March Ridge"
} -- Muldraugh
, {
    x = 10516,
    y = 9300,
    x2 = 11000,
    y2 = 10700,
    difficulty = 1,
    title = "Muldraugh"
}, -- Rosewood
{
    x = 7800,
    y = 10800,
    x2 = 8699,
    y2 = 12299,
    difficulty = 0,
    title = "Rosewood"
} -- Riverside
, {
    x = 5400,
    y = 5100,
    x2 = 6899,
    y2 = 5699,
    difficulty = 2,
    title = "Riverside"
}, --  Louisville
{
    x = 11700,
    y = 300,
    x2 = 14699,
    y2 = 5975,
    difficulty = 4,
    title = "Louisville"
}, {
    -- Everywhere else
    x = 0,
    y = 0,
    x2 = 999999,
    y2 = 999999,
    difficulty = 1,
    title = "Kentucky"
}}

function PhunRunners:getZoneInfo()

end

if PhunZoneRRRs then
    Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
        function(playerObj, location, old)

            if playerObj:isLocalPlayer() then
                if playerObj:getModData().PhunRunnersZone == nil then
                    playerObj:getModData().PhunRunnersZone = {}
                end
                if playerObj:getModData().PhunRunnersZone.key ~= location.key then
                    playerObj:getModData().PhunRunnersZone = location
                    PhunRunners:updatePlayer(playerObj)
                end
            end
        end)
else

    local function getDistance(x1, y1, x2, y2)
        return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
    end
    local pCache = {}

    Events.OnPlayerMove.Add(function(playerObj)

        if playerObj:isLocalPlayer() then
            local name = playerObj:getUsername()
            if not pCache[name] then
                pCache[name] = {
                    x = 0,
                    y = 0
                }
            end
            local x, y = playerObj:getX(), playerObj:getY()

            local distance = getDistance(pCache[name].x, pCache[name].y, x, y)
            if distance > 2 then
                pCache[name] = {
                    x = x,
                    y = y
                }
                for _, z in ipairs(defaultZones) do
                    if x > z.x and x < z.x2 and y > z.y and y < z.y2 then
                        if playerObj:getModData().PhunRunnersZone ~= z.title then
                            playerObj:getModData().PhunRunnersZone = z.title
                            PhunRunners:updatePlayer(playerObj)
                        end
                        break
                    end
                end
            end

        end

    end)
end
