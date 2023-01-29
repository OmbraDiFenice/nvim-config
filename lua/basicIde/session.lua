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
		}

		vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
	end,
}
