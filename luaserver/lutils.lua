-- Lua Utils (lutils)
-- Lua Utils contains frequently used functions through out
-- the To The Moon! framework.
-- Author: Jann Jacobsen
-- 29.01.2023
-------------------------------------------------------------------------

local lutils = {}
local md5 = require("md5")

local hashmethods = {
	["CHF"] = "Custom Hashing Function. It is my own in development cryptographic hash function.",
	["MD5"] = "Based on the MD5 Lua Module. It is a secure cryptographic hash function.",
}

local hashkeys = {

}

function lutils.hashpasswordCHF(input)
	return
end

function lutils.hashpasswordMD5(password)
	local md5_as_hex = md5.sumhexa(password)
	return md5_as_hex
end

-- We want to generate a hashkey for when putting a user
-- into the database, this makes accessing easier as index
-- is calculated based on the username, in this module
-- there are several ways of accomplishing this, for now
-- We will use linear proping and quadratic proping for indexing
function lutils.genhashkey(hashtable, hashtablelen, hashkey, optinc)
	local key = 0
	local index = 0

	-- increment for collisions
	if optinc then 
		index = index + optinc
	end

	-- we sum the ascii codes of each character in the key
	for i = 1, #hashkey do
		key = key + string.byte(hashkey, i)
	end

	index = key % hashtablelen

	return key
end

-- It is meant to only return the error on the first error it encounters
-- regardless of how many, as user corrects errors the other errors messages
-- will eventually come to show anyways
function lutils.validusername(username, rules)

	-- if no rules table has been passed
	-- default to standard rules
	-- below is the standard rules so far


	-- check if there is something at all
	if not username then
		return "username must not be empty"
	end

	-- check if too short or too long (12 characters in this case is standard and lowest is 4)
	local len = string.len(username)
	if  len > 12 or len < 4 then
		return "username must be between 4 and 12 characters"
	end

	-- check if non-alpha-numerical characters are present
	if username:match("%c%d%p%x%z%s") then
		return "username can only contain letters and numbers"
	end

	return true
end

function lutils.validpassword(password)

	if not password then
		return "password empty"
	end

	local len = string.len(password)
	if len > 20 or len < 8 then
		return "password length must be between 8 and 20 characters"
	end

	if password:match("%s") then
		return "spaces in password not allowed"
	end

	return true
end

function lutils.validname(name)

	if not name then
		return "name empty"
	end

	local len = string.len(name)
	if len > 30 or len < 5 then
		return "name length must be between 5 and 30 characters"
	end

	return true
end

function lutils.validemail(email)

	if not email then
		return "email empty"
	end

	if not email:match("@") then
		return "email not valid"
	end

	return true
end

function lutils.validage(age)

	if not age then 
		return "age empty"
	end

	if not (age >= 0 and age < 130) then
		return "age not valid"
	end

	if type(age) ~= "number" then
		return "age must be an integer"
	end

	return true
end

function lutils.validsex(sex)

	if not sex then
		return "Must choose sex"
	end

	return true

end


return lutils



















