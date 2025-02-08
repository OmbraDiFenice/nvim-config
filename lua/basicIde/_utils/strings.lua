local M = {}

---Ensures that the path string passed in has a trailing forward slash /
---@param path string
---@return string
M.ensure_trailing_slash = function(path)
	if string.sub(path, #path, #path) == '/' then return path end
	return path .. '/'
end

---Ensures that the path string passed in has no leading forward slash /
---@param path string
---@return string
M.ensure_no_leading_slash = function(path)
	while string.sub(path, 1, 1) == '/' do path = string.sub(path, 2) end
	return path
end

---Ensures that the path string passed in has no trailing forward slash /
---@param path string
---@return string
M.ensure_no_trailing_slash = function(path)
	while string.sub(path, #path, #path) == '/' do path = string.sub(path, 1, #path-1) end
	return path
end

---Removes any line of length 0 from the list of lines
---@param lines string[]
---@return string[] a new list of lines without the empty ones
M.remove_trailing_empty_lines = function(lines)
	local cleaned_lines = {}

	for i = #lines, 1, -1 do
		if #(lines[i]) ~= 0 then
			table.insert(cleaned_lines, 1, lines[i])
		end
	end

	return cleaned_lines
end

---Split a string in an array over sep
---@param inputstr string
---@param sep string? -- defaults to %s if omitted
---@return string[]
function M.split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function M.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return M
