local sensorInfo = {
	name = "Concatenate",
	desc = "Concatenate two lists of units.",
	author = "PepeAmpere",
	date = "2017-05-30",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- no caching 

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT
	}
end

-- @description concatenate two lists of units
-- @argument listA
-- @argument listB
-- @return list of units
return function(listA, listB)
	local newListOfUnits = listA
	
	for i=1, #listB do
        newListOfUnits[#newListOfUnits + 1] = listB[i]
    end
	return newListOfUnits
end