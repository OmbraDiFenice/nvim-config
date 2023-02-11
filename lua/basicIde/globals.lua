P = function(table)
	vim.api.nvim_echo({{vim.inspect(table)}}, true, {})
	return table
end
