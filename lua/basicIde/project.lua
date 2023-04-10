local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

return {
	use_deps = function(use)
	end,

	configure = function()
		if File_exists(PROJECT_SETTINGS_FILE)
		then
			vim.cmd('source ' .. PROJECT_SETTINGS_FILE)
		end
	end,
}
