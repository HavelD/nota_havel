local sensorInfo = {
	name = "ClosestUnitsByCategory",
	desc = "List positions of closest units by category",
	author = "haveld",
	date = "2025-09-07",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local SpringGetWind = Spring.GetWind
local getHeight = Spring.GetGroundHeight

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local sizingFix = 2
local checkPerSquare = 2

-- maxheight = core.MissionInfo().areaHeight

-- Categories.Common.immobile
-- Categories.Common.transports
-- Categories.Common.groundUnits

-- @description return current wind statistics
return function(params)
    if params == nil then
        params = {}
    end

    -- Spring.Echo("UnitDefs", UnitDefs)

    local category = params.category  -- No Default - using nil means no thresholding
    local maxUnits = params.maxUnits
    local center = params.center
    local allUnits = params.units or units -- all units if not specified

    if category == nil then
        Logger.warn("ClosestUnitsByCategory", "No category provided")
        return {}
    elseif center == nil then
        Logger.warn("ClosestUnitsByCategory", "No center provided - cannot compute distances")
        return {}
    end

    if type(category) ~= "table" then
        category = {category}
    end

    local filteredUnits = {}
    for _, unit in ipairs(allUnits) do
        local thisUnitDefID = Spring.GetUnitDefID(unit)
		if (category[thisUnitDefID] ~= nil) then -- in category
			filteredUnits[#filteredUnits + 1] = unit
		end
    end
    -- Spring.Echo("Number of selected units", #allUnits)
    -- Spring.Echo("Number of filtered units", #filteredUnits)

    
    table.sort(filteredUnits,
        function(a, b)
            local ax, ay, az = Spring.GetUnitPosition(a)
            local bx, by, bz = Spring.GetUnitPosition(b)
            local distA = (ax - center.x)^2 + (az - center.z)^2
            local distB = (bx - center.x)^2 + (bz - center.z)^2
            return distA < distB
        end)

    if maxUnits ~= nil and #filteredUnits > maxUnits then
        while #filteredUnits > maxUnits do
            table.remove(filteredUnits)
        end
    end

	return filteredUnits
end
