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
table.insert(components, 'basicIde/git')
table.insert(components, 'basicIde/session')
table.insert(components, 'basicIde/terminal')
table.insert(components, 'basicIde/editor')
table.insert(components, 'basicIde/debugging')
table.insert(components, 'basicIde/coverage')
table.insert(components, 'basicIde/codeFormatting')
table.insert(components, 'basicIde/remote_sync')
table.insert(components, 'basicIde/notifications')
table.insert(components, 'basicIde/code_layout')
table.insert(components, 'basicIde/ai')
table.insert(components, 'basicIde/statusBar') -- depends on the existence of the event groups it listens for

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
				-- need to mutate the existing object so that every component gets the update on the shared object
				utils.tables.deepmerge(project_settings, project.load_settings())
				vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectSettingsChanged' })
			end,
		})
	end,
}
