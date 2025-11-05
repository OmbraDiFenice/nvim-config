local next = next  -- faster access, see https://stackoverflow.com/a/1252776/4046810

local M = {}

---@param table table
---@return boolean # true if the table doesn't contain anything, false otherwise
M.is_table_empty = function(table)
	return next(table) == nil
end

---Recursively copy the given value. Applies to tables too.
---Taken from http://lua-users.org/wiki/CopyTable
---@generic T: any
---@param orig T # value to copy, can be a table
---@return T # deep copy of the input value
function M.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[M.deepcopy(orig_key)] = M.deepcopy(orig_value)
		end
		setmetatable(copy, M.deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---Recursively traverse obj and returns a copy of it applying fn to each element.
---If a table is encountered, applies fn to both keys and values.
---@param orig any # object to traverse
---@param fn fun(obj: any): any # function that will be invoked on each element. Returns the eventually modified parameter. If no modification is needed, it should just return the parameter
---@return any obj # copy of obj with all keys and values changed by fn
function M.deepmap(orig, fn)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[M.deepmap(orig_key, fn)] = M.deepmap(orig_value, fn)
		end
		setmetatable(copy, M.deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = fn(orig)
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
function M.deepmerge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			M.deepmerge(t1[k], t2[k])
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
function M.is_in_list(needle, haystack)
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
function M.map(t, fn)
	local mapped = {}
	for key, value in pairs(t) do
		table.insert(mapped, fn(value, key, t))
	end
	return mapped
end

---Sets the default value obtained when accessing an undefined key in a table
---See https://www.lua.org/pil/13.4.3.html
---@param table table
---@param default_value any
function M.setTableDefault(table, default_value)
	local mt = { __index = function() return default_value end }
	setmetatable(table, mt)
end

---Concatenates two list-like tables, returning a new list-like table
---@t1 any[]
---@t2 any[]
---@return any[]
function M.concat(t1, t2)
	local t = {}
	for _, v in ipairs(t1) do
		table.insert(t, v)
	end
	for _, v in ipairs(t2) do
		table.insert(t, v)
	end
	return t
end

---Takes an array-like table and return a new array-like table
---containing the elements from the input for which the given function returns
---true.
---@generic T: any
---@param t T[] array-like table
---@param fn fun(T):boolean functions called with each input element, returning true if the element must be included in the output
---@return T[]
function M.filter(t, fn)
	local out = {}
	for _, elem in ipairs(t) do
		if fn(elem) then
			table.insert(out, elem)
		end
	end
	return out
end

return M
