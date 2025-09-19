local sensorInfo = {
	name = "FollowPathOLD",
	desc = "Follow a path defined by a series of points",
	author = "haveld",
	date = "2025-09-12",
	license = "notAlicense",
}

function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Move to defined position following a path",
		parameterDefs = {
			{ 
				name = "selectedUnits", -- relative formation
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "{}",
			},
			{ 
				name = "pathArray", -- relative formation
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			}
		}
	}
end

-- constants
local THRESHOLD_STEP = 25
local THRESHOLD_DEFAULT = 50

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local SpringCategory = Spring.GetUnitDefID
local airUnits = Categories.Common.airUnits
local isDead = Spring.GetUnitIsDead

local getHeight = Spring.GetGroundHeight

local function ClearState(self)
	self.threshold = THRESHOLD_DEFAULT
	self.currentWaypointIndex = 1
	self.unitWaypoints = {} -- track current waypoint for each unit
end

function Run(self, units, parameter)
	-->>-------------DEBUG
	-- local path = parameter.pathArray
	
	-- for _, unitID in ipairs(units) do
	-- 	Spring.Echo("Unit ID:", unitID)
	-- end

	-- Spring.Echo("Path Points size:", #path)
	-- for _, pos in ipairs(path) do
	-- 	Spring.Echo("Path Point:", pos.x, pos.y, pos.z)
	-- end
	--<<-------------DEBUG

	-->>-------------TEMP
	self.threshold = THRESHOLD_DEFAULT
	--<<*------------TEMP

	local path = parameter.pathArray -- array of Vec3
	local useSelected = false
	if (parameter.selectedUnits ~= nil and type(parameter.selectedUnits) == "table" and #parameter.selectedUnits > 0) then
		-- Spring.Echo("FollowPath: Using selected units for path following.")
		useSelected = true
	else
		-- Spring.Echo("FollowPath: Using all command units for path following.")
	end
	local selectedUnits = useSelected and parameter.selectedUnits or units-- array of unit IDs

	-->>-------------FIXING Y coordinate
	for i, pos in ipairs(path) do
		pos.y = getHeight(pos.x, pos.z)
	end
	--<<-------------FIXING Y coordinate

	if not path or #path == 0 then
		Logger.warn("FollowPath", "No path provided or path is empty")
		return FAILURE
	end
	
	if not self.unitWaypoints then
		self.unitWaypoints = {}
	end
	
	local cmdID = CMD.MOVE -- Spring command (source: Trello)
	local allUnitsFinished = true

	for u = 1, #selectedUnits do
		local unitID = selectedUnits[u]
		if not isDead(unitID) then -- skip dead units

			-- Height and Threshold correction for Flying units
			local heightCorrection = 0
			local thresholdCorrection = 0
			local thisUnitDefID = SpringCategory(unitID)
			if (airUnits[thisUnitDefID] ~= nil) then -- in category
				-- Spring.Echo("Unit is flying, applying height correction.")
				heightCorrection = 20 -- arbitrary value for height correction
				thresholdCorrection = 100 -- increase threshold for flying units
			end
			
			if not self.unitWaypoints[unitID] then -- Initialize waypoint index if does not yet exist
				self.unitWaypoints[unitID] = 1
			end

			local currentWaypointIndex = self.unitWaypoints[unitID]

			if currentWaypointIndex <= #path then -- if unit has a path still to follow and is not finished
				allUnitsFinished = false
				
				local unitX, unitY, unitZ = SpringGetUnitPosition(unitID) -- current unit position
				if unitX ~= nil then
					-- unit still exists (does live) -- maybe Spring.ValidUnitID ?? 

					local unitPosition = Vec3(unitX, unitY, unitZ)
					local targetWaypoint = path[currentWaypointIndex] + Vec3(0, heightCorrection, 0)
					
					-- Is Close enough to go to next?? 
					-- local distance = unitPosition:Distance(targetWaypoint)
					local distance = math.sqrt((unitPosition.x - targetWaypoint.x)^2 + (unitPosition.z - targetWaypoint.z)^2) -- Ignoring Height
					-- Spring.Echo("FollowPath: Unit " .. unitID .. " distance to waypoint " .. currentWaypointIndex .. " is " .. distance)
					if distance < (self.threshold + thresholdCorrection) then
						-- move to next waypoint
						self.unitWaypoints[unitID] = currentWaypointIndex + 1
						
						-- check if there's a next waypoint
						if self.unitWaypoints[unitID] <= #path then
							local nextWaypoint = path[self.unitWaypoints[unitID]] + Vec3(0, heightCorrection, 0)
							SpringGiveOrderToUnit(unitID, cmdID, nextWaypoint:AsSpringVector(), {})
						end
					else
						-- still moving to current waypoint
						SpringGiveOrderToUnit(unitID, cmdID, targetWaypoint:AsSpringVector(), {})
					end
				end
			end
		end
	end
	
	-- returning SUCCESS if all units finished their paths
	if allUnitsFinished then
		return SUCCESS
	else
		return RUNNING
	end
	return SUCCESS
end


function Reset(self)
	ClearState(self)
end
