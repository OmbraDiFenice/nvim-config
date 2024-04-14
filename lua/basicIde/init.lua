require('basicIde/globals')

---@class IdeModule
---@field use_deps fun(use: fun(plugin_spec: any), project_settings: ProjectSettings): nil
---@field configure fun(project_settings: ProjectSettings): nil

local project = require('basicIde/project')
local project_settings = project.load_settings()

---@type string[]
local components = {}
table.insert(components, 'basicIde/theme')
table.insert(components, 'basicIde/statusBar')
table.insert(components, 'basicIde/completion') -- lsp uses nvim-cmp to advertise extra capabilities, so configure it first
table.insert(components, 'basicIde/lsp')
table.insert(components, 'basicIde/vimSettings')
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

---@type { use_deps: fun(use: fun(plugin_sepc: any)), configure: fun() }
return {
	use_deps = function(use)
		for _, component in ipairs(components)
		do
			---@type boolean, IdeModule
			local ok, module = pcall(require, component)
			if ok then
				module.use_deps(use, project_settings)
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
	end,
}
