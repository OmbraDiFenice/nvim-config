local close_nvim_tree = function()
	local nvim_api = require('nvim-tree.api')
	if nvim_api ~= nil then
		nvim_api.tree.close()
	end
end

local open_nvim_tree = function()
	local nvim_api = require('nvim-tree.api')
	if nvim_api ~= nil then
		nvim_api.tree.open()
	end
end

return {
	use_deps = function(use)
		use 'rmagatti/auto-session'
	end,

	configure = function()
		require('auto-session').setup {
			log_level = "error",
			auto_session_root_dir = vim.fn.getcwd().."/.sessions/",
      auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/"},
			auto_session_use_git_branch = true,

			-- can't be done in nvim-tree, see https://github.com/nvim-tree/nvim-tree.lua/issues/1992#issuecomment-1455504628
			pre_save_cmds = { close_nvim_tree },
			post_restore_cmds = { open_nvim_tree },
		}

		vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
	end,
}
