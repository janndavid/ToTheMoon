--          /* SERVER RELATED */

--Server related objects
local socket = require("socket")
local server = assert(socket.bind("127.0.0.1", 8888))
local host = "127.0.0.1:8888"
local hostname = "Janns http lua server"
local running = true
local debug = true

--			/* Cookies and sessions */
local sessions = {}

--			/* FILE & DATABASE */

-- file handling objects,fixed files and database related
local LOCALSTORAGE = "localstorage.txt"
local localbackupwrite = true
local fileops = require("fileops")
local sqlite3 = require("luasql.sqlite3")
local MKTABLEUSERS = [[
	CREATE TABLE 'users' (
	'id'	INTEGER NOT NULL UNIQUE,
	'username'	TEXT NOT NULL UNIQUE,
	'password' TEXT NOT NULL,
	'name'	TEXT NOT NULL,
	'age'	INTEGER NOT NULL,
	'email'	TEXT NOT NULL UNIQUE,
	'sex'	TEXT NOT NULL,
	PRIMARY KEY('id' AUTOINCREMENT)
);]]
local MKTABLESUBMISSIONS = [[
	CREATE TABLE submissions (
	'author' TEXT, 
	'submission' TEXT,
	)]]
local MKTABLEPOSTS = [[
	CREATE TABLE posts (
	'title'	 TEXT, 
	'author' TEXT, 
	'date' 	 DATETIME, 
	'usertext' TEXT
	)]]-- DATETIME format: YYYY-MM-DD HH:MI:SS
local INSERTUSER = [[INSERT INTO users VALUES('%s', '%d', '%s')]]
local INSERTSUBMISSION = [[INSERT INTO submissions VALUES('%s', '%s')]]
local FETCHVAR = [[to be done - fetch something by cursor]]


--			/* HTML CSS URLS */

-- HTML, CSS, urls and other pointers stored under these variables
local template = require("resty.template")
local HTTP_V = "HTTP/1.1"
local response_line_200 = HTTP_V .. " 200 OK"
local response_line_201 = HTTP_V .. " 201 Created"
local response_line_400 = HTTP_V .. " 400 Bad Request"
local response_line_404 = HTTP_V .. " 404 Not Found"
local response_line_501 = HTTP_V .. " 501 Not Implemented"
local header_srv_name = "Server: Custom LUA HTTP server"
local header_contype_HTML = "Content-Type: text/html"
local header_contype_CSS = "Content-Type: text/css"
local CRLF = "\r\n" -- CARRIAGE RETURN LINE FEED


--			/* HTML PAGES*/

-- html files, templates and urls
local content = fileops.flines("pages/home.html")
local homepage = table.concat(content, "\n")
local submitscontent = fileops.flines("pages/submits.html")
local submitspage = table.concat(submitscontent, "\n")
local logincontent = fileops.flines("pages/login.html")
local loginpage = table.concat(logincontent, "\n")
local registercontent = fileops.flines("pages/register.html")
local registerpage = table.concat(registercontent, "\n")
local CSS = table.concat(fileops.flines("pages/resources/styling.css"), "")
local homeURL = "localhost:8888"
local urls = {
	["/"] = homepage,
	["/submits"] = submitspage,
	["/login"] = loginpage,
	["/register"] = registerpage,
	["/resources/styling.css"] = "",
}
local HTTPmethods = {
	["GET"] = "",
	["POST"] = "",
}

--			/* CLI, UTILS AND ETC */

-- Custom CLI helper module instead of ugly strings in the main code
local cli = require("clihelper")
cli.startstr(hostname, host, {"/", "/submits"}, {"GET", "POST"}, {"q: (quit)", "h: (help)"})
local longline = cli.getlongline()
-- Lua utils for hashing, input validation and so on
local lutils = require("lutils")


--			/* DUMMY DATA */
--
POSTS_DD = {
    {"My title" ,"DaddyBoi", "01.01.2020", "Its ya Daddy, ya kno im sayin?"},
    {"Another day another title!", "MommaGurl", "02.01.2020", "Baby daddy cheatin again LMFAO"},
    {"I'm bad at titles", "Hellnaw", "04.07.2020", "Heeeeeeeeeeeel nawwwwwwwww"},
    {"faggoty fag", "SimonBendicksen", "01.09.2020", "C# er faktisk det mest populaere sprog, i foelge microsoft."},
}

--*******************************************************************************************
--*******************************************************************************************
--*******************************************************************************************

--			/* MAIN LOGIC BEGINS */

-- dbinit() is only to be run when starting server again with full wipe of stored data
-- will be moved to dbhandler module shortly
local function dbinit(debug) -- Debug is bool

	if not debug then
		return
	end

	-- clear localstorage.txt by open in write mode and then just close it
	io.open("localstorage.txt", "w"):close()
	local env = sqlite3.sqlite3()
	local conn = env:connect("mydb.sqlite")

	-- create user data table in mydb.sqlite
	local userstatus, err = conn:execute(MKTABLEUSERS)
	--local submissionstatus, err2 = conn:execute(MKTABLESUBMISSIONS)
	local poststatus, err3 = conn:execute(MKTABLEPOSTS)

	print(userstatus, err)
	--print(submissionstatus, err2)
	print(poststatus, err3)

	conn:close()
	env:close()
end

local function getusertable()
	local usertable = {""}

	local env = sqlite3.sqlite3()
	local conn = env:connect('mydb.sqlite')
	local cursor, err = conn:execute([[SELECT * FROM users]])
	local row = cursor:fetch ({}, "a")

	while row do
		print(string.format("Id: %s, Name: %s, Age: %s, Sex: %s", row.id, row.name, tostring(row.age), row.sex))
		row = cursor:fetch (row, "a")
	end

	return "yes"
end

local function generateresponse(status, servername, contype, conlen)
	local response = {}

	if not (status and servername and contype and conlen) then
		return nil
	end

	table.insert(response, status .. CRLF)
	table.insert(response, "Server-Name: " .. servername .. CRLF)
	table.insert(response, "Content-Type: " .. contype .. CRLF)
	table.insert(response, "Content-Length: " .. tostring(conlen) .. CRLF)
	table.insert(response, CRLF)

	return table.concat(response, "")
end

local function makeredirect(HTML, delay, redirectURL)
	local HTMLlines = fileops.flines(HTML)
	local newHTML = {}

	for _, line in pairs(HTMLlines) do
		if string.match(line, "<head>") then
			table.insert(newHTML, line)
			local str = string.format('<meta http-equiv="refresh" content="%d; URL="%s""/>', delay, redirectURL)
			table.insert(newHTML, str)
		end
		table.insert(newHTML, line)
	end
	for _, line in pairs(newHTML) do print(line) end
	return table.concat(newHTML, "\n")
end

local function handle_404(client, head, headers)
	print(head[2] .. " " .. "URL not found - ERROR 404")
    local notfound = [[
    	<!DOCTYPE html>
		<html lang="en">
		<head>
  			<meta charset="UTF-8">
  			<meta name="viewport" content="width=device-width, initial-scale=1.0">
  			<title>404 Not Found</title>
  			<link rel="stylesheet" type="text/css" href="resources/styling.css">
		</head>
		<body>
			<h1>404 Not Found</h1>
		</body>
		</html>
    ]]

    local response = generateresponse(response_line_404, header_srv_name, header_contype_HTML, #notfound)

    client:send(response)
    client:send(notfound)
end

local function handle_501(client, request)

	local notsupported = [[
    	<!DOCTYPE html>
		<html lang="en">
		<head>
  			<meta charset="UTF-8">
  			<meta name="viewport" content="width=device-width, initial-scale=1.0">
  			<title>501 Not supported</title>
  			<link rel="stylesheet" type="text/css" href="resources/styling.css">
		</head>
		<body>
			<h1>501 - Method has not yet been implemented!</h1>
		</body>
		</html>
    ]]

    local response = generateresponse(response_line_501, header_srv_name, header_contype_HTML, #notsupported)

    client:send(response)
    client:send(notsupported)
end


local md5 = require("md5")

local function hashstring(input)
	local md5_as_hex = md5.sumhexa(input)
	return md5_as_hex
end

-- we dont check the args, they have already gotten checked
-- by handle_HTTP, we do however have to check client input
-- by backend input validation, most of this code will be
-- moved to its own module shortly.
local function handle_POST(client, headers, body, head)

	if head[2] == "/login" then 

		local username = string.match(body, "userName=([^&]+)")
		local password = hashstring(string.match(body, "userPassword=([^&]+)"))

		-- check if username exists
		local env = sqlite3.sqlite3()
		local conn = env:connect("mydb.sqlite")

		local query = string.format([[
			SELECT password FROM users WHERE username = '%s'
		]], username)

		local cursor, err = conn:execute(query)
		local row = cursor:fetch({}, "a")

		if not row then 
			print("No such user..") 
			return 
		end

		if row.password ~= password then
			print("Wrong password...")
			-- send a wrong password response and no redirect
			return
		end

		-- *** generate a sessions ID here, store it in the cookie ***
		-- 

		-- sending a response and redirect html
		local redirectHTMLfile = "pages/succ_file.html"
		local redirectHTML = makeredirect(redirectHTMLfile, 2, "/") 
		local response_content = redirectHTML

		local response = generateresponse(response_line_200, header_srv_name, header_contype_HTML, #response_content)
		client:send(response)
		client:send(redirectHTML)

		cursor:close()
		conn:close()
		env:close()

	elseif head[2] == "/register" then 

		-- *** relocate to own function so it doesnt bloat main code *** --
		local username, name, age, sex, email, password
		local usernameMatch = string.match(body, "usernameName=([^&]+)")
		local usernamevalid = lutils.validusername(usernameMatch)
		local nameMatch = string.match(body, "userName=([^&]+)")
		local namevalid = lutils.validname(nameMatch)
		local ageMatch = string.match(body, "userAge=([^&]+)")
		local agevalid = lutils.validage(tonumber(ageMatch))
		local sexMatch = string.match(body, "selectedSex=([^&]+)")
		local sexvalid = lutils.validsex(sexMatch)
		local emailMatch = string.match(body, "userMail=([^&]+)")
		local emailvalid = lutils.validemail(emailMatch)
		local passwordMatch = string.match(body, "userPassword=([^&]+)")
		local passwordvalid = lutils.validpassword(passwordMatch)
		local errormsgs = {}

		if usernameMatch and usernamevalid then
			username = usernameMatch
		else
			table.insert(errormsgs, usernamevalid)
		end

		if nameMatch and namevalid then
			name = nameMatch
		else
			table.insert(errormsgs, namevalid)
		end

		if ageMatch and agevalid then
			age = tonumber(ageMatch)
		else
			table.insert(errormsgs, agevalid)
		end

		if sexMatch and sexvalid then
			sex = sexMatch
		else
			table.insert(errormsgs, sexvalid)
		end

		if emailMatch and emailMatch then
			email = emailMatch
		else
			table.insert(errormsgs, emailvalid)
		end

		if passwordMatch and passwordvalid then
			password = passwordMatch
		else 
			table.insert(errormsgs, passwordvalid)
		end

		if next(errormsgs) ~= nil then
			for k, v in pairs(errormsgs) do print("Key: " .. k .. " Value: " .. v) end
			local redirectHTMLfile = "pages/fail_file.html"
			local redirectHTML = makeredirect(redirectHTMLfile, 2, "/register") 
			local response_content = redirectHTML
			local response = generateresponse(response_line_400, header_srv_name, header_contype_HTML, #response_content)
			client:send(response)
			client:send(redirectHTML)
			return
		end

		password = hashstring(string.match(body, "userPassword=([^&]+)"))
		-- then we try to send it to db, we will receive a nil if user already exists
		local env = sqlite3.sqlite3()
		local conn = env:connect("mydb.sqlite")
		local registerstatus, err = conn:execute( string.format([[
			INSERT INTO users (username, password, name, age, email, sex) 
			VALUES('%s', '%s', '%s', '%d', '%s', '%s')]], username, password, name, age, email, sex)) -- id, username, password, name, age, email, sex

		if err then 
			local redirectHTMLfile = "pages/fail_file.html"
			local redirectHTML = makeredirect(redirectHTMLfile, 2, "localhost:8888/register") 
			local response_content = redirectHTML
			local response = generateresponse(response_line_400, header_srv_name, header_contype_HTML, #response_content)
			client:send(response)
			client:send(redirectHTML)
		else 
			local redirectHTMLfile = "pages/succ_file.html"
			local redirectHTML = makeredirect(redirectHTMLfile, 2, homeURL) 
			local response_content = redirectHTML
			local response = generateresponse(response_line_201, header_srv_name, header_contype_HTML, #response_content)

			client:send(response)
			client:send(redirectHTML)
		end

	else
		-- return 400 bad request
		return
	end
end

local function handle_GET(client, head, headers)
    local requrl = head[2]
    local clientpage = urls[requrl]
    
    if not urls[requrl] then
        -- Handle 404 response first
        handle_404(client, head, headers)

    -- add support for jpg, jpeg, png and such
	elseif requrl:match("%.jpg%") then
		--client:send(MOON)

    elseif requrl:match("%.css$") then
        -- Handle CSS request
        local response = generateresponse(response_line_200, header_srv_name, header_contype_CSS, #CSS)
        print(response)
        client:send(CSS)
        client:send(response)

    elseif requrl:match("submits") then
    	local mypage = template.process(submitspage, POSTS_DD)
    	local response = generateresponse(response_line_200, header_srv_name, header_contype_HTML, #mypage)
    	client:send(response)
    	client:send(mypage)
    else
        -- Handle other requests 
        local response = generateresponse(response_line_200, header_srv_name, header_contype_HTML, #clientpage)
        client:send(response)
        client:send(clientpage)
    end
end

-- edge cases has been put first - OK
local function handle_HTTP(client, headers, contentlength)

	-- lets check the first line by parsing it
	local head = {}
	for word in headers[1]:gmatch("%S+") do table.insert(head, word) end


	local method = head[1]
	print(head[1] .. " " .. head[2] .. " " .. head[3] .. "\n")

	if not (HTTPmethods[method] ~= nil) then
		handle_501(client, headers)
	
	elseif method == "GET" then
		handle_GET(client, head, headers)

	elseif method == "POST" then
		local body, err = client:receive(contentlength)
		if err then print(err) end
    	handle_POST(client, headers, body, head)
    end
end


--			/* MAIN LOOP */

dbinit(debug)

getusertable()

while running do

	local client = server:accept()
	local headers = {}
	local line, err = client:receive()

	print(line)

	-- keeping this temporarily while implementing remote access
	if line == "q" then 
		running = false 
		client:close() return 
		cli.shutdownstr()
	end

	while line and line ~= "" do
    	table.insert(headers, line)
    	line, err = client:receive()
		if err then print(err) end
	end

	local contentlength

	for _, header in ipairs(headers) do
    	local key, value = header:match("([^:]+):%s*(.*)")
    	if key and value and key:lower() == "content-length" then
        	contentlength = tonumber(value)
        	break
    	end
	end

	contentlength = contentlength or 0
	handle_HTTP(client, headers, contentlength)
	client:close()
end