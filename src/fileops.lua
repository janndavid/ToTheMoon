-- handles common file actions and parsings
-- used heavily by httpserver.lua
-- notice that dictoJSON doesnt work properly
local fileops = {}

function fileops.fexists(file)
    return io.open(file, "r") ~= nil
end

function fileops.flines(file)
	local lines = {}
	if fileops.fexists(file) then
		local f = io.open(file, "r")
		for line in f:lines() do 
			table.insert(lines, line)
		end
		io.close(f)
	end
	return lines
end

function fileops.sendtofile(file, JSON_entry)

	if fileops.fexists(file) then
		local lines = fileops.flines(file)

		for _, line in pairs(lines) do
			if string.match( line, tostring(JSON_entry)) then
				return nil
			end
		end

		local f = io.open(file, "a")
		io.output(f)
		io.write(tostring(JSON_entry) .. "\n")
		io.close(f)
	end
end

function fileops.dictoJSON(table, keyorder)
	
	local metatable = {
		__tostring = function(table)
			local JSON = {}
			for _, k in ipairs(keyorder) do
				local v = table[k]
				local entry = string.format('"%s":"%s"', k, v)
				table.insert(JSON, entry)
			end
		return "{" .. table.concat(JSON, ", ") .. "}"
	end
	}
	local JSON_entry = setmetatable(table, metatable)
	return JSON_entry
end

return fileops