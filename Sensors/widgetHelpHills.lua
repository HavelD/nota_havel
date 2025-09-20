local sensorInfo = {
	name = "HillsInfoWidgetData",
	desc = "Sends data to hills info widget",
	author = "haveld",
	date = "2025-09-10",
	license = "MIT",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local EVAL_PERIOD_DEFAULT = 1 -- cache - nothing changes on map

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT
	}
end

-- speedups
local SpringGetWind = Spring.GetWind

-- @description return current wind statistics
return function(peaksData)
    local unitID = 0 -- dummy, no unit associated
    if peaksData == nil then
        return {info="no data"}
    end
    
    local stepSize = peaksData.stepSize
    -- local hillHeightThreshold = peaksData.developer.threshold
    local gridHeight = peaksData.developer.gridHeightMap
    local localMax = peaksData.developer.localMaxMap
    local peaksList = peaksData.peaks

    local spotData = {}

    -- fill spot data as a list of positions and color types
    for x = 1, #localMax do
        for z = 1, #localMax[x] do
            
            local y = gridHeight[x][z] -- getHeight(x, z)
            
            local pointType = ""
            if localMax[x][z] then
                pointType = "max"
            elseif (peaksData.developer.threshold ~= nil) and (gridHeight[x][z] >= peaksData.developer.threshold) then
                pointType = "threshold"
            else
                pointType = "base"
            end

            table.insert(spotData, {position = Vec3(x * stepSize, y, z * stepSize), pointType = pointType})
        end
    end

    -- attach peaks as special points as last (so they are on top)
    for i = 1, #peaksList do
        local peak = peaksList[i]
        table.insert(spotData, {position = peak, pointType = "peak"})
    end

    if (Script.LuaUI('hills_show')) then
        -- Spring.Echo("Sending data to Hills Widget")
        Script.LuaUI.hills_show(
            unitID, -- key -- neccessary?
            {
                pointsData = spotData
            }
        )
    end
    return {	-- data
                pointsData = spotData,
            }
end

--  aktualna dilema - mam priamo v vykreslovacom widgete pocitat sipky? Alebo vsetko predpocitat tu a tam poslat len velky zoznam
--  Treba pozret ako sa to robi v inych widgetoch