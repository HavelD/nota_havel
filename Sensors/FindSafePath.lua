local sensorInfo = {
	name = "SafePath",
	desc = "Find a safe path between two positions",
	author = "haveld",
	date = "2025-09-13",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- actual, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local getHeight = Spring.GetGroundHeight

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local sizingFix = 2
local checkPerSquare = 2

-- speedups
local SpringGetUnitPosition = Spring.GetUnitPosition

-- ## Helper functions
--- @description Convert world coordinates to grid indices
local function worldToGrid(worldPos, stepSize)
    if not worldPos or not stepSize or stepSize <= 0 then
        return nil
    end

    local gridI = math.floor(worldPos.x / stepSize) + 1  -- X to I (row)
    local gridJ = math.floor(worldPos.z / stepSize) + 1  -- Z to J (column)

    return {gridI, gridJ}
end


--- @description Convert grid indices to world coordinates
local function gridToWorld(gridPos, stepSize)
    if not gridPos or not stepSize or stepSize <= 0 then
        return nil
    end
    
    local worldX = (gridPos[1] - 1) * stepSize + stepSize / 2
    local worldZ = (gridPos[2] - 1) * stepSize + stepSize / 2
    
    return Vec3(worldX, getHeight(worldX, worldZ), worldZ)
end


local function createBinaryGrid(safegrid)
    if not safegrid or not safegrid.developer or 
       not safegrid.developer.gridHeightMap or 
       not safegrid.developer.threshold then
        Logger.warn("FindSafePath", "Invalid safegrid structure")
        return nil
    end
    
    local heightMap = safegrid.developer.gridHeightMap
    local threshold = safegrid.developer.threshold
    local binaryGrid = {}
    
    for i = 1, #heightMap do
        binaryGrid[i] = {}
        for j = 1, #heightMap[i] do
            binaryGrid[i][j] = heightMap[i][j] < threshold -- Points below threshold are safe
        end
    end
    
    return binaryGrid
end


local function findClosestSafePoint(gridPos, binaryGrid)
    local maxRadius = 100 -- Magic number, Just performance limit
    if not gridPos or not binaryGrid then
        return nil
    end
    
    local gridHeight = #binaryGrid
    local gridWidth = gridHeight > 0 and #binaryGrid[1] or 0
    local startI, startJ = gridPos[1], gridPos[2]

    -->> Check grid and the need of search
    if gridHeight == 0 or gridWidth == 0 then
        return nil
    end
        -- If the current position is already safe, return it
    if startI >= 1 and startI <= gridHeight and startJ >= 1 and startJ <= gridWidth and
       binaryGrid[startI][startJ] then
        return gridPos
    end
    --<<
    
    -- Search in expanding circle
    for radius = 1, maxRadius do
        for di = -radius, radius do
            for dj = -radius, radius do
                if math.max(math.abs(di), math.abs(dj)) == radius then
                    local checkI, checkJ = startI + di, startJ + dj
                    if checkI >= 1 and checkI <= gridHeight and checkJ >= 1 and checkJ <= gridWidth and
                       binaryGrid[checkI][checkJ] then
                        return {checkI, checkJ}
                    end
                end
            end
        end
    end
    
    return nil -- No safe point found
end

-- maxheight = core.MissionInfo().areaHeight

--- @description return a safe path between two positions using BFS
--- @param startPoint table The starting position - {i, j} indices
--- @param endPoint table The ending position - {i, j} indices
--- @param grid table binary 2D grid representing safe (true) and unsafe (false) areas
--- @return table Path (grid indices) from A to B
function bfs(startPoint, endPoint, grid)
    if not grid or not startPoint or not endPoint then
        return {}
    end
    
    local gridHeight = #grid
    local gridWidth = gridHeight > 0 and #grid[1] or 0
    
    if gridHeight == 0 or gridWidth == 0 then
        return {}
    end
    
    local startI, startJ = startPoint[1], startPoint[2]
    local endI, endJ = endPoint[1], endPoint[2]
    
    -- Edges check
    if startI < 1 or startI > gridHeight or startJ < 1 or startJ > gridWidth or
       endI < 1 or endI > gridHeight or endJ < 1 or endJ > gridWidth then
        return {}
    end

    -- Setup
    local queue = {{startI, startJ}}
    local visited = {}
    local parent = {}
    
    for i = 1, gridHeight do
        visited[i] = {}
        parent[i] = {}
        for j = 1, gridWidth do
            visited[i][j] = false
            parent[i][j] = nil
        end
    end
    
    visited[startI][startJ] = true
    
    -- Directions to check: up, down, left, right + diagonals
    local directions = {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1},  -- cardinal
        {-1, -1}, {-1, 1}, {1, -1}, {1, 1}  -- diagonal
    }
    
    local queueIndex = 1
    while queueIndex <= #queue do
        local current = queue[queueIndex]
        local curI, curJ = current[1], current[2]
        queueIndex = queueIndex + 1
        
        if curI == endI and curJ == endJ then
            -- Reconstruct path
            local path = {}
            local pathI, pathJ = endI, endJ
            
            while pathI and pathJ do
                table.insert(path, 1, {pathI, pathJ}) -- push to front
                local parentCell = parent[pathI][pathJ]
                if parentCell then
                    pathI, pathJ = parentCell[1], parentCell[2]
                else
                    break
                end
            end
            
            return path
        end
        
        
        for _, dir in ipairs(directions) do
            -- Check neighbors 
            local newI = curI + dir[1]
            local newJ = curJ + dir[2]
            
            -- Check bounds and if cell is safe and not visited
            if newI >= 1 and newI <= gridHeight and newJ >= 1 and newJ <= gridWidth and
               grid[newI][newJ] and not visited[newI][newJ] then
                    visited[newI][newJ] = true
                    parent[newI][newJ] = {curI, curJ}
                    table.insert(queue, {newI, newJ})
            end
        end
    end
    
    return {} -- No path found
end


--- @description return a safe path between two positions
--- @param startpos table|number The starting position as a Vec3 or a unit ID.
--- @param endpos table|number The ending position as a Vec3 or a unit ID.
--- @param safegrid Peaks.lua output - specifically we will use "stepSize", "developer.gridHeightMap" and "developer.threshold"
--- @return table A table representing the calculated path. Returns an empty table if the input is invalid.
return function(startPosition, endPosition, safegrid)
    local startpos = startPosition
    local endpos = endPosition

    if safegrid == nil then
        Logger.warn("FindSafePath", "safegrid parameter is nil.")
        return {}
    end

    if type(startpos) == "number" then
        local x,y,z = SpringGetUnitPosition(startpos)
        startpos = Vec3(x,y,z)
    elseif type(startpos) ~= "table" then
        Logger.warn("FindSafePath", "Invalid start position type:", type(startpos))
        return {}
    end

    if type(endpos) == "number" then
        local x,y,z = SpringGetUnitPosition(endpos)
        endpos = Vec3(x,y,z)
    elseif type(endpos) ~= "table" then
        Logger.warn("FindSafePath", "Invalid end position type:", type(endpos))
        return {}
    end

    if startpos == nil or endpos == nil then
        Logger.warn("FindSafePath", "Start or end position is nil.")
        return {}
    end

    if not safegrid.stepSize or not safegrid.developer then
        Logger.warn("FindSafePath", "Invalid safegrid structure - missing stepSize or developer data")
        return {}
    end

    -- Binary grid from safegrid
    local binaryGrid = createBinaryGrid(safegrid)
    if not binaryGrid then
        Logger.warn("FindSafePath", "Failed to create binary grid")
        return {}
    end

    -->> Translating positions to grid coordinates
    local startGridPos = worldToGrid(startpos, safegrid.stepSize)
    local endGridPos = worldToGrid(endpos, safegrid.stepSize)
    
    local tempFirstStartGridPos = startGridPos
    local tempFirstEndGridPos = endGridPos

    local gridHeight = #binaryGrid
    local gridWidth = gridHeight > 0 and #binaryGrid[1] or 0
    if startGridPos[1] < 1 or startGridPos[1] > gridHeight or 
       startGridPos[2] < 1 or startGridPos[2] > gridWidth or
       endGridPos[1] < 1 or endGridPos[1] > gridHeight or 
       endGridPos[2] < 1 or endGridPos[2] > gridWidth then
        Logger.warn("FindSafePath", "Start or end position is outside grid bounds")
        return {}
    end
    ---<< 

    -->> If start or end position is not in safe area, find closest safe point
    if not binaryGrid[startGridPos[1]][startGridPos[2]] then
        startGridPos = findClosestSafePoint(startGridPos, binaryGrid)
        -- Spring.Echo(string.format("FindSafePath: Found safe start position at grid [%d, %d]", startGridPos[1], startGridPos[2]))
    end
    if not binaryGrid[endGridPos[1]][endGridPos[2]] then
        endGridPos = findClosestSafePoint(endGridPos, binaryGrid)
        -- Spring.Echo(string.format("FindSafePath: Found safe end position at grid [%d, %d]", endGridPos[1], endGridPos[2]))
    end
    --<<

    -- BFS for shortest (first) path between start and end
    local gridPath = bfs(startGridPos, endGridPos, binaryGrid)
    if #gridPath == 0 then
        Logger.warn("FindSafePath", "No safe path found between positions")
        return {}
    end

    -- Path (in grid) to world real coordinates
    local worldPath = {}
    for i, gridPos in ipairs(gridPath) do
        local worldPos = gridToWorld(gridPos, safegrid.stepSize)
        if worldPos then
            table.insert(worldPath, worldPos)
        else
            Logger.warn("FindSafePath", "Failed to convert grid position back to world coordinates")
            return {}
        end
    end

    return {
        path = worldPath, 
        developer = { -- DEBUG
            startPosition = startpos, 
            endPosition = endpos,
            safeStart = gridToWorld(startGridPos, safegrid.stepSize),
            safeEnd = gridToWorld(endGridPos, safegrid.stepSize),
            firstStartGridPos = gridToWorld(tempFirstStartGridPos, safegrid.stepSize),
            firstEndGridPos = gridToWorld(tempFirstEndGridPos, safegrid.stepSize),
            safeGridBinary = binaryGrid,
            stepsize = safegrid.stepSize,
        }
    }
end
