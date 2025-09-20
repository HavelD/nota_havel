local sensorInfo = {
	name = "Peaks",
	desc = "List positions of unique hills on the map",
	author = "haveld",
	date = "2025-09-07",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 1 -- cache - nothing changes on map

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local SpringGetWind = Spring.GetWind
-- local getHeight = Spring.GetGroundHeight

function getHeight(x, z)
    local r = 25
    -- local heightSum = 0
    -- local count = 0
    local maxH = -math.huge
    for _, dX in ipairs({-r, 0, r}) do
        for _, dZ in ipairs({-r, 0, r}) do
            local h = Spring.GetGroundHeight(x + dX, z + dZ)
            -- heightSum = heightSum + h
            -- count = count + 1
            if h > maxH then
                maxH = h
            end
        end
    end

    -- local average = heightSum / count
    return maxH
end

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local sizingFix = 2
local checkPerSquare = 2

-- maxheight = core.MissionInfo().areaHeight

-- @description return current wind statistics
return function(params)
    if params == nil then
        params = {}
    end

    local threshold = params.hillHeightThreshold  -- No Default - using nil means no thresholding
    -- no-parameter handling - if granularity (in map size units - e.g. 256 is good start)
    local areaCheckStep = (params.checkGranularity ~= nil) and params.checkGranularity or (mapWidth / (checkPerSquare * Game.mapX * sizingFix)) -- should be 4 times (2x2) per square

    local maxIndexX = math.floor(mapWidth / areaCheckStep)
    local maxIndexZ = math.floor(mapHeight / areaCheckStep)
    local gridHeight = {}
    local aboveThreshold = {}
    local mapMinHeight = math.huge

    -- Create Height Map
    for x = 1, maxIndexX do
        gridHeight[x] = {}
        aboveThreshold[x] = {}
        for z = 1, maxIndexZ do
            local heightHere = getHeight(x * areaCheckStep, z * areaCheckStep)
            gridHeight[x][z] = heightHere --Vec3(x * areaCheckStep, heightHere, z * areaCheckStep)
            if threshold ~= nil then
                aboveThreshold[x][z] = (heightHere >= threshold) and true or false -- if no threshold given, all are false
            end
            
            -- Update map lowest point height
            if heightHere < mapMinHeight then
                mapMinHeight = heightHere
            end
        end
    end

    -- kernel - filtering and keeping local max height and plateaus
    -- looking in 4 directions - N, E, S, W
    -- if point is higher or equal than all 4 neighbours, it is local max, add to new grid a true value, else false. it is a flag that it is local max
    local kernel = {
        { 0,  1}, -- N
        { 1,  0}, -- E
        { 0, -1}, -- S
        {-1,  0}, -- W
    }
    local localMax = {}
    for x = 1, maxIndexX do
        localMax[x] = {}
        for z = 1, maxIndexZ do
            local isLocalMax = false
            if (gridHeight[x][z] > (mapMinHeight + 1)) then -- or (threshold ~= nil and not aboveThreshold[x][z]) then
                isLocalMax = true
                for i = 1, #kernel do
                    local k = kernel[i]
                    local neighborX = x + k[1]
                    local neighborZ = z + k[2]
                    if neighborX >= 1 and neighborX <= maxIndexX and neighborZ >= 1 and neighborZ <= maxIndexZ then
                        if gridHeight[neighborX][neighborZ] > gridHeight[x][z] then
                            isLocalMax = false
                            break
                        end
                    end
                end
            end
            localMax[x][z] = isLocalMax
        end
    end

    -- going through the localMax grid, when finding true, take its position (x and z index) and start flood fill to find all connected points. In another grid with same size flag fields that had been checked already.
    -- In the flood fill, calculate average position of all connected points
    local checked = {}
    local peaks = {}
    for x = 1, maxIndexX do
        checked[x] = {}
        for z = 1, maxIndexZ do
            checked[x][z] = false
        end
    end
    -- flood filling info. Grid is checked from top left corner going trough whole first row, then second and so on.
    -- When finding true in localMax grid, start flood fill from this point. With information above, we check first left, down, right. No up, as it would be hit earlier and that is not possible.
    local function FloodFillAVG(startX, startZ)
        local toCheck = {}
        table.insert(toCheck, {startX, startZ})
        local sumX = 0
        local sumZ = 0
        local count = 0

        while #toCheck > 0 do
            local current = table.remove(toCheck, 1) -- remove first element (FIFO)
            local cx = current[1]
            local cz = current[2]

            if cx >= 1 and cx <= maxIndexX and cz >= 1 and cz <= maxIndexZ then -- in bounds
                if not checked[cx][cz] and localMax[cx][cz] then
                    checked[cx][cz] = true
                    sumX = sumX + cx
                    sumZ = sumZ + cz
                    count = count + 1

                    -- Neighbors check
                    table.insert(toCheck, {cx - 1, cz}) -- left
                    table.insert(toCheck, {cx + 1, cz}) -- right
                    table.insert(toCheck, {cx, cz - 1}) -- down
                    table.insert(toCheck, {cx, cz + 1}) -- up
                end
            end
        end
        
        if count == 0 then
            return nil -- should not happen, but just in case
        end
        -- count is always > 0 as we start only from true localMax point
        return {x = sumX / count, z = sumZ / count}
    end

    -- find all peaks using flood fill
    local peaks = {}
    for x = 1, maxIndexX do
        for z = 1, maxIndexZ do
            if localMax[x][z] and not checked[x][z] then
                local peakPos = FloodFillAVG(x, z)
                local peakX = peakPos.x * areaCheckStep
                local peakZ = peakPos.z * areaCheckStep
                peaks[#peaks + 1] = Vec3(peakX, getHeight(peakX, peakZ), peakZ)
            end
        end
    end

    -- Putting it here just for ease and less files
    -- But yes, I could create separate sensor that removes points that are closeset to given list of different points
    if params.removeClosest ~= nil then
        local removeList = params.removeClosest
        if type(removeList) ~= "table" then
            removeList = {removeList}
        end

        local toBeRemoved = {}
        for _, removePos in ipairs(removeList) do
            if (removePos.x ~= nil and removePos.z ~= nil) then
                local closestIndex = nil
                local closestDist = math.huge
                for i = 1, #peaks do
                    local peak = peaks[i]
                    local dist = math.sqrt((peak.x - removePos.x)^2 + (peak.z - removePos.z)^2)
                    if dist < closestDist then
                        closestDist = dist
                        closestIndex = i
                    end
                end
                if closestIndex ~= nil then
                    table.insert(toBeRemoved, closestIndex)
                end
            end
        end

        -- Remove the marked peaks
        for i = #toBeRemoved, 1, -1 do
            table.remove(peaks, toBeRemoved[i])
        end
    end


	return {
        peaks = peaks,
        stepSize = areaCheckStep,
        developer = {
            minHeight = mapMinHeight,
            threshold = threshold,
            gridHeightMap = gridHeight,
            localMaxMap = localMax
        }
	}
end
