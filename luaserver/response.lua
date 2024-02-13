local response = {}

local HTTP_V = "HTTP/1.1"
response.code200 = HTTP_V .. " 200 OK"
response.code201 = HTTP_V .. " 201 Created"
response.code400 = HTTP_V .. " 400 Bad Request"
response.code404 = HTTP_V .. " 404 Not Found"
response.response_line_501 = HTTP_V .. " 501 Not Implemented"
response.header_srv_name = "Server: Custom LUA HTTP server"
response.header_contype_HTML = "Content-Type: text/html"
response.header_contype_CSS = "Content-Type: text/css"
response.CRLF = "\r\n" -- CARRIAGE RETURN LINE FEED

function response.generateresponse(status, servername, contype, conlen)
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

function response.response_404(head)
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

    local response = response.generateresponse(response_line_404, header_srv_name, header_contype_HTML, #notfound)

end


return response