local utils = require('basicIde.utils')

---@type IdeModule
return {
	use_deps = function()
	end,

	configure = function(project_settings)
		local vimscript_path = table.concat({project_settings.IDE_DIRECTORY, "vimSettings.vim"}, utils.files.OS.sep)
		vim.cmd('source ' .. vimscript_path)
	end,
}
