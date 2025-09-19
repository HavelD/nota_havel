local sensorInfo = {
	name = "testLineDebug",
	desc = "just basic example demo within local development",
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

-- @description return current wind statistics
return function()
	if #units > 0 then
		local unitID = units[1]
		local x,y,z = Spring.GetUnitPosition(unitID)
        
		if (Script.LuaUI('testDebug_update')) then
			Spring.Echo("Sending wind direction data to widget")
			Script.LuaUI.testDebug_update(
				unitID, -- key
				{	-- data
					startPos = Vec3(x,y,z), 
					endPos = Vec3(x,y,z) + Vec3(-10,0,10)
				}
			)
		end
		return {	-- data
					startPos = Vec3(x,y,z), 
					endPos = Vec3(x,y,z) + Vec3(-10,0,10)
				}
	end
end

--- Upravovanim tohto suboru sa menili veci v hre - smer ciary