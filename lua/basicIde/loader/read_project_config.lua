---Prefix `filename` with the provided base path
---@param base_path string
---@param filename string
---@return string
local function prefix(base_path, filename)
	local path_sep = package.config:sub(1, 1)
	if base_path[#base_path] ~= path_sep then
		base_path = base_path .. path_sep
	end

	return base_path .. filename
end

---Load the project file from the current directory
---@return ProjectSettings
local function load_proj_file()
	package.path = table.concat({
		table.concat({vim.fn.stdpath('config'), 'lua', '?'}, '/'),
		table.concat({vim.fn.stdpath('config'), 'lua', '?.lua'}, '/'),
	}, ';')
	require('basicIde/globals')
	local project = require('basicIde.project')
	return project.load_settings()
end

---Return a string containing the environment table from loader config that
---can be parsed by a shell script
---@param environment table<string, string>
---@return string
local function parseable_environment(environment)
	local str = ""
	for variable, value in pairs(environment) do
		value, _ = string.gsub(value, "%${env:(%a+)}", function (capture) return os.getenv(capture) end)
		str = str .. variable .. '=' .. value .. '\n'
	end
	return str
end

---Return a string that can be passed to `eval` in the loader shell script
---@param script string
---@return string
local function evaluatable_script_string(script)
	script, _ = script:gsub("[	\r]", '') -- remove tabs and carriage return since they're not understood when the string is evaluated by bash
	return script
end

---Load the project file and prints the `virtual_environment` field, so the shell script can source it
local function main()
	local project_root_dir = arg[1]
	local command = arg[2]
	local proj_config = load_proj_file()

	if command == "virtual_environment" and proj_config.loader.virtual_environment ~= nil then
		print(prefix(project_root_dir, proj_config.loader.virtual_environment))
	elseif command == "environment" then
		print(parseable_environment(proj_config.loader.environment))
	elseif command == "init_script" then
		print(evaluatable_script_string(proj_config.loader.init_script))
	end
end

main()
