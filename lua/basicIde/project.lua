local utils = require('basicIde.utils')
local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

---Execute the callbacks in `custom_startup_scripts` setting
---@param settings ProjectSettings
---@param utils Utils
---@return nil
local function run_custom_startup_scripts(settings, utils)
	for script_name, callback in pairs(settings.custom_startup_scripts) do
		callback(utils)
	end
end

---Initialize keymaps from `custom_keymaps` setting
---@param settings ProjectSettings
---@param utils Utils
---@return nil
local function init_custom_keymaps(settings, utils)
	for mode_shortcut, keymap_def in pairs(settings.custom_keymaps) do
		local mode, shortcut, callback, desc = utils.parse_custom_keymap_config(mode_shortcut, keymap_def)
		vim.keymap.set(mode, shortcut, function() callback(utils, settings) end, { desc = desc })
	end
end

---@type ProjectSettings
local default_settings = {
	---@diagnostic disable: missing-fields
	PROJECT_SETTINGS_FILE = '',
	DATA_DIRECTORY = '',
	IDE_DIRECTORY = '',
	PROJECT_ROOT_DIRECTORY = '',
	project_title = '[nvim IDE] ' .. vim.fn.getcwd(-1, -1),
	project_languages = {},
	performance = {
		disable_treesitter_highlight = function(_, bufnr) return vim.api.nvim_buf_line_count(bufnr) > 50000 end,
	},
	project_templates = {
		empty = {
			template_dir = "${ide:IDE_DIRECTORY}/project_templates/empty",
		},
		python = {
			template_dir = "${ide:IDE_DIRECTORY}/project_templates/python",
			post_dir_init = function(utils, end_cb)
				if utils.files.is_dir('venv') then end_cb() return end
				utils.python.create_venv(end_cb)
			end,
		},
		platformio = {
			template_dir = "${ide:IDE_DIRECTORY}/project_templates/platformio",
			post_dir_init = function(utils, end_cb)
				if not utils.files.is_file(vim.uv.os_homedir() .. '/.platformio/penv/bin/pio') and not utils.files.is_bin_available('pio') then
					vim.notify('pio script not found. Please install it then reload nvim.\nSee https://docs.platformio.org/en/latest/core/installation/methods/index.html')
				end
				vim.notify('new venv added to config, restart neovim to use it properly')
				end_cb()
			end
		},
		ufbt = {
			template_dir = "${ide:IDE_DIRECTORY}/project_templates/ufbt",
			post_dir_init = function(utils, end_cb)
				vim.ui.input({ prompt = "APPID: " }, function(appid)
					utils.python.create_venv(function(_, _)
						local notif = vim.notify("creating installing ufbt...", vim.log.levels.INFO, { keep = utils.true_fn })
						utils.proc.runAndReturnOutput("bash -c 'source venv/bin/activate && pip install --upgrade ufbt'", function(output_lines, exit_code)
							if exit_code ~= 0 then
								vim.notify(table.concat(output_lines, utils.files.OS.newline), vim.log.levels.ERROR)
								return
							end

							notif = vim.notify("initializing ufbt app...", vim.log.levels.INFO, { keep = utils.false_fn, replace = notif })
							utils.proc.runAndReturnOutput("bash -c 'source venv/bin/activate && ufbt create APPID=".. appid .. "'", function(output_lines, exit_code)
								if exit_code ~= 0 then
									vim.notify(table.concat(output_lines, utils.files.OS.newline), vim.log.levels.ERROR)
									return
								end

								notif = vim.notify("configuring .clangd...", vim.log.levels.INFO, { keep = utils.false_fn, replace = notif })
								utils.proc.runAndReturnOutput("sed -i -e 's#$HOME#" .. vim.uv.os_homedir() .. "#g' .clangd", function(output_lines, exit_code)
									if exit_code ~= 0 then
										vim.notify(table.concat(output_lines, utils.files.OS.newline), vim.log_levels.ERROR)
										return
									end
									end_cb()
								end)
							end)
						end)
					end)
				end)
			end,
		},
	},
	build_remote_url = function() return nil end,
	loader = {
		virtual_environment = nil,
		environment = {},
		init_script = '',
	},
	format_on_save = { -- WARNING: if enabled together with autosave it will pollute the undo history and you won't be able to undo changes anymore
		enabled = false, -- 1. you make a change -> autosave triggers -> changes go to undo history
                     -- 2. buffer is autoformatted -> buffer is changed -> autosave triggers again -> autoformatting changes go to undo history
                     -- 3. you want to undo changes made at point 1, but:
                     --    - hitting 'u' actually undoes the reformatting from point 2
                     --    - that triggers autoformat again
                     --    - you're back to the change you wanted to undo
		keymaps = {
			format_current_buffer = {'<F7>', 'v <F7>'},
		}
	},
	debugging = {
		dap_configurations = {},
		external_scripts = {},
	},
	lsp = {
		notifications = {
			enabled = true,
		},
		extra_server_cli = {},
		server_settings = {},
	},
	terminal = {
		init_environment_cmd = '[[ -d ${VIRTUAL_ENV+x} ]] || source "$VIRTUAL_ENV/bin/activate" ; clear'
	},
	remote_sync = {
		enabled = false,
		strategy = 'rsync',
		rsync_settings = {
			remote_user = nil, -- required
			remote_host = nil, -- required
			remote_port = 22,
		},
		sync_on_save = true,
		sync_on_git_head_change = true,
		mappings = { -- required
			-- { local_prefix_dir, remote_prefix_dir },
			-- ...
		},
		exclude_paths = {},
		exclude_git_ignored_files = true,
		notifications = {
			enabled = true,
		},
	},
	custom_startup_scripts = {},
	custom_packer_plugins = {},
	custom_keymaps = {},
	code_layout = {
		strategy = "smart",
		indent_width = 2,
		languages = {
			c = {
				node_types = {'function_definition', 'struct_specifier'},
				queries = {
					{
						format = "${type} ${var};",
						-- lang: query
						query = [[
						 (
						  (
							 declaration
							 type: (_)? @type
							 declarator: [
							  (init_declarator declarator: (_) @var)
								(identifier) @var
								(function_declarator) @var
							 ]
							) @root
              (#not-has-ancestor? @root function_definition)
						 )
						]],
					},
					{
						format = "${type} ${var};",
						-- lang: query
						query = [[
						 (
						  (
							 field_declaration
							 type: (_) @type
							 declarator: (_) @var
							) @root
              (#not-has-ancestor? @root function_definition)
						 )
						]],
					},
					{
						format = "${return_type} ${declarator};",
						-- lang: query
						query = [[
						 (
						  function_definition
							type: (_) @return_type
							declarator: (_) @declarator
						 ) @root
						]],
					},
					{
						format = "${type} ${name};",
						-- lang: query
						query = [[
						(
						 (
						  [
						 	 (struct_specifier "struct" @type name: (type_identifier) @name)
						 	 (enum_specifier "enum" @type name: (type_identifier) @name)
						  ]
						 ) @root
             (#not-has-parent? @root type_definition)
						)
						]]
					},
					{
						format = "typedef ${type} ${name};",
						-- lang: query
						query = [[
						 [
						  (
						   type_definition
						   type: (
						    [
						     (struct_specifier "struct" @type)
						     (enum_specifier "enum" @type)
						     (primitive_type) @type
						    ]
						   )
						   declarator: (_) @name
						  ) @root
						 ]
						]]
					},
					{
						format = "#define ${name}",
						-- lang: query
						query = [[
						 (preproc_def name: (_) @name) @root
						]],
					},
					{
						format = "#define ${name}${params}",
						-- lang: query
						query = [[
						 (
						  preproc_function_def
							name: (_) @name
							parameters: (_) @params
						 ) @root
						]],
					},
				},
			},
			cpp = {
				node_types = {'function_definition', 'struct_specifier', 'declaration', 'class_specifier', 'namespace_definition'},
				queries = {
					{
						format = "${type} ${var};",
						-- lang: query
						query = [[
						 (
						  (
							 declaration
							 type: (_)? @type
							 declarator: [
							  (init_declarator declarator: (_) @var)
								(identifier) @var
								(function_declarator) @var
							 ]
							) @root
							(#not-has-ancestor? @root function_definition)
							(#not-has-parent? @root template_declaration)
						 )
						]],
					},
					{
						format = "template${template_params} ${type} ${var};",
						-- lang: query
						query = [[
						 (
						  template_declaration
							parameters: (_) @template_params
						  (
							 declaration
							 type: (_) @type
							 declarator: [
							  (init_declarator declarator: (_) @var)
								(identifier) @var
								(function_declarator) @var
							 ]
							) @root
							(#not-has-ancestor? @root function_definition)
						 )
						]],
					},
					{
						format = "${return_type} ${declarator};",
						-- lang: query
						query = [[
						 (
						  (
						   function_definition
						   type: (_)? @return_type ; the type is not there for class constructors
						   declarator: (_) @declarator
						  ) @root
							(#not-has-parent? @root template_declaration)
						 )
						]],
					},
					{
						format = "template${template_params} ${return_type} ${declarator};",
						-- lang: query
						query = [[
						 (
						 	template_declaration
							parameters: (_) @template_params
						  (
							 function_definition
							 type: (_)? @return_type ; the type is not there for class constructors
							 declarator: (_) @declarator
							) @root
						 )
						]],
					},
					{ -- matches class member declarations
						format = "${return_type} ${declarator};",
						-- lang: query
						query = [[
						 (
						  field_declaration
							type: (_) @return_type
							declarator: (_) @declarator
						 ) @root
						]],
					},
					{
						format = "${type} ${name};",
						-- lang: query
						query = [[
						(
						 (
						  [
						 	 (struct_specifier "struct" @type name: (type_identifier) @name)
						 	 (enum_specifier "enum" @type name: (type_identifier) @name)
						  ]
						 ) @root
             (#not-has-parent? @root type_definition template_declaration)
						)
						]]
					},
					{
						format = "template${template_params} struct ${name};",
						-- lang: query
						query = [[
						 (
						  template_declaration
						  parameters: (_) @template_params
						  (
						   struct_specifier
						   name: (_) @name
						  ) @root
						 )
						]]
					},
					{
						format = "typedef ${type} ${name};",
						-- lang: query
						query = [[
						 (
						  type_definition
						  type: (
						   [
						    (struct_specifier "struct" @type)
						    (enum_specifier "enum" @type)
						    (primitive_type) @type
						   ]
						  )
						  declarator: (_) @name
						 ) @root
						]]
					},
					{
						format = "class ${name}${base_classes};",
						--lang: query
						query = [[
						 (
						  (
						   class_specifier
						   name: (_) @name
						   (base_class_clause)? @base_classes
						  ) @root
						  (#not-has-parent? @root template_declaration)
						 )
						]]
					},
					{
						format = "template${template_params} class ${name}${base_classes};",
						--lang: query
						query = [[
						 (
						  template_declaration
						  parameters: (_) @template_params
						  (
						   class_specifier
						   name: (_) @name
						   (base_class_clause)? @base_classes
						  ) @root
						 )
						]]
					},
					{
						format = "#define ${name}",
						-- lang: query
						query = [[
						 (preproc_def name: (_) @name) @root
						]],
					},
					{
						format = "#define ${name}${params}",
						-- lang: query
						query = [[
						 (
						  preproc_function_def
							name: (_) @name
							parameters: (_) @params
						 ) @root
						]],
					},
					{
						format = "namespace ${name};",
						-- lang: query
						query = [[
						 (
							namespace_definition
							name: (_) @name
						 ) @root
						]],
					},
				},
			},
			python = {
				node_types = {'class_definition', 'function_definition'},
				stop_at_tokens = { { type = 'token', value = ':' }, },
				ignore_tokens = { { type = 'node_type', value = 'comment' }, },
				queries = {
					{
						format = "${name}${op} ${type}",
						-- lang: query
						query = [[
             (
              (expression_statement
               (assignment
                left: (identifier) @name
								":"? @op
                type: (_)? @type
               )
              ) @root
              (#has-parent? @root module)
             )
						]]
					},
					{
						format = "def ${fn_name}${fn_params} ${op} ${fn_return_type}:",
						-- lang: query
						query = [[
						 (
							function_definition
							 name: (_) @fn_name
							 parameters: (_) @fn_params
							 "->"? @op
							 return_type: (_)? @fn_return_type
						 ) @root
						]]
					},
					{
						format = "class ${class_name}${class_superclasses}:",
						-- lang: query
						query = [[
							(
							 class_definition
							  name: (_) @class_name
							  superclasses: (_)? @class_superclasses
							) @root
						]],
					},
				},
			},
			lua = {
				node_types = {'table_constructor', 'function_declaration', 'function_definition'},
				stop_at_tokens = {},
				ignore_tokens = {},
				queries = {
					{
						format = "${fn_name}${fn_params}",
						-- lang: query
						query = [[
						 (
						  (function_declaration
						 	 name: [
						 		(identifier)
						 		(method_index_expression)
						 		(dot_index_expression)
						 	 ] @fn_name
						 	 parameters: (_) @fn_params
						  ) @root
						 )
						]]
					},
					{
						format = "${fn_name}${fn_params}",
						-- lang: query
						query = [[
						 (
						  (assignment_statement
						   (variable_list 
								 name: [
						      (identifier)
						      (dot_index_expression)
						     ] @fn_name
						    )
						    (expression_list value: (function_definition parameters: (_) @fn_params))
						  ) @root
						  )
						]]
					},
					{
						format = "${name}${params}",
						-- lang: query
						query = [[
						 (
						  (table_constructor
						   (field 
								 name: (identifier) @name
						     value: (function_definition parameters: (_) @params)
							 ) @root
						  )
						 )
						]]
					},
					{
						format = "${name}",
						-- lang: query
						query = [[
						 (
						  (table_constructor
						   (field 
								 name: (identifier) @name
						     value: (_) @val
							 ) @root
						  )
							(#not-kind-eq? @val function_definition)
						 )
						]]
					},
					{
						format = "${name}",
						-- lang: query
						query = [[
							(
							 (
								assignment_statement
								 (variable_list name: [
									(identifier)
									(dot_index_expression)
								 ] @name)
								 (expression_list value: (_) @val)
							 ) @root
							 (#not-has-ancestor? @root function_definition)
							 (#not-has-ancestor? @root function_declaration)
							 (#not-kind-eq? @val function_definition)
							)
						]]
					},
				},
			},
			markdown = {
				node_types = {'atx_heading'},
				stop_at_tokens = {},
				ignore_tokens = {},
				queries = {
					{
						format = "${name}",
						-- lang: query
						query = [[
							(
								section
								(
									atx_heading
								) @name
							) @root
						]]
					},
				},
			},
		},
		keymaps = {
			open_layout = {'<leader>l'}, -- from the file to analyze
			close_layout = {'q'}, -- from within layout buffer
			goto_and_close_layout = {'<CR>'}, -- from within layout buffer
			scroll_to = {'<C-h>', '<C-l>'}, -- from within layout buffer
		},
	},
	editor = {
		autosave = true,
		status_bar = {
			code_breadcrumb = {
				enabled = true,
				provider = "trouble",
			},
		},
		append_git_branch_to_title = false,
		recenter_viewport = {
			enabled = true,
			ignore_filetypes = {},
		},
		tree_view = {
			open_on_start = true,
			keymaps = {
				open = { 'l' },
				close_tree_view = { '<C-h>' },
				vsplit_preview = { 'L' },
				close_dir = { 'h' },
				collapse = { 'H' },
				git_add = { 'ga' },
				synchronize_file_or_dir_remotely = { '<leader>S' },
				search_in_marked_locations = { '<leader>sf' },
				grep_in_marked_locations = { '<leader>sg' },
				new_scope_from_marks = { '<leader>sc' },
			},
		},
		activity_monitor = {
			enabled = true,
			keymaps = {
				show_log = { '<leader>a' },
			},
		},
		notifications = {
			strategy = "nvim-float",
			system_configs = {
				icons = {},
				transient = true,
			},
		},
		keymaps = {
			show_line_diagnostic = { '<leader>d?' },
			show_buffer_diagnostic = { '<C-l>' },
			search_lsp_symbol = { '<leader>ss' },
			clear_lsp_symbol_highlight = { '<leader>sS' },
			show_opened_buffers = { '<leader>b' },
			close_buffer = { '<leader>q' },
			quit_nvim = { '<leader>Q' },
			open_undo_tree = { '<leader>u' },
			jump_to_previous_location = { '<X1Mouse>', '<C-y>' },
			jump_to_next_location = { '<X2Mouse>', '<C-p>' },
		},
	},
	ai = {
		enabled = false,
		engine = 'codeium',
		disable_for_all_filetypes = false,
		filetypes = {},
		manual = false,
		render_suggestion = true,
		show_in_status_bar = true,
		keymaps = {
			accept_current_suggestion = {'i <C-g>'},
			clear_current_suggestion = {'i <C-x>'},
			next_suggestion = {'i <C-l>'},
			previous_suggestion = {'i <C-h>'},
		},
	},
	ai_chat = {
		enabled = false,
		provider = 'openai',
		api_key = '${env:OPENAI_API_KEY}',
		keymaps = {
			new_chat = { 'gP' },
			toggle = { 'gp' },
			search = { 'sgp' },
			delete = { 'gpd' },
			rewrite = { 'gpr' },
			stop = { 'gpx' },
		},
	},
}

---Helper function for resolve_variables.
---Replaces any supported variable placeholder with the corrsponding computed value
local function resolve_variable(orig_value, settings)
	local value = orig_value
	value, _ = string.gsub(value, "%${env:([%w_]+)}", function (capture)
		local env_value = os.getenv(capture)
		if env_value == nil then return "" end
		return env_value:gsub('\r', '')
	end)
	value, _ = string.gsub(value, "%${ide:PROJECT_ROOT}", settings.PROJECT_ROOT_DIRECTORY)
	value, _ = string.gsub(value, "%${ide:IDE_DIRECTORY}", settings.IDE_DIRECTORY)
	return value
end


---Resolves special variable names anywhere in the settings
---
---Supported variables are:
---
---  Environment variables: the pattern ${env:VARIABLE_NAME} will be replaced with the value from the environment variable VARIABLE_NAME.
---                         If the variable doesn't exist it's replaced with an empty string.
---                         The variable name is not recursively expanded
---
---  IDE variables: the pattern ${ide:IDE_VARIABLE} is replaced with the value provided by the IDE itself.
---                 Here's the list of variables currently supported:
---     							- PROJECT_ROOT: the full path to the project root (where the .nvim.proj.lua file is located)
---@param settings table<string, string>
local function resolve_variables(settings)
	return utils.tables.deepmap(settings, function(config)
			if type(config) == 'string' then
				return resolve_variable(config, settings)
			end
			return config
		end)
end

---Creates a new project configuration file in the project root folder. 
---If the template is specified, it is used to index the defined
---templates in the settings to fill the otherwise empty settings table
---with some initial values. Normally one would set custom predefined
---templates in the user-level config file in the home folder, otherwise
---just rely on the default ones from the IDE.
---
---If the requested template doesn't exist an error is reported and the
---command does nothing.
---
---If a project config file already exists it is just opened for edit.
---
---@param template_name string?
---@param settings ProjectSettings
local function create_or_open_project_file(template_name, settings)
	if utils.files.path_exists(settings.PROJECT_SETTINGS_FILE, false) then
		vim.notify('Opening existing project settings')
		vim.cmd.edit(settings.PROJECT_SETTINGS_FILE)
		return
	end

	if template_name == nil then template_name = "empty" end

	local template = settings.project_templates[template_name]
	if template == nil then
		vim.notify('Unknown project template: ' .. template_name, vim.log.levels.ERROR)
		return
	end

	if not utils.files.is_dir(template.template_dir) then
		vim.notify('templte folder ' .. template.template_dir .. ' is not a directory', vim.log.levels.ERROR)
		return
	end

	utils.files.copy_folder(template.template_dir, settings.PROJECT_ROOT_DIRECTORY,
													function ()
														vim.cmd.edit(settings.PROJECT_SETTINGS_FILE)
														if template.post_dir_init ~= nil then
															local notif = vim.notify("setting up project template", vim.log.levels.INFO, { keep = function() return true end })
															template.post_dir_init(utils, function()
																vim.notify("project template setup done", vim.log.levels.INFO, { replace = notif, keep = function() return false end })
															end)
														end
													end,
													function(output, _) vim.notify(output, vim.log.levels.ERROR) end)

end

return {
	-- mostly for testing purposes
	default_settings = default_settings,

	---@return ProjectSettings
	load_settings = function()
		local settings = utils.tables.deepcopy(default_settings)

		local user_default_settings_file = table.concat({vim.fn.expand('$HOME'), PROJECT_SETTINGS_FILE}, utils.files.OS.sep)
		if utils.files.path_exists(user_default_settings_file, false) then
			local user_default_settings = dofile(user_default_settings_file)
			---@cast user_default_settings ProjectSettings
			settings = utils.tables.deepmerge(settings, user_default_settings)
		end

		if utils.files.path_exists(PROJECT_SETTINGS_FILE, false) then
			local custom_settings = dofile(PROJECT_SETTINGS_FILE)
			---@cast custom_settings ProjectSettings
			settings = utils.tables.deepmerge(settings, custom_settings)
		end

		-- Read only fields.
		-- They're intentionally not customizable from project file,
		-- only available to be referenced by plugins if needed (see e.g. debugging)
		-- Must be set before resolving variables since some of them might be used during that process
		settings.PROJECT_SETTINGS_FILE = PROJECT_SETTINGS_FILE
		settings.DATA_DIRECTORY = utils.get_data_directory()
		settings.PROJECT_ROOT_DIRECTORY = vim.fn.getcwd(-1, -1)
		settings.IDE_DIRECTORY = table.concat({ vim.fn.stdpath('config'), 'lua', 'basicIde' }, utils.files.OS.sep)

		settings = resolve_variables(settings)

		return settings
	end,

	---@param settings ProjectSettings
	---@return nil
	init = function(settings)
		if settings.project_title ~= nil then
			local title = settings.project_title
			if settings.editor.append_git_branch_to_title then
				local branch = utils.paths.trim(table.concat(utils.proc.runAndReturnOutputSync('git rev-parse --abbrev-ref HEAD'), ""))
				title = utils.paths.trim(title) .. ' [' .. branch .. ']'
			end
			utils.loader.set_title(title)
		end

		vim.api.nvim_create_user_command('BasicIdeSetTitle', function()
			vim.ui.input({ prompt = 'Title: ', default = utils.loader.get_title() }, function(title)
				if title == nil or #title == 0 then return end
				utils.loader.set_title(title)
			end)
		end, {
			nargs = 0,
			desc = 'Set window title',
		})

		if settings.editor.append_git_branch_to_title then
			vim.api.nvim_create_autocmd('User', {
				group = 'BasicIde.GitMonitor',
				pattern = 'HeadChange',
				desc = 'Append git branch to title',
				callback = function(event)
					if #event.data.new_head ~= 0 then
						utils.loader.set_title(settings.project_title .. ' [' .. event.data.new_head .. ']')
					end
				end,
			})
		end

		vim.api.nvim_create_user_command('BasicIdeInitProject', function(params)
				create_or_open_project_file(params.fargs[1], settings)
			end, {
			nargs = '?',
			complete = function(arglead, _, _)
				return utils.tables.filter(vim.tbl_keys(settings.project_templates),
													         function(template) return vim.startswith(template, arglead) end)
			end,
			desc = 'Create and edit a new project settings file, optionally using a template. If the file already exists it will just be opened',
		})
		vim.api.nvim_create_user_command('BasicIdeListProjectTemplates', function()
				print('Available project templates:\n' .. table.concat(vim.tbl_keys(settings.project_templates), '\n'))
			end, {
			nargs = 0,
			desc = 'List available project templates'
		})

		run_custom_startup_scripts(settings, utils)
		init_custom_keymaps(settings, utils)
	end
}
