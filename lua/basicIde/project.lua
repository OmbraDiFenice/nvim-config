local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

---@class FormatOnSaveKeymapsSettings
---@field format_current_buffer string

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
---@field sync_on_save boolean
---@field remote_user? string
---@field remote_host? string
---@field mappings string[][]
---@field exclude_paths string[] -- local paths to exclude from sync. To exclude directories the path must end with a slash
---@field exclude_git_ignored_files boolean

---@class CustomKeymapDef
---@field desc string?
---@field fun string|fun(...): nil -- if string build a simple run command
---@field verbose boolean? -- only applicable when fun is a string. Default to false

---@class LspNotificationSettings
---@field enabled boolean

---@class LspSettings
---@field notifications LspNotificationSettings

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
---@field keymaps table<string, CustomKeymapDef> function will receive a reference to the instance of code layout being interacted with

---@class ProjectSettings
---@field PROJECT_SETTINGS_FILE string
---@field virtual_environment? string
---@field format_on_save FormatOnSaveSettings
---@field debugging DebuggingSettings
---@field terminal TerminalSettings
---@field remote_sync RemoteSyncSettings
---@field custom_startup_scripts table<string, fun(utils: Utils): nil>
---@field custom_keymaps table<string, CustomKeymapDef>
---@field lsp LspSettings
---@field code_layout CodeLayoutConfig

---@class UserProjectSettings
---@field virtual_environment? string
---@field format_on_save? FormatOnSaveSettings
---@field debugging? DebuggingSettings
---@field terminal? TerminalSettings
---@field remote_sync? RemoteSyncSettings
---@field custom_startup_scripts? table<string, fun(utils: Utils): nil> the key is just a name used for reference and error reporting purposes
---@field custom_keymaps? table<string, CustomKeymapDef> the key is the keymap shortcut in the format '<mode> <shortcut>' (e.g. 'n <leader>X'). If <mode> is omitted it defaults to n. Callbacks will receive a reference to the basicIde.utils module
---@field lsp? LspSettings
---@field code_layout? CodeLayoutConfig

---Execute the callbacks in `custom_startup_scripts` setting
---@param settings ProjectSettings
---@return nil
local function run_custom_startup_scripts(settings, utils)
	for script_name, callback in pairs(settings.custom_startup_scripts) do
		callback(utils)
	end
end

---Initialize keymaps from `custom_keymaps` setting
---@param settings ProjectSettings
---@return nil
local function init_custom_keymaps(settings, utils)
	for mode_shortcut, keymap_def in pairs(settings.custom_keymaps) do
		local mode, shortcut, callback, desc = utils.parse_custom_keymap_config(mode_shortcut, keymap_def)
		vim.keymap.set(mode, shortcut, function() callback(utils) end, { desc = desc })
	end
end

---@type ProjectSettings
local default_settings = {
	PROJECT_SETTINGS_FILE = '',
	virtual_environment = nil,
	format_on_save = { -- WARNING: if enabled together with autosave it will pollute the undo history and you won't be able to undo changes anymore
		enabled = false, -- 1. you make a change -> autosave triggers -> changes go to undo history
                     -- 2. buffer is autoformatted -> buffer is changed -> autosave triggers again -> autoformatting changes go to undo history
                     -- 3. you want to undo changes made at point 1, but:
                     --    - hitting 'u' actually undoes the reformatting from point 2
                     --    - that triggers autoformat again
                     --    - you're back to the change you wanted to undo
		keymaps = {
			format_current_buffer = '<F7>',
		}
	},
	debugging = {
		dap_configurations = nil,
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
		sync_on_save = true,
		remote_user = nil, -- required
		remote_host = nil, -- required
		mappings = { -- required
			-- { local_prefix_dir, remote_prefix_dir },
			-- ...
		},
		exclude_paths = {},
		exclude_git_ignored_files = true,
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
			['q'] = {
				desc = '[Code layout] close code layout',
				fun = function(code_layout)
					code_layout:close_code_layout_window()
				end
			},
			['<CR>'] = {
				desc = '[Code layout] goto to symbol and close layout',
				fun = function(code_layout)
					code_layout:navigate_to_source()
					code_layout:close_code_layout_window()
				end
			},
			['l'] = {
				desc = '[Code layout] goto to symbol and close layout',
				fun = function(code_layout)
					code_layout:navigate_to_source()
					code_layout:close_code_layout_window()
				end
			},
			['h'] = {
				desc = '[Code layout] goto to symbol and close layout',
				fun = function(code_layout)
					code_layout:navigate_to_source()
					code_layout:close_code_layout_window()
				end
			},
		},
	}
}

return {
	---@return ProjectSettings
	load_settings = function()
		local settings = Deepcopy(default_settings)

		if File_exists(PROJECT_SETTINGS_FILE) then
			local custom_settings = dofile(PROJECT_SETTINGS_FILE)
			---@cast custom_settings ProjectSettings
			settings = Deepmerge(settings, custom_settings)
		end

		-- Read only field.
		-- It's intentionally not customizable from project file,
		-- only available to be referenced by plugins if needed (see e.g. debugging)
		settings.PROJECT_SETTINGS_FILE = PROJECT_SETTINGS_FILE

		return settings
	end,

	---@param settings ProjectSettings
	---@return nil
	init = function(settings)
		local utils = require('basicIde.utils')
		run_custom_startup_scripts(settings, utils)
		init_custom_keymaps(settings, utils)
	end
}
