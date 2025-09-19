local sensorInfo = {
	name = "ReverseTable",
	desc = "Reverse the order of elements in a table.",
	author = "Zakk",
	date = "2022-06-28",
	license = "idk",
    source = "https://stackoverflow.com/questions/72783502/how-does-one-reverse-the-items-in-a-table-in-lua"
}

local EVAL_PERIOD_DEFAULT = -1 -- no caching 

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT
	}
end


--- Reverses the order of elements in a given table in-place.
---
--- @param tab table The table to be reversed.
--- @return table The reversed table.
return function(tab)
    for i = 1, math.floor(#tab/2), 1 do
        tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
    end
    return tab
end
