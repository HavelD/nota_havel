local sensorInfo = {
	name = "FollowPathSimple",
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

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local getHeight = Spring.GetGroundHeight

local function ClearState(self)
	self.path_set = false
end

function Run(self, units, parameter)
	local path = parameter.pathArray -- array of Vec3
	
	-- validation first
	if not path or #path == 0 then
		Spring.Echo("FollowPath: No path provided or path is empty")
		return FAILURE
	end

    local useSelected = false
	if (parameter.selectedUnits ~= nil and type(parameter.selectedUnits) == "table" and #parameter.selectedUnits > 0) then
		Spring.Echo("FollowPath: Using selected units for path following.")
		useSelected = true
	else
		Spring.Echo("FollowPath: Using all command units for path following.")
	end
	local selectedUnits = useSelected and parameter.selectedUnits or units-- array of unit IDs
	
	-->>-------------FIXING Y coordinate
	for i, pos in ipairs(path) do
		pos.y = getHeight(pos.x, pos.z)
	end
	--<<-------------FIXING Y coordinate
	
	-- pick the spring command implementing the move
	local cmdID = CMD.MOVE

	Spring.Echo("FollowPath: Setting path with " .. #path .. " waypoints for " .. #selectedUnits .. " units.")

	-- give all path orders at once to all units
	for u = 1, #selectedUnits do
		local unitID = selectedUnits[u]

		-- verify unit exists before giving orders
		local unitX, unitY, unitZ = SpringGetUnitPosition(unitID)
		if unitX ~= nil then
			-- give first waypoint without shift to clear existing orders -- afterall i don't want that
			local firstWaypoint = path[1]
			SpringGiveOrderToUnit(unitID, cmdID, {firstWaypoint.x, firstWaypoint.y, firstWaypoint.z}, {})
			
			-- give remaining waypoints with shift to queue them
			for p = 2, #path do
				local waypoint = path[p]
				SpringGiveOrderToUnit(unitID, cmdID, {waypoint.x, waypoint.y, waypoint.z}, {"shift"})
			end
		else
			Spring.Echo("FollowPath: Unit " .. unitID .. " does not exist, skipping.")
		end
	end

	Spring.Echo("FollowPath: All path orders have been given to units.")
	return SUCCESS
end


function Reset(self)
	ClearState(self)
end
