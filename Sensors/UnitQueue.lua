local sensorInfo = {
	name = "UnitQueue",
	desc = "Create a queue of items to be processed one at a time; If multiple tables of units are provided, they are paired element-wise",
	author = "haveld",
	date = "2025-09-20",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedup
local isDead = Spring.GetUnitIsDead
local validID = Spring.ValidUnitID

local Queue = {}
local index = 1


-- @description return current wind statistics
return function(input)
    if input == "pop" then
        -- GETTER
        -- if not isDead(unitID) and validID(unitID) then -- skip dead units

        local items = {}
        for i=1 , #Queue do -- for list or element arrays that we want to merge next alive unit
            local unitList = Queue[i]
            
            local localIndex = index
            local toBeRemoved = {}
            local found = false
            while (localIndex <= #unitList) do
                local thisItem = unitList[localIndex]
                if isDead(thisItem) or not validID(thisItem) then -- skip dead units
                    toBeRemoved[#toBeRemoved + 1] = localIndex
                    localIndex = localIndex + 1
                else
                    items[#items + 1] = thisItem -- Add first next alive unit to list
                    if #toBeRemoved > 0 then
                        for j = #toBeRemoved, 1, -1 do
                            table.remove(unitList, toBeRemoved[j])
                        end
                    end
                    found = true
                    break -- only one item per list
                end
            end
            if not found then
                -- no more alive units - Cannot create the combination
                return {nil, nil}
            end
        end
        index = index + 1
        return items

    else 
        -- SETTER 
        if input ~= nil and type(input) == "table" and #input > 0 then
            if type(input[1]) ~= "table" then
                Queue = {}
                Queue[1] = input
            else
                Queue = input
            end
            index = 1
            return true
        else
            Logger.warn("UnitQueue", "Invalid input for UnitQueue sensor - expected non-empty table (or table with tables) or 'pop' command")
            return false
        end
    end
end
