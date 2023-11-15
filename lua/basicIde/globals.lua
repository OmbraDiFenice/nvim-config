local utils = require('basicIde.utils')

P = function(table)
	vim.api.nvim_echo({ { vim.inspect(table) } }, true, {})
	return table
end

function Printlines(lines)
	vim.notify(table.concat(lines, '\n'))
end

-- https://stackoverflow.com/a/54775280/4046810
File_exists = function(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

Get_data_directory = function()
	return utils.ensure_trailing_slash(vim.fn.stdpath("data")) .. "sessions/" .. utils.ensure_trailing_slash(utils.ensure_no_leading_slash(vim.fn.getcwd()))
end

-- taken from http://lua-users.org/wiki/CopyTable
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

-- taken from https://stackoverflow.com/a/7470789
-- Overwrites value of table t1 with corresponding values from t2.
-- Mutate and return t1
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

function LogWarning(message)
	vim.cmd('echohl WarningMsg')
	vim.cmd('echomsg "Warning: ' .. message .. '"')
	vim.cmd('echohl None')
end

function Is_in_list(needle, haystack)
	for _, element in ipairs(haystack) do
		if needle == element then
			return true
		end
	end
end

function Map(t, fn)
	local mapped = {}
	for key, value in pairs(t) do
		table.insert(mapped, fn(value, key, t))
	end
	return mapped
end

