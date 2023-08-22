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
