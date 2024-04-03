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

--- Function written following the tutorial at https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md
local function edit_session_file()
	local auto_session = require('auto-session')
	local pickers = require('telescope.pickers')
	local finders = require('telescope.finders')
	local conf = require('telescope.config').values
	local themes = require('telescope.themes')

	local session_files = auto_session.get_session_files()
	local function get_display_name(session_entry)
		if session_entry.display_name ~= nil then return session_entry.display_name end
		return session_entry.path
	end

	local opts = themes.get_dropdown({})
	pickers.new(opts, {
			finder = finders.new_table {
				results = session_files,
				entry_maker = function (entry)
					return {
						value = entry,
						display = function(tbl) return get_display_name(tbl.value) end,
						ordinal = entry.path,
						path = auto_session.get_root_dir() .. entry.path,
					}
				end,
			},
			sorter = conf.generic_sorter(opts),
		}):find()
end

---@type IdeModule
return {
	use_deps = function(use)
		use 'rmagatti/auto-session'
	end,

	---@param settings ProjectSettings
	configure = function(settings)
		local pre_save_cmds = {}
		local post_restore_cmds = {}

		if settings.editor.open_tree_view_on_start then
			table.insert(pre_save_cmds, close_nvim_tree)
			table.insert(post_restore_cmds, open_nvim_tree)
		end

		require('auto-session').setup {
			log_level = "error",
			auto_session_root_dir = Get_data_directory(),
			auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			auto_session_use_git_branch = true,

			-- can't be done in nvim-tree, see https://github.com/nvim-tree/nvim-tree.lua/issues/1992#issuecomment-1455504628
			pre_save_cmds = pre_save_cmds,
			post_restore_cmds = post_restore_cmds,
		}

		vim.o.sessionoptions = "blank,buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"

		vim.keymap.set('n', '<leader>es', edit_session_file, { desc = "edit session file" })
	end,
}
