-- only used as temp solution for better server receiving terminal info
-- just a bunch of fucking strings and such but meh

local clihelper = {}

local longline = "-----------------------------------------------------------------------"
local longslash = "///////////////////////////////////////////////////////////////////////"
local defaultshutdownstr = "\nServer shutting down.........."
local supportedcommands = {
	["q:"] = "(quit)",
	["h:"] = "(help)",
	["adm:"] = "(admin)"
}
local descriptions = {
	["q"] = "",
	["h"] = "type q or quit to close the server. Typing adm and a supported admin function will execute admin command.",
	["adm:"] = "Admin commands are as follows: to be implemented"
}

function clihelper.startstr(srvname, srvhost, urls, methods, actions)
	print(longline .. "\n" .. longslash .. "\n" .. longline)
	local str = string.format("Server: %s\nLocation: %s", srvname, srvhost)
	print(str)

	print("Available urls:")
	for _, line in pairs(urls) do print("\t" .. line) end

	print("Supported HTTP methods are:")
	for _, line in pairs(methods) do print("\t" .. line) end

	print("Actions supported through telnet are:")
	for _, line in pairs(actions) do print("\t" .. line) end

	print(longline .. "\n" .. longslash .. "\n" .. longline)
end

function clihelper.shutdownstr(message)
	if message == nil then print(defaultshutdownstr) return
	else print(message) end
end

function clihelper.printlongline()
	print(longline)
end

function clihelper.getlongline()
	return longline
end

function clihelper.printlongslash()
	print(longslash)
end

function clihelper.checkaction(actiontable, action)
	for _, v in pairs(actiontable) do
		if v == action then return true end
	end
	return false
end

-- key is the command, value is the description
function clihelper.helpstr(client, helptable)

	if not client and not helptable then
		print("invalid arguments")
		return nil
	end 

	for k, v in pairs(helptable) do 
		local helpstr = string.format("%s: %s", k, v)
		print(helpstr)
		client:send(helpstr)
	end

end

function clihelper.processremote(socket, server, client, line)
	local srvstring = {}
	local clientstring = {}

	if not client and line then 
		print("clihelper.processremote invalid args")
		return nil
	end

	client:send("Welcome to the remote CLI")

	-- I want to send a response to the server which
	-- makes it easier for me to monitor whats going on
	-- hence the srvstring, it also has to look and feel
	-- different than http requests and responses
	table.insert(srvstring, tostring(client:getpeername()))
	table.insert(srvstring, "has connected to the server.")
	print(table.concat(srvstring, " "))

	-- On the other hand I also want to send the client
	-- something that does not feel like http, but more like
	-- a django admin feel
	if supportedcommands[line] then
		-- call the appropriate function to handle line
		if line == "q" then
			print("Server shutting down...")
			client:close()
			server:close()
			socket:close()
		end

		if line == "h" or line == "help" then
			client:send(descriptions["h"])
		end

		if line == "adm" or line == "admin" then
			client:send(descriptions["adm"])
		end

	end

	client:close()

end



return clihelper






























