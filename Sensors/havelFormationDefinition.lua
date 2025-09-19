local sensorInfo = {
	name = "FormationDefinition",
	desc = "Return definition of the formation based on name key",
	author = "haveld", -- original: "PepeAmpere"
	date = "2025-09-09",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- instant, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT
	}
end

local formationDefinitions = {
	-- taken from NOE formations, \games\nota-xxx.sdd\LuaRules\Configs\noe\formations.lua
	["line"] = {
		name = "line",
		-- positions(count): returns a table of `count` positions {x, z}
		-- sequence: {0,0}, {-1,0}, {1,0}, {-2,0}, {2,0}, ...
		positions = function(count)
			local positions = {}
			for i = 1, count do
				local x = 1 + math.floor((i-1) / 2) * (1 - 2* (i % 2)) -- offsetting to remove zero position in the middle - that is place for maverick
				positions[i] = {x, 0}
			end
			return positions
		end,
		generated = true,
		defaults = {    
			spacing = Vec3(80, 1 ,0),
			hillyCoeficient = 20,
			constrained = true,
			variant = false,
			rotable = true,
		},		
	},
}

-- @description return stuctured description of the formation
-- @argument formationName [string] name of the formaiton
return function(formationName)
	local thisDefinition = formationDefinitions[formationName]
    -- if thisDefinition.generated then
    --     -- generate positions if needed
    --     local thisPositions = thisDefinition.positions(50) -- only for generated formations
    -- else
    --     local thisPositions = thisDefinition.positions
    -- end
    -- local thisPositions = (thisDefinition.generated) and (thisDefinition.positions(50)) or (thisDefinition.positions)  -- (a == b ? "yes" : "no")

    local thisPositions = thisDefinition.positions(50)

	local vectorPositions = {}
	local vectorPositionsCount = 0
	
	for i=1, #thisPositions do
		vectorPositionsCount = vectorPositionsCount + 1
		vectorPositions[vectorPositionsCount] = Vec3(thisPositions[i][1], 0, -thisPositions[i][2]) --  -- ORIGINAL
		-- vectorPositions[vectorPositionsCount] = Vec3(thisPositions[i][1], 0, thisPositions[i][2]) * thisDefinition.defaults.spacing --  -- MODIFIED: to have +Z forward, +X right
	end
	
	-- do not rewrite the originial table otherwise it is not robust on "reset"
	local finalDefinition = {
		name = thisDefinition.name,
		positions = vectorPositions,
		generated = thisDefinition.generated,
		defaults = thisDefinition.defaults,		
	}
	
	return finalDefinition
end