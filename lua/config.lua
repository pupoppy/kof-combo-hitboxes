local colors = require("render.colors")
local ReadConfig = {}

ReadConfig.yesValues = {"yes", "y", "true", "t", "on"}
ReadConfig.noValues = {"no", "n", "false", "f", "off"}

local INTEGER_PARSE_ERR = "Could not interpret '%s' as an integer value."
local BOOLEAN_PARSE_ERR = "Could not interpret '%s' as a yes/no value."
local COLOR_PARSE_ERR = "Could not interpret '%s' as a color value."
local BYTE_RANGE_ERR = "Value %d must be between 0 and 255 (inclusive)."
local INVALID_LINE_ERR = 
	"Line %d is not an option line or a section header, and will be skipped."
local ERRLINE = "Error on line %d: %s"

-- used by ReadConfig.parseColor()
local cp = "%s*%d+%s*"
local rgbPattern = string.format("%%(%s,%s,%s%%)", cp, cp, cp)
local rgbaPattern = string.format("%%(%s,%s,%s,%s%%)", cp, cp, cp, cp)

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function stripComment(s)
	local index = (s:find(";", 1, true))
	return (index and s:sub(1, index - 1)) or s
end

local function selectSection(target, section)
	section = section:lower()
	for segment in section:gmatch("([%w_]+)(%.?)") do
		target[segment] = (target[segment] or {})
		target = target[segment]
	end
	return target
end

local function isSectionMarker(line)
	local l, r = line:find("%[[%w%._]+%]")
	return (l and r and line:sub(l + 1, r - 1)) or nil
end

local function isOptionLine(line)
	local l, r = line:find("[%w_]+%s*=.+")
	if l and r then
		local eq = line:find("=", l, true)
		return trim(line:sub(1, eq - 1)), trim(line:sub(eq + 1))
	else
		return nil
	end
end

local function contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then return true end
	end
	return false
end

local function asInt(s)
	return (type(s) == "number" or s:find("^[+-]?%d+$")) and (s + 0)
end

function ReadConfig.parseInteger(s)
	local result = asInt(s)
	if result then return result
	else return nil, string.format(INTEGER_PARSE_ERR, s) end
end

function ReadConfig.parseBoolean(s)
	s = s:lower()
	if contains(ReadConfig.yesValues, s) then return true
	elseif contains(ReadConfig.noValues, s) then return false
	else return nil, string.format(BOOLEAN_PARSE_ERR, s) end
end

function ReadConfig.parseDecimalByte(s)
	local result = asInt(s)
	if result ~= nil and result >= 0 and result <= 255 then return result
	else return nil, string.format(BYTE_RANGE_ERR, result) end
end

function ReadConfig.parseColor(s)
	local hasAlpha
	if s:find(rgbPattern) then hasAlpha = false
	elseif s:find(rgbaPattern) then hasAlpha = true
	else return nil, string.format(COLOR_PARSE_ERR, s) end

	local f = s:gmatch("%d+")
	local r, g, b = f(), f(), f() -- each invocation returns next channel
	local a = (hasAlpha and f()) or 255
	local packed = { r, g, b, a }
	for i, rawValue in ipairs(packed) do
		local value, err = ReadConfig.parseDecimalByte(rawValue)
		if not err then packed[i] = value
		else return nil, err end -- bail out early on parse error
	end

	return colors.rgba(unpack(packed)), hasAlpha
end

-- schema dictates what config file structure to expect,
-- and the appropriate handler for each item in that structure
function ReadConfig.readFile(file, schema)
	if type(file) == "string" then
		file = assert(io.open(file, "r"))
	end
	local result = { global = {} }
	local currentSection = "global" -- implicit "default" config section
	local target, handler = result[currentSection], schema[currentSection]
	local i = 1 -- current line number

	for line in file:lines() do
		line = trim(stripComment(line))
		local sectionMarker -- must be on its own line for the "goto" below
		if line:len() == 0 then goto continue end
		-- is the current line a section header?
		sectionMarker = isSectionMarker(line)
		if sectionMarker then
			currentSection = sectionMarker
			target = selectSection(result, currentSection)
			handler = selectSection(schema, currentSection)
		else
			local key, value = isOptionLine(line)
			if not key then
				print(string.format(INVALID_LINE_ERR, i))
			elseif handler[key] then
				local result, err = handler[key](value, key)
				if result ~= nil then
					target[key] = result
				else
					err = string.format(ERRLINE, i, err)
					print(err)
				end
			end
		end
		::continue::
		i = i + 1
	end

	file:close()
	return result
end

return ReadConfig
