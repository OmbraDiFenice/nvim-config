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

---@type { use_deps: fun(use: fun(plugin_sepc: any)), configure: fun() }
return {
	use_deps = function(use)
		for _, component in ipairs(components)
		do
			---@type IdeModule
			local module = require(component)
			module.use_deps(use, project_settings)
		end
	end,

	configure = function()
		for _, component in ipairs(components)
		do
			---@type IdeModule
			local module = require(component)
			module.configure(project_settings)
		end

		project.init_custom_scripts(project_settings)
	end,
}
