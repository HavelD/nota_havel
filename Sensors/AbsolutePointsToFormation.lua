local sensorInfo = {
	name = "PointsToFormation",
	desc = "Convert absolute points to formation (relative positions) with first point as anchor",
	author = "haveld",
	date = "2025-09-07",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

local SpringGetUnitPosition = Spring.GetUnitPosition
-- maxheight = core.MissionInfo().areaHeight

-- @description return current wind statistics
return function(mapPoints, allowGroups, unitSelection)
    -- Takes absolute positions and return a formation with furthest point as first (so everyone should reach its position before this position is reached)
    -- units

    -- go trough all units and points, find furthest point for every unit by distance. Then return the smallest distance form this list
    if mapPoints == nil or #mapPoints == 0 then
        Spring.Echo("PointsToFormation: No map points provided")
        return nil
    end

    if (mapPoints[1].x == nil or mapPoints[1].z == nil) then
        Spring.Echo("PointsToFormation: Missing x or z in point data", mapPoints[1].x, mapPoints[1].z)
        return nil
    end

    local selectedUnits = unitSelection ~= nil and unitSelection or units

    local anchorPoint = nil
    local minMaxDist_global = math.huge

    for _, unit in ipairs(selectedUnits) do
        local pointX, pointY, pointZ = SpringGetUnitPosition(unit)
        -- local unitPosition = Vec3(pointX, pointY, pointZ)

        local maxDist_unit = 0
        local furtherstPoint_unit = nil
        for _, pointData in ipairs(mapPoints) do
            local distance = math.sqrt((pointData.x - pointX)^2 + (pointData.z - pointZ)^2)
            if (furtherstPoint_unit == nil) or (distance > maxDist_unit) then
                furtherstPoint_unit = pointData
                maxDist_unit = distance
            end
        end

        if maxDist_unit < minMaxDist_global then
            minMaxDist_global = maxDist_unit
            anchorPoint = furtherstPoint_unit
        end
    end

    if anchorPoint == nil then
        return nil
    end

    -- Create the formation with the anchor point
    local formation = {anchorPoint}
    for _, pointData in ipairs(mapPoints) do
        if pointData ~= anchorPoint then --skip anchor point itself
            local relativePosition = pointData - anchorPoint -- anchorPoint - pointData
            table.insert(formation, relativePosition)
        end
    end

    if #selectedUnits > #formation then
        if allowGroups == nil or not allowGroups then
            Logger.warn("PointsToFormation", "More units [" .. #selectedUnits .. "] than formation points [" .. #formation .. "] - Try setting allowGroups=true")
        elseif allowGroups ~= nil and allowGroups then
            -- Spring.Echo("PointsToFormation: INFO - Groups are allowed - repeating formation to fit units")
            -- trim formation to number of units
            local iterator = math.huge
            for i = 1, (#selectedUnits - #formation) do
                if iterator > #formation then
                    iterator = 1
                    local randomPosX = math.random(10, 40) * ((math.random(0,1) == 0) and -1 or 1) -- random x pos around anchor
                    local randomPosZ = math.random(10, 40) * ((math.random(0,1) == 0) and -1 or 1) -- random z pos around anchor                
                    table.insert(formation, Vec3(randomPosX, 0, randomPosZ)) -- relative position to anchor
                else
                    table.insert(formation, formation[iterator]) -- We dont need random pos here, because These positions do not trigger "position reached" flag - so I don't care
                end
                iterator = iterator + 1
            end
        end
    end

    return formation
end
