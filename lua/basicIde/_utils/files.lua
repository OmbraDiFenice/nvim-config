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

M.load_file = function(path)
	if not M.path_exists(path) then return nil end
	local fd = io.open(path, "r")
	if fd == nil then return nil end
	return fd:read("*a")
end

M.OS = {
	---directory path separator
	sep = package.config:sub(1, 1),
}

return M