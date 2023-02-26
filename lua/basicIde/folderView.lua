local lib = require("nvim-tree.lib")
local view = require("nvim-tree.view")
local api = require("nvim-tree.api")

local function collapse_all()
	require("nvim-tree.actions.tree-modifiers.collapse-all").fn()
end

local function edit_or_open()
	-- open as vsplit on current node
	local action = "edit"
	local node = lib.get_node_at_cursor()

	if not node then return end

	-- Just copy what's done normally with vsplit
	if node.link_to and not node.nodes then
		require('nvim-tree.actions.node.open-file').fn(action, node.link_to)

	elseif node.nodes ~= nil then
		lib.expand_or_collapse(node)

	else
		require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
	end

end

local function vsplit_preview()
	-- open as vsplit on current node
	local action = "vsplit"
	local node = lib.get_node_at_cursor()

	if not node then return end

	-- Just copy what's done normally with vsplit
	if node.link_to and not node.nodes then
		require('nvim-tree.actions.node.open-file').fn(action, node.link_to)

	elseif node.nodes ~= nil then
		lib.expand_or_collapse(node)

	else
		require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)

	end

	-- Finally refocus on tree if it was lost
	view.focus()
end

local git_add = function()
  local node = lib.get_node_at_cursor()

	if not node then return end

  local gs = node.git_status.file

  -- If the file is untracked, unstaged or partially staged, we stage it
  if gs == "??" or gs == "MM" or gs == "AM" or gs == " M" then
    vim.cmd("silent !git add " .. node.absolute_path)

  -- If the file is staged, we unstage
  elseif gs == "M " or gs == "A " then
    vim.cmd("silent !git restore --staged " .. node.absolute_path)
  end

  lib.refresh_tree()
end

local close_current_buffer = function()
	local bufs = vim.fn.getbufinfo({ buflisted = true })
	local current_buffer = vim.api.nvim_win_get_buf(0)
	local current_buffer_idx = nil

	for i, buf_info in ipairs(bufs) do
		if buf_info.bufnr == current_buffer then
			current_buffer_idx = i
		end
	end

	if current_buffer_idx == nil then
		vim.api.nvim_err_writeln('unable to find current buffer index. Maybe it is not listed?')
		return
	end

	local prev = bufs[current_buffer_idx-1] ~= nil and bufs[current_buffer_idx-1].bufnr
	local next = bufs[current_buffer_idx+1] ~= nil and bufs[current_buffer_idx+1].bufnr

	vim.api.nvim_buf_delete(current_buffer, { unload = false })
	if prev then
		vim.cmd('buffer '..prev)
	else
		if next then
			vim.cmd('buffer '..next)
		end
	end
end

local key_mapping = {
	{ key = "l", action = "edit", action_cb = edit_or_open },
	{ key = "L", action = "vsplit_preview", action_cb = vsplit_preview },
	{ key = "h", action = "close_node" },
	{ key = "H", action = "collapse_all", action_cb = collapse_all },
	{ key = "ga", action = "git_add", action_cb = git_add },
}

return {
	use_deps = function(use)
		use {
			'nvim-tree/nvim-tree.lua',
			requires = {
				'nvim-tree/nvim-web-devicons',
			},
			tag = 'nightly' -- optional, updated every week. (see issue #1193)
		}

		-- "tab" (buffer) bar
		use {'akinsho/bufferline.nvim', tag = "v3.*", requires = 'nvim-tree/nvim-web-devicons'}
	end,

	configure = function()

		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		vim.opt.termguicolors = true

		vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeFocus<cr>", { silent = true, noremap = true, desc = "focus tree view" })
		vim.api.nvim_set_keymap("n", "<C-u>", ":bp<cr>", { silent = true, noremap = true, desc = "previous buffer" })
		vim.api.nvim_set_keymap("n", "<C-o>", ":bn<cr>", { silent = true, noremap = true, desc = "next buffer" })
		vim.keymap.set("n", "<leader><C-w>", close_current_buffer, { silent = true, noremap = true, desc = "close buffer" })
		vim.api.nvim_set_keymap("n", "<leader>f", ":NvimTreeFindFile<CR>", { silent = true, noremap = true, desc = "find current buffer in tree view" })

		local config = {
			view = {
				width = "20%",
				mappings = {
					custom_only = false,
					list = key_mapping,
				},
			},
			actions = {
				open_file = {
					quit_on_open = false
				}
			},
			renderer = {
				group_empty = false,
				indent_markers = {
					enable = true,
				},
				highlight_git = true,
				icons = {
					show = {
						git = false,
					},
				},
			},
			filters = {
				custom = {
					"\\.git",
				},
			},
		}

		require("nvim-tree").setup(config)

		--

		require("bufferline").setup({
			options = {
				numbers = "buffer_id",
				right_mouse_command = "",
				middle_mouse_command = "bdelete! %d",
				show_buffer_icons = false,
				show_buffer_default_icon = false,
				show_close_icon = false,
				show_duplicate_prefix = true,
				always_show_bufferline = true,
				sort_by = "id",
			},
		})
	end,
}
