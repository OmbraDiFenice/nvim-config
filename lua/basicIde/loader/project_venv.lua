local function prefix(filename)
	local base_path = arg[1]
	local path_sep = package.config:sub(1, 1)
	if base_path[#base_path] ~= path_sep then
		base_path = base_path .. path_sep
	end

	return base_path .. filename
end

local function load_proj_file()
	local proj_config_file = prefix('.nvim.proj.lua')
	local fh = io.open(proj_config_file)
	if fh == nil then return end

	local proj_config_str = fh:read('*a')
	return assert(loadstring(proj_config_str))()
end

local function main()
	local proj_config = load_proj_file()
	if proj_config ~= nil and proj_config.virtual_environment ~= nil then
		print(prefix(proj_config.virtual_environment))
	end
end

main()
