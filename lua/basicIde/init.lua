local components = {}
table.insert(components, 'basicIde/theme')
table.insert(components, 'basicIde/statusBar')
table.insert(components, 'basicIde/completion') -- lsp uses nvim-cmp to advertise extra capabilities, so configure it first
table.insert(components, 'basicIde/lsp')
table.insert(components, 'basicIde/vimSettings')
table.insert(components, 'basicIde/folding')
table.insert(components, 'basicIde/search')
table.insert(components, 'basicIde/folderView')

return {
	use_deps = function(use)
		for _, component in ipairs(components)
		do
			require(component).use_deps(use)
		end
	end,

	configure = function()
		for _, component in ipairs(components)
		do
			require(component).configure()
		end
	end,
}
