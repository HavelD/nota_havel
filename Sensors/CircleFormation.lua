local sensorInfo = {
	name = "Peaks",
	desc = "List positions of unique hills on the map",
	author = "haveld",
	date = "2025-09-07",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 1 -- cache

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local getHeight = Spring.GetGroundHeight

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

-- maxheight = core.MissionInfo().areaHeight

-- @description return current wind statistics
return function(params)
    if params == nil then
        params = {}
    end

    -- Use selectedUnits or fallback to global units
    local unitList = params.selectedUnits or units
    if not unitList or #unitList == 0 then
        error("No units available for formation.")
    end

    -- Validate params.area
    if not params.area or #params.area ~= 4 then
        error("Invalid area parameter. Expected table with x, y, z, and radius.")
    end

    local FlyingHeight = 20 -- 10

    local centerX, centerY, centerZ, radius = params.area[1], params.area[2], params.area[3], params.area[4]
    local flyingHeight = getHeight(centerX, centerZ) + FlyingHeight
    local circleFormation = {Vec3(centerX, flyingHeight, centerZ)} -- first point is center

    local numUnits = #unitList
    local angleIncrement = (2 * math.pi) / (numUnits-1)

    for i = 0, numUnits - 1 do 
        local angle = i * angleIncrement
        local x = radius * math.cos(angle) -- + centerX --Relative to center
        local z = radius * math.sin(angle) -- + centerZ --Relative to center
        local y = 0 --getHeight(x, z) + FlyingHeight
        table.insert(circleFormation, Vec3(x, y, z))
    end

    return circleFormation
end
