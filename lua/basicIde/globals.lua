P = function(table)
	vim.api.nvim_echo({{vim.inspect(table)}}, true, {})
	return table
end

-- https://stackoverflow.com/a/54775280/4046810
File_exists = function(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end

Get_data_directory = function ()
	return vim.fn.stdpath("data").."/sessions/"..vim.fn.getcwd().."/"
end
