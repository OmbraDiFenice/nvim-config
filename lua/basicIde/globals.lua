local utils = require('basicIde.utils')
local next = next  -- faster access, see https://stackoverflow.com/a/1252776/4046810

---Print the given input as nvim message, including tables
---@param table any # what to print. It also accepts tables, in which case prints the content recursively
---@return any # returns the same input it was passed
P = function(table)
	vim.api.nvim_echo({ { vim.inspect(table) } }, true, {})
	return table
end

---Checks if the given file path exists
---taken from https://stackoverflow.com/a/54775280/4046810
---@param name string # the path to the file to check
---@return boolean
File_exists = function(name)
	local f = io.open(name, "r")
	if f == nil then return false end
	local closed = io.close(f)
	return closed ~= nil and closed
end

---Checks if the given path exists (dir or file)
---@param path string
---@return boolean
Path_exists = function(path)
	local fail, err, _ = vim.uv.fs_stat(path)
	if fail == nil then vim.notify(err, vim.log.levels.WARN); return false end
	return true
end

---Returns the directory to be used to store data related to the current nvim session.
---@return string # the full path to the folder holding session data
Get_data_directory = function()
	local data_path = vim.fn.stdpath("data")
	local cwd_path = vim.fn.getcwd()
	---@cast data_path string
	---@cast cwd_path string
	return utils.ensure_no_trailing_slash(utils.ensure_trailing_slash(data_path) .. "sessions/" .. utils.ensure_no_leading_slash(cwd_path))
end

---@param table table
---@return boolean # true if the table doesn't contain anything, false otherwise
Is_table_empty = function(table)
	return next(table) == nil
end

---Recursively copy the given value. Applies to tables too.
---Taken from http://lua-users.org/wiki/CopyTable
---@generic T: any
---@param orig T # value to copy, can be a table
---@return T # deep copy of the input value
function Deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[Deepcopy(orig_key)] = Deepcopy(orig_value)
		end
		setmetatable(copy, Deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---Overwrites value of table t1 with corresponding values from t2.
---Mutate and return t1
---taken from https://stackoverflow.com/a/7470789
---@generic T: table
---@generic U: table
---@param t1 T # table to merge `t2` into. This will be mutated
---@param t2 U # table to merge into `t1`. This will not be mutated
---@return T | U # returns the mutated `t1`, containing values from the original `t1` overwritten/extended (recursively) with values from `t2`
function Deepmerge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			Deepmerge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end

---Checks if `needle` is contained in `haystack`
---@generic T
---@param needle T # the value to search for
---@param haystack T[] # the array in which to search
---@return boolean # true if `needle` is contained in `haystack` at least once
function Is_in_list(needle, haystack)
	for _, element in ipairs(haystack) do
		if needle == element then
			return true
		end
	end
	return false
end

---Builds an array where each element is the result of applying `fn` to each value from `t`
---@generic K: any
---@generic V: any
---@generic MappedV: any
---@alias T table<K, V>
---@param t T # input table on which to apply `fn`
---@param fn fun(value: V, key: K, t: T): MappedV # invoked for each element of `t` and should compute the mapped value to insert in the resulting array. Receives the `value`, the `key` and a reference to the whole input `t` table. WARNING: do not mutate `t` inside `fn`
---@return MappedV[] # a new array containing the mapped values
function Map(t, fn)
	local mapped = {}
	for key, value in pairs(t) do
		table.insert(mapped, fn(value, key, t))
	end
	return mapped
end

function Get_buf_var(buf, var_name, default_value)
  local s, v = pcall(function()
    return vim.api.nvim_buf_get_var(buf, var_name)
  end)
  if s then return v else return default_value end
end

---Split a string in an array over sep
---@param inputstr string
---@param sep string? -- defaults to %s if omitted
---@return string[]
function Split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

---Sets the default value obtained when accessing an undefined key in a table
---See https://www.lua.org/pil/13.4.3.html
---@param table table
---@param default_value any
function SetTableDefault(table, default_value)
	local mt = { __index = function() return default_value end }
	setmetatable(table, mt)
end

OS = {
	---directory path separator
	sep = package.config:sub(1, 1),
}
