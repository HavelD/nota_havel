local sensorInfo = {
	name = "ShowPath",
	desc = "Sends data to path display widget",
	author = "haveld",
	date = "2025-09-15",
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
return function(pathData)
    local unitID = units[1]
    if (Script.LuaUI('path_show')) then
        Spring.Echo("Sending path data to widget")
        Script.LuaUI.path_show(
            unitID, -- key
            { pathData = pathData } -- data
        )
    else
        Spring.Echo("Path debug widget not found")
    end
    
    return  { pathData = pathData }
end
