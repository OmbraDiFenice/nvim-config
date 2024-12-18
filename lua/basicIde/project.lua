local utils = require('basicIde.utils')
local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

---@class NotificationSettings
---@field enabled boolean

---@class FormatOnSaveKeymapsSettings
---@field format_current_buffer string[]

---@class FormatOnSaveSettings
---@field enabled boolean
---@field keymaps FormatOnSaveKeymapsSettings

---@class DapConfigurationExtended: Configuration
---@field unittest? boolean
---@field keymap string
---@field keymap_coverage string
---@field is_coverage? boolean
---@field open_console_on_start? boolean

---@class DapConfigurationExtendedPython: DapConfigurationExtended
---@field args string[]
---@field module string

---@class DapSessionExtended: Session
---@field is_coverage? boolean

---@class DebuggingSettings
---@field dap_configurations? table<string, DapConfigurationExtended[]>

---@class TerminalSettings
---@field init_environment_cmd string

---@class RemoteSyncSettings
---@field enabled boolean
---@field strategy string -- 'rsync'
---@field rsync_settings RsyncStrategySettings
---@field quantconnect_settings QuantConnectStrategySettings
---@field sync_on_save boolean
---@field sync_on_git_head_change boolean
---@field mappings string[][] -- mapping of the folders to sync in the form of { { local_path1, remote_path1}, {local_path2, remote_path_2} ...} . Both local and remote paths must be absolute
---@field exclude_paths string[] -- local paths to exclude from sync. They're considered relative to the project root. To exclude directories the path must end with a slash
---@field exclude_git_ignored_files boolean
---@field notifications NotificationSettings

---@class CustomKeymapDef
---@field desc string?
---@field fun string|fun(utils: Utils, settings: ProjectSettings): nil -- if string build a simple run command
---@field verbose boolean? -- only applicable when fun is a string. Print information about start and end of called external command. Default to false

---@class LspSettings
---@field notifications NotificationSettings

---@class TokenPattern
---@field type 'token'|'node_type'
---@field value string

---@class CodeLayoutLanguageConfig
---@field node_types string[] treesitter node types to consider when building the layout
---@field stop_at_tokens TokenPattern[] stop extracting node signature when any of these tokens are matched within it
---@field ignore_tokens TokenPattern[] skip extracting text for node signature from any of the matching nodes

---@class CodeLayoutConfig
---@field languages table<string, CodeLayoutLanguageConfig>
---@field indent_width integer how much to indent each entry in the code layout. The indent is relative to the position of that node counting only the specific language node types
---@field keymaps table<string, string[]>

---@class TreeViewConfig
---@field open_on_start boolean
---@field keymaps table<string, string[]>

---@class EditorConfig
---@field autosave boolean
---@field tree_view TreeViewConfig

---@class LoaderConfig
---@field virtual_environment? string
---@field environment table<string, string> environment variables <name, value> to set before launching nvim via the loader. Use ${env:PATH} to include values from the existing PATH environment variable
---@field init_script string script to be executed before starting nvim, after having sourced the venv and loaded the environment from this config. The interpreter is the same used in nvim_loader.sh

---@class AiConfig
---@field enabled boolean
---@field engine "codeium"|"copilot"
---@field disable_for_all_filetypes boolean
---@field filetypes table<string, boolean> -- explicitly enable or disable AI for specific filetypes. The default for unspecified filetypes depends on disable_for_all_filetypes. There are some default applied implicitly (see the module config code), but they can always be overridden manually
---@field manual boolean
---@field render_suggestion boolean
---@field keymaps table<string, string[]> -- they keys are fixed and associated to each possible AI action. The value is a list of keymaps shortcut to trigger the action in a format similar to the keys associated to CustomKeymapDef in other configs. These keymaps should always be set for insert mode
---@field show_in_status_bar boolean

---@class ProjectSettings
---@field PROJECT_SETTINGS_FILE string
---@field DATA_DIRECTORY string
---@field project_title string
---@field loader LoaderConfig
---@field format_on_save FormatOnSaveSettings
---@field debugging DebuggingSettings
---@field terminal TerminalSettings
---@field remote_sync RemoteSyncSettings
---@field custom_startup_scripts table<string, fun(utils: Utils): nil>
---@field custom_keymaps table<string, CustomKeymapDef>
---@field lsp LspSettings
---@field code_layout CodeLayoutConfig
---@field editor EditorConfig
---@field ai AiConfig
---@field build_remote_url fun(commit_hash: string): string? -- builds the url for the given commit so that it can be opened in the browser with a key shortcut from Diffview history view. Return the url or nil to cancel the operation

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
	PROJECT_SETTINGS_FILE = '',
	DATA_DIRECTORY = '',
	project_title = '[nvim IDE] ' .. vim.fn.getcwd(-1, -1),
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
	},
	lsp = {
		notifications = {
			enabled = true,
		},
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
	custom_keymaps = {},
	code_layout = {
		indent_width = 2,
		languages = {
			python = {
				node_types = {'class_definition', 'function_definition'},
				stop_at_tokens = { { type = 'token', value = ':' }, },
				ignore_tokens = { { type = 'node_type', value = 'comment' }, },
			},
		},
		keymaps = {
			open_layout = {'<leader>l'}, -- from the file to analyze
			close_layout = {'q'}, -- from within layout buffer
			goto_and_close_layout = {'<CR>', 'l', 'h'}, -- from within layout buffer
		},
	},
	editor = {
		autosave = true,
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
			},
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
}

---Helper function for resolve_variables.
---Replaces any supported variable placeholder with the corrsponding computed value
local function resolve_variable(orig_value)
	local value = orig_value
	value, _ = string.gsub(value, "%${env:([%w_]+)}", function (capture)
		local env_value = os.getenv(capture)
		if env_value == nil then return "" end
		return env_value:gsub('\r', '')
	end)
	value, _ = string.gsub(value, "%${ide:PROJECT_ROOT}", vim.fn.getcwd(-1, -1))
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
				return resolve_variable(config)
			end
			return config
		end)
end

return {
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

		settings = resolve_variables(settings)

		-- Read only fields.
		-- They're intentionally not customizable from project file,
		-- only available to be referenced by plugins if needed (see e.g. debugging)
		settings.PROJECT_SETTINGS_FILE = PROJECT_SETTINGS_FILE
		settings.DATA_DIRECTORY = utils.get_data_directory()

		return settings
	end,

	---@param settings ProjectSettings
	---@return nil
	init = function(settings)
		run_custom_startup_scripts(settings, utils)
		init_custom_keymaps(settings, utils)
	end
}
