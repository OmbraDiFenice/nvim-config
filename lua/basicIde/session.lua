local close_nvim_tree = function()
	local nvim_tree_api = require('nvim-tree.api')

	if nvim_tree_api ~= nil then
		nvim_tree_api.tree.close_in_all_tabs()
	end
end

local open_nvim_tree = function()
	local nvim_tree_api = require('nvim-tree.api')
	local nvim_tree_view = require('nvim-tree.view')

	if nvim_tree_api ~= nil and nvim_tree_view ~= nil then
		if not nvim_tree_view.is_visible() then
			nvim_tree_api.tree.open()
		end

		if vim.api.nvim_get_current_buf() == nvim_tree_view.get_bufnr() and vim.fn.expand('#') ~= '' then
			vim.cmd [[ :e # ]]
		end
	end
end

return {
	use_deps = function(use)
		use 'rmagatti/auto-session'
	end,

	configure = function()
		require('auto-session').setup {
			log_level = "error",
			auto_session_root_dir = Get_data_directory(),
      auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/"},
			auto_session_use_git_branch = true,

			-- can't be done in nvim-tree, see https://github.com/nvim-tree/nvim-tree.lua/issues/1992#issuecomment-1455504628
			pre_save_cmds = { close_nvim_tree },
			post_restore_cmds = { open_nvim_tree },
		}

		vim.o.sessionoptions="blank,buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"
	end,
}
