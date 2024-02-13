-- Lua HTML: For adding functionality to your HTML pages without touching
-- that steaming pile of fucking feces called jAvAsCrIpT
-- Author: Jann Jacobsen
-- 25.01.2023
-------------------------------------------------------------------------
local luatemplate = {}

local fileops = require("fileops")

local validtokens = {
	 ["for"] = "for",
    ["endfor"] = "endfor",
    ["if"] = "if",
    ["endif"] = "endif",
    ["in"] = "in",
    ["."] = ".",
    ["{%"] = "{%",
    ["%}"] = "%}",
    ["block"] = "block",
    ["endblock"] = "endblock",
}

local stdtags = {
	"{%%(.-)%%}",
	"{{(.-)}}",
	"{%%%w+%%}(.-){%%w+%%}"
}

local example = [[
<!DOCTYPE html>
<html lang="en">
	<head>	
  		<meta charset="UTF-8">
  		<meta name="viewport" content="width=device-width, initial-scale=1.0">
  		<title>Blog</title>
  		<link rel="stylesheet" type="text/css" href="resources/styling.css">
	</head>
	<body>

		{% for post in posts %}

    	<article>
        	<h2>{{ post.title }}</h2>
        	<a href="#">{{ post.author }}</a>
        	<p class="date">{{ post.date }}</p>
        	<p>{{ post.text }}</p>
    	</article>

    	{% endfor %}

    	{% for pic in pics %}

    	<article>
        	<h2>{{ pic.title }}</h2>
        	<a href="#">{{ pic.author }}</a>
        	<p class="date">{{ pic.date }}</p>
        	<p>{{ pic.text }}</p>
    	</article>

    	{% endfor %}

	</body>
</html>
]]


local function findtokens(HTMLpage)

	local tokens = {}

	for _,pattern in pairs(stdtags) do
		print(pattern)

		-- get all instances of templates by looking at {% ... %} where ... represents all possible tokens in this files token table.
		for block in HTMLpage:gmatch(pattern) do

			-- Split the block into individuel tokens
			if block ~= "" then
				for token in block:gmatch("%S+") do
					table.insert(tokens, token)
					print(token)
				end
			end
		end
	end
	return tokens
end

-- either take findtokens as input, but first i try to replace findtokens with this
-- therefore it will take a string (HTMLpage)
-- notice that we return a table of tables
local function findblocks(HTMLpage)

	local blocks = findtokens(HTMLpage)




	return blocks
end

print(table.concat(findtokens(example), " "))

-- basically a solution to the leetcode parenthesis problems
local function templateisvalid(HTMLpage)
	local tokens = findtokens(HTMLpage)
	local stack = {} 

	for _, val in ipairs(tokens) do

		if val == "for" or val == "if" then
            table.insert(stack, val)

		elseif val == "endfor" or val == "endif" then

            if #stack > 0 and stack[#stack] == "for" and val == "endfor" then
                table.remove(stack, #stack)

            elseif #stack > 0 and stack[#stack] == "if" and val == "endif" then
                table.remove(stack, #stack)
            else
                return false
            end
        end
    end
	return true
end

--"(%w+) in (%w+)"
function renderblock(HTMLpage, context)

	

end

-- Context is a table of pseudo OOP objects, they must
-- have a proper pseudo User object passed along in context
-- It is important that we keep SQL transactions in either httpserver
-- and or in fileops 
function luatemplate.render(HTMLpage, context)

	if not templateisvalid(HTMLpage) or context == nil then
		return nil
	end

	-- we get all the tags(tokens)
	local tags = findtokens(HTMLpage)

	if tags[1] == "for" then

		local forblock = tags[1]

	end


	return "html"

end



-- Temp pseudo User object
local User = {name = "", age = 0, sex = ""}
function User:new(o, name, age, sex)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.name = name or ""
	self.age = age or 0
	self.sex = sex or ""
	return o
end

-- Temp pseudo Context object
-- Context object which is used to send info to be rendered in html passed in args
local Context = {}
function Context:new(o, User, posts)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.User = User
	self.posts = posts
	return o 
end

--local user = User:new(o, "John", 50, "male")

local posts = {
	[1] = "Today was a good day.",
	[2] = "I was not very fond of today.",
	[3] = "Oh yeah!",
}

--local context = Context:new(o, user, posts)

--for _, v in ipairs(context.posts) do print(string.format("Author: %s Text: %s", context.User.name, v)) end

--print(luatemplate.render(example, context))

return luatemplate












































