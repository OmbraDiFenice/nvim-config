---@alias PackerStringOrList string|string[]
---@alias PackerCondition string|fun(): boolean|(string|fun(): boolean)[]
---@alias PackerHook string|fun(...): any|table<any, any>
---@alias PackerDependency string|PackerPluginSpec|(string|PackerPluginSpec)[]
---@alias PackerUseSpec string|PackerPluginSpec

---@class PackerPluginSpec
---@field [1] string plugin location string passed as the first positional entry to `packer.use`
---@field disable? boolean
---@field as? string
---@field installer? fun(...): any
---@field updater? fun(...): any
---@field after? PackerStringOrList
---@field rtp? string
---@field opt? boolean
---@field bufread? boolean
---@field branch? string
---@field tag? string
---@field commit? string
---@field lock? boolean
---@field run? PackerHook
---@field requires? PackerDependency
---@field rocks? PackerStringOrList
---@field config? string|fun(...): any
---@field setup? string|fun(...): any
---@field cmd? PackerStringOrList
---@field ft? PackerStringOrList
---@field keys? PackerStringOrList
---@field event? PackerStringOrList
---@field fn? PackerStringOrList
---@field cond? PackerCondition
---@field module? PackerStringOrList
---@field module_pattern? PackerStringOrList

-- ---------------------- IDE types ----------------------

---@class NotificationSettings
---@field enabled boolean

---@class FormatOnSaveKeymapsSettings
---@field format_current_buffer string[]

---@class FormatOnSaveSettings
---@field enabled boolean
---@field keymaps FormatOnSaveKeymapsSettings

---@class DapConfigurationExtended: dap.Configuration
---@field unittest? boolean
---@field keymap string
---@field keymap_coverage string
---@field is_coverage? boolean
---@field open_console_on_start? boolean

---@class DapConfigurationExtendedPython: DapConfigurationExtended
---@field args string[]
---@field module string

---@class DapSessionExtended: dap.Session
---@field is_coverage? boolean

---@class ExternalScript
---@field name string
---@field template string?
---@field keymap string
---@field command string[]
---@field args string[]|nil
---@field cwd string?
---@field open_console_on_start? boolean
---@field open_console_on_end? boolean

---@class DebuggingSettings
---@field dap_configurations? table<string, DapConfigurationExtended[]>
---@field external_scripts ExternalScript[]

---@class TerminalSettings
---@field init_environment_cmd string

---@class RemoteSyncSettings
---@field enabled boolean
---@field strategy string -- 'rsync'
---@field rsync_settings RsyncStrategySettings
---@field quantconnect_settings QuantConnectStrategySettings
---@field sync_on_save boolean
---@field sync_on_git_head_change boolean
---@field mappings string[][] -- mapping of the folders to sync in the form of { { local_path1, remote_path1}, {local_path2, remote_path2} ...} . Both local and remote paths must be absolute
---@field exclude_paths string[] -- local paths to exclude from sync. They're considered relative to the project root. To exclude directories the path must end with a slash
---@field exclude_git_ignored_files boolean
---@field notifications NotificationSettings

---@class CustomKeymapDef
---@field desc string?
---@field fun string|fun(utils: Utils, settings: ProjectSettings): nil -- if string build a simple run command
---@field verbose boolean? -- only applicable when fun is a string. Print information about start and end of called external command. Default to false

---@class LspSettings
---@field notifications NotificationSettings
---@field extra_server_cli table<string, string[]> -- key is the server name and the value is a list of extra arguments to be passed to the server when starting it
---@field server_settings table<string, table<any, any>> -- key is the server name and the value is the settings to apply to that server. These settings are merged with any default ones defined in the IDE and take precedence over them in case of conflict

---@class TokenPattern
---@field type 'token'|'node_type'
---@field value string

---@class CodeLayoutQuery
---@field query string treesitter query to extract nodes to display in the code layout
---@field format string the format string to be used to build the code layout buffer entry for each capture coming from the query. If a capture is empty (e.g. because it's optional) it is not displayed and any space before that capture is removed from the final output
---@field root_capture string? the name of the capture in the query that points to the root node to be used as "anchor" in the source buffer. This is the node where the cursor is brought to, the one accordng to which the indentation is computed and more. If not specified it defaults to "root"

---@class CodeLayoutLanguageConfig
---@field node_types string[] treesitter node types to consider when building the layout
---@field stop_at_tokens TokenPattern[] stop extracting node signature when any of these tokens are matched within it
---@field ignore_tokens TokenPattern[] skip extracting text for node signature from any of the matching nodes
---@field queries CodeLayoutQuery[]

---@class CodeLayoutConfig
---@field strategy string
---@field languages table<string, CodeLayoutLanguageConfig>
---@field indent_width integer how much to indent each entry in the code layout. The indent is relative to the position of that node counting only the specific language node types
---@field keymaps table<string, string[]>

---@class TreeViewConfig
---@field open_on_start boolean
---@field keymaps table<string, string[]>

---@class RecenterViewportConfig
---@field enabled boolean
---@field ignore_filetypes string[] filetypes for which the recenter should be always disabled

---@class ActivityMonitorConfig
---@field enabled boolean
---@field keymaps table<string, string[]>

---@class CodeBreadcrumbConfig
---@field enabled boolean
---@field provider "trouble"|"treesitter"

---@class StatusBarConfig
---@field code_breadcrumb CodeBreadcrumbConfig

---@class SystemNotificationConfig
---@field icons table<vim.log.levels, string> -- mapping between vim log levels and icon name (system icon name or path to image). If not defined takes the system default icon
---@field transient boolean

---@class GlobalNotificationConfig
---@field strategy "vanilla"|"nvim-float"|"system"
---@field system_configs SystemNotificationConfig

---@class EditorConfig
---@field autosave boolean
---@field tree_view TreeViewConfig
---@field recenter_viewport RecenterViewportConfig
---@field activity_monitor ActivityMonitorConfig
---@field status_bar StatusBarConfig
---@field append_git_branch_to_title boolean
---@field notifications GlobalNotificationConfig
---@field keymaps table<string, string[]> -- they keys are fixed and associated to each possible AI action. The value is a list of keymaps shortcut to trigger the action in a format similar to the keys associated to CustomKeymapDef in other configs. These keymaps should always be set for insert mode

---@class LoaderConfig
---@field virtual_environment? string path to the virtual environment to launch nvim with. If the path is relative it will be resolved relative to the project root
---@field environment table<string, string> environment variables <name, value> to set before launching nvim via the loader. Use ${env:PATH} to include values from the existing PATH environment variable
---@field init_script string script to be executed before starting nvim, after having sourced the venv and loaded the environment from this config. The interpreter is the same used in nvim_loader.sh

---@class AiChatConfig
---@field enabled boolean
---@field provider string -- 'openai'
---@field api_key string
---@field endpoint string?
---@field keymaps table<string, string[]> -- they keys are fixed and associated to each possible action. The value is a list of keymaps shortcut to trigger the action in a format similar to the keys associated to CustomKeymapDef in other configs.

---@class AiConfig
---@field enabled boolean
---@field engine "codeium"|"copilot"
---@field disable_for_all_filetypes boolean
---@field filetypes table<string, boolean> -- explicitly enable or disable AI for specific filetypes. The default for unspecified filetypes depends on disable_for_all_filetypes. There are some default applied implicitly (see the module config code), but they can always be overridden manually
---@field manual boolean
---@field render_suggestion boolean
---@field keymaps table<string, string[]> -- they keys are fixed and associated to each possible AI action. The value is a list of keymaps shortcut to trigger the action in a format similar to the keys associated to CustomKeymapDef in other configs. These keymaps should always be set for insert mode
---@field show_in_status_bar boolean

---@class PerformanceSettings
---@field disable_treesitter_highlight fun(lang: string, bufnr: integer): boolean -- return true if treesitter highlight should be disabled. Takes the buffer language and the bufnr as parameters

---@class ProjectTemplate
---@field template_dir string -- path of the folder containing the files to copy to initialize the project template
---@field post_dir_init nil|fun(utils: Utils, end_cb: fun():nil): nil -- optional function to be called after the template directy has been copied. end_cb must be called once the post init is complete

---@class ProjectSettings
---@field PROJECT_SETTINGS_FILE string
---@field PROJECT_ROOT_DIRECTORY string
---@field DATA_DIRECTORY string
---@field IDE_DIRECTORY string -- path to the directory where the IDE code is located (inside nvim config). To be used as a convenience in some components to point to utility scripts in there
---@field project_title string
---@field project_languages string[] -- languages to use in this project. Used to e.g. ensure the TreeSitter parsers are installed
---@field project_templates table<string, ProjectTemplate> -- key is the name of the template
---@field loader LoaderConfig
---@field format_on_save FormatOnSaveSettings
---@field debugging DebuggingSettings
---@field terminal TerminalSettings
---@field remote_sync RemoteSyncSettings
---@field custom_packer_plugins PackerUseSpec[] -- list of packer specs to install custom plugins. They are added after all the IDE modules have been loaded (but before they're configured).
---@field custom_startup_scripts table<string, fun(utils: Utils): nil>
---@field custom_keymaps table<string, CustomKeymapDef>
---@field lsp LspSettings
---@field code_layout CodeLayoutConfig
---@field editor EditorConfig
---@field ai AiConfig
---@field ai_chat AiChatConfig
---@field build_remote_url fun(commit_hash: string): string? -- builds the url for the given commit so that it can be opened in the browser with a key shortcut from Diffview history view. Return the url or nil to cancel the operation
---@field performance PerformanceSettings
