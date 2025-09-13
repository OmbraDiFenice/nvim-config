local utils = require('basicIde.utils')

---@type IdeModule
return {
	use_deps = function(use)
	end,

	configure = function(project_settings)
		local dap = require('dap')
		local mason_registry = require('mason-registry')

		if not mason_registry.is_installed("cpptools") then return end

		local cpptools = mason_registry.get_package("cpptools")
		dap.adapters.cppdbg = {
			id = "cppdbg",
			type = "executable",
			command = table.concat({ cpptools:get_install_path(), cpptools.spec.source.asset[1].bin }, utils.files.OS.sep),
		}
	end
}
