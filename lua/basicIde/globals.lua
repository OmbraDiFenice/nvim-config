---Print the given input as nvim message, including tables
---@param table any # what to print. It also accepts tables, in which case prints the content recursively
---@return any # returns the same input it was passed
P = function(table)
	vim.api.nvim_echo({ { vim.inspect(table) } }, true, {})
	return table
end
