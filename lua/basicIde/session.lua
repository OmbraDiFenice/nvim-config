local utils = require('basicIde.utils')

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
---@param data_directory string
local function edit_session_file(data_directory)
	local auto_session_lib = require('auto-session.lib')
	local pickers = require('telescope.pickers')
	local finders = require('telescope.finders')
	local conf = require('telescope.config').values
	local themes = require('telescope.themes')

	local files_to_return = {
		'neoscopes.config.json',
		'nvim-tree.state',
	}
	local session_files = vim.fn.readdir(data_directory, function(item)
		local file_path = utils.paths.ensure_trailing_slash(data_directory) .. item
		return not utils.files.is_dir(file_path) and (utils.tables.is_in_list(item, files_to_return) or auto_session_lib.is_session_file(item))
	end)

	session_files = vim.tbl_map(function(file)
		return {
			display_name = file,
			path = utils.paths.ensure_trailing_slash(data_directory) .. file,
		}
	end, session_files)

	local function get_display_name(session_entry)
		if session_entry.display_name ~= nil then return session_entry.display_name end
		return session_entry.path
	end

	local opts = themes.get_dropdown({})
	pickers.new(opts, {
			initial_mode = 'normal',
			finder = finders.new_table {
				results = session_files,
				entry_maker = function (entry)
					return {
						value = entry,
						display = function(tbl) return get_display_name(tbl.value) end,
						ordinal = entry.path,
						path = entry.path,
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

		if settings.editor.tree_view.open_on_start then
			table.insert(pre_save_cmds, close_nvim_tree)
			table.insert(post_restore_cmds, open_nvim_tree)
		end

		require('auto-session').setup {
			log_level = "error",
			auto_session_root_dir = settings.DATA_DIRECTORY,
			auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			auto_session_use_git_branch = false, -- bug in auto-session: this causes the *entire* path to be escaped at some point
																					 -- which results in the session file being placed in a folder other than the auto_session_root_dir

			-- can't be done in nvim-tree, see https://github.com/nvim-tree/nvim-tree.lua/issues/1992#issuecomment-1455504628
			pre_save_cmds = pre_save_cmds,
			post_restore_cmds = post_restore_cmds,
		}

		vim.o.sessionoptions = "blank,buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"

		vim.keymap.set('n', '<leader>es', function() edit_session_file(settings.DATA_DIRECTORY) end, { desc = "edit session file" })
	end,
}
