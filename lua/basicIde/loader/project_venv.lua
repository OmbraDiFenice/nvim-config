---Prefix `filename` with the base path provided as command line parameter
---@param filename string
---@return string
local function prefix(filename)
	local base_path = arg[1]
	local path_sep = package.config:sub(1, 1)
	if base_path[#base_path] ~= path_sep then
		base_path = base_path .. path_sep
	end

	return base_path .. filename
end

---Load the project file from the current directory
---@return ProjectSettings? # return nil if there was an error loading the file
local function load_proj_file()
	local proj_config_file = prefix('.nvim.proj.lua')
	local fh = io.open(proj_config_file)
	if fh == nil then return end

	local proj_config_str = fh:read('*a')
	return assert(loadstring(proj_config_str))()
end

---Load the project file and prints the `virtual_environment` field, so the shell script can source it
local function main()
	local proj_config = load_proj_file()
	if proj_config ~= nil and proj_config.virtual_environment ~= nil then
		print(prefix(proj_config.virtual_environment))
	end
end

main()
