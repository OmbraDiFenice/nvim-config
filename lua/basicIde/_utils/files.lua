local M = {}

---Checks if the given path exists (dir or file)
---@param path string
---@param verbose boolean? when false doesn't warn if the file doesn't exists. Defaults to true
---@return boolean
M.path_exists = function(path, verbose)
	if verbose == nil then verbose = true end
	local fail, err, _ = vim.uv.fs_stat(path)
	if fail == nil and verbose then vim.notify(err, vim.log.levels.WARN); end
	return fail ~= nil
end

---Checks if the given path is a file
---If the path doesn't exists it returns false
---@param path string
---@return boolean
M.is_file = function(path)
	local stat, _, _ = vim.uv.fs_stat(path)
	return stat ~= nil and stat.type == "file"
end

---Return the content of the specified file.
---If the file doesn't exist or is not a regular file returns nil.
---@param path string
---@return string?
M.load_file = function(path)
	if not M.path_exists(path) or not M.is_file(path) then return nil end
	local fd = io.open(path, "r")
	if fd == nil then return nil end
	local content = fd:read("*a")
	io.close(fd)
	return content
end

---Creates an empty file at the given path if it doesn't exist.
---Also creates any dir parents if they don't exist
---@param path string
M.touch_file = function(path)
	if M.path_exists(path, false) then return end

	vim.fn.mkdir(vim.fs.dirname(path), 'p')

	local fd = io.open(path, "w")
	if fd == nil then return end
	fd:close()
end

M.OS = {
	---directory path separator
	sep = package.config:sub(1, 1),
}

return M
