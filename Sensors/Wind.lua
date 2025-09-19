local sensorInfo = {
	name = "WindDirection",
	desc = "Return data of actual wind direction.",
	author = "haveld", -- original: "PepeAmpere"
	date = "2025-09-07",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local SpringGetWind = Spring.GetWind

-- @description return current wind statistics
return function()
	local dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = SpringGetWind()
	-- local dirX, dirY, dirZ, strength = SpringGetWind()
	-- Calculate azimuth (angle in radians from X axis, in XZ plane)
	local azimuth = math.atan2(dirZ, dirX)
	return {
		strength = strength,
		azimuth = azimuth
	}
end

-- TODO - return direction as vector

