local function edit_or_open()
	local lib = require("nvim-tree.lib")
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
	local lib = require("nvim-tree.lib")
	local view = require("nvim-tree.view")
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
	local lib = require("nvim-tree.lib")
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
	local api = require("nvim-tree.api")
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

	if prev then
		vim.cmd('buffer '..prev)
	else
		if next then
			vim.cmd('buffer '..next)
		end
	end
	vim.api.nvim_buf_delete(current_buffer, { unload = false })
end

local nvim_tree_key_mappings = function(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

	api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set('n', 'l', edit_or_open, opts('Open'))
  vim.keymap.set('n', 'L', vsplit_preview, opts('vsplit_preview'))
  vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts('Close Directory'))
  vim.keymap.set('n', 'H', api.tree.collapse_all, opts('Collapse'))
  vim.keymap.set('n', 'ga', git_add, opts('git_add'))
end

return {
	use_deps = function(use)
		use {
			'nvim-tree/nvim-tree.lua',
			requires = {
				'nvim-tree/nvim-web-devicons',
			},
			tag = 'master'
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
		vim.keymap.set("n", "<leader>q", close_current_buffer, { silent = true, noremap = true, desc = "close buffer" })
		vim.api.nvim_set_keymap("n", "<leader>f", ":NvimTreeFindFile<CR>", { silent = true, noremap = true, desc = "find current buffer in tree view" })

		local config = {
			view = {
				width = "20%",
			},
			on_attach = nvim_tree_key_mappings,
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
		require("basicIde/folderViewExtensions/treeState").setup()

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
