---@type IdeModule
return {
	use_deps = function(use)
	end,

	configure = function(project_settings)
		-- required since apparently nvim -c 'lua Get_data_directory()' doesn't work
		vim.api.nvim_create_user_command('GetDataDirectory', function () print(Get_data_directory()) end, {})
	end
}
