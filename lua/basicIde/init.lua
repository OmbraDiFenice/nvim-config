require('basicIde/globals')

---@class IdeModule
---@field use_deps fun(use: fun(plugin_spec: any), project_settings: ProjectSettings, use_rocks: fun(plugin_spec: any)): nil
---@field configure fun(project_settings: ProjectSettings): nil

local project = require('basicIde/project')
local project_settings = project.load_settings()

---@type string[]
local components = {}
table.insert(components, 'basicIde/vimSettings') -- must be first
table.insert(components, 'basicIde/theme')
table.insert(components, 'basicIde/completion') -- lsp uses nvim-cmp to advertise extra capabilities, so configure it first
table.insert(components, 'basicIde/lsp')
table.insert(components, 'basicIde/folding')
table.insert(components, 'basicIde/search')
table.insert(components, 'basicIde/folderView')
table.insert(components, 'basicIde/notifications')
table.insert(components, 'basicIde/git') -- uses notifications
table.insert(components, 'basicIde/session')
table.insert(components, 'basicIde/terminal')
table.insert(components, 'basicIde/editor') -- requires search, treesitter (folding), lsp
table.insert(components, 'basicIde/debugging')
table.insert(components, 'basicIde/coverage')
table.insert(components, 'basicIde/codeFormatting')
table.insert(components, 'basicIde/remote_sync')
table.insert(components, 'basicIde/code_layout')
table.insert(components, 'basicIde/ai')
table.insert(components, 'basicIde/statusBar') -- depends on the existence of the event groups it listens for, so better to load it last
                                               -- depends on the theme being already loaded
																							 -- depends on search module for trouble integration

---@type { use_deps: fun(use: fun(plugin_sepc: any), use_rocks: fun(plugin_spec: any)), configure: fun() }
return {
	use_deps = function(use, use_rocks)
		for _, component in ipairs(components)
		do
			---@type boolean, IdeModule
			local ok, module = pcall(require, component)
			if ok then
				module.use_deps(use, project_settings, use_rocks)
			else
				vim.notify('error while loading module ' .. component .. '. Skipping for now, try relunch nvim again to see if it gets fixed', vim.log.levels.WARN)
				vim.notify('error message:\n' .. module, vim.log.levels.DEBUG)
			end
		end
	end,

	configure = function()
		for _, component in ipairs(components)
		do
			---@type boolean, IdeModule
			local ok, module = pcall(require, component)
			if ok then
				module.configure(project_settings)
			else
				vim.notify('error while configuring module ' .. component .. '. Skipping for now, try relunch nvim again to see if it gets fixed', vim.log.levels.WARN)
				vim.notify('error message:\n' .. module, vim.log.levels.DEBUG)
			end
		end

		project.init(project_settings)

		vim.api.nvim_create_autocmd('BufWritePost', {
			pattern = project_settings.PROJECT_SETTINGS_FILE,
			desc = 'reload ' .. project_settings.PROJECT_SETTINGS_FILE .. ' on save',
			callback = function()
				local utils = require('basicIde/utils')
				-- Need to mutate the existing object so that every component gets the update on the shared object
				-- Clear the array fields that will be recreated by the event handlers. These are fields that might have been
				-- removed in the last update and need not be present in the updated settings, but a simple table merge would keep them.
				project_settings.debugging.external_scripts = {}
				utils.tables.deepmerge(project_settings, project.load_settings())
				vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectSettingsChanged' })
			end,
		})

		vim.api.nvim_create_user_command('BasicIdeShowInstallCheck',
			function()
				local report_file = os.getenv('REPORT_FILE')
				if report_file == nil or io.lines(report_file) == nil then
					vim.notify('No report to display')
					return
				end
				local show_report = require('basicIde.loader.show_report')
				show_report()
			end,
			{
				nargs = 0,
				desc = 'Show the install check report, if there was one',
		})
	end,
}
