SLCustom = {}

SLCustom.InitTable = function(input)
	local getItems = {}
	local outputTable = {}
	
	for i,j in ipairs(input) do
		if j.name ~= "_getItems" then
			getItems[i]=j.name
			outputTable[j.name]=j.custom
		end
	end
	
	outputTable._getItems = getItems
	
	return outputTable
end