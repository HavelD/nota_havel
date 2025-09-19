local sensorInfo = {
	name = "CommanderWindArrow",
	desc = "Sends data to air direction arrow widget",
	author = "haveld", -- original: "PepeAmpere"
	date = "2025-09-08",
	license = "MIT",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT
	}
end

-- speedups
local SpringGetWind = Spring.GetWind

-- @description return current wind statistics
return function()
	if #units > 0 then
		local unitID = units[1]
		local x,y,z = Spring.GetUnitPosition(unitID)
        
        --  TODO Change to get this info from custom wind sensor (nota_havel_hlaa/Sensors/Wind.lua)
        local dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = SpringGetWind()
        local azimuth = math.atan2(dirZ, dirX)

		if (Script.LuaUI('wind_direction_debug')) then
			Spring.Echo("Sending wind direction data to widget")
			Script.LuaUI.wind_direction_debug(
				unitID, -- key
				{	-- data
					unitPos = Vec3(x,y,z),
                    windStrength = strength,
                    windAzimuth = azimuth
				}
			)
		end
		return {	-- data
					unitPos = Vec3(x,y,z),
                    windStrength = strength,
                    windAzimuth = azimuth
				}
	end
end
