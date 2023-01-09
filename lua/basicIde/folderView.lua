local function collapse_all()
	require("nvim-tree.actions.tree-modifiers.collapse-all").fn()
end

local function edit_or_open()
	-- open as vsplit on current node
	local lib = require("nvim-tree.lib")
	local view = require("nvim-tree.view")
	local action = "edit"
	local node = lib.get_node_at_cursor()

	if not node then return end

	-- Just copy what's done normally with vsplit
	if node.link_to and not node.nodes then
		require('nvim-tree.actions.node.open-file').fn(action, node.link_to)
		view.close() -- Close the tree if file was opened

	elseif node.nodes ~= nil then
		lib.expand_or_collapse(node)

	else
		require('nvim-tree.actions.node.open-file').fn(action, node.absolute_path)
		view.close() -- Close the tree if file was opened
	end

end

local function vsplit_preview()
	-- open as vsplit on current node
	local lib = require("nvim-tree.lib")
	local view = require("nvim-tree.view")
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

return {
	use_deps = function(use)
		use {
			'nvim-tree/nvim-tree.lua',
			requires = {
				'nvim-tree/nvim-web-devicons',
			},
			tag = 'nightly' -- optional, updated every week. (see issue #1193)
		}
	end,

	configure = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		vim.opt.termguicolors = true

		vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeToggle<cr>", { silent = true, noremap = true })
		local config = {
			view = {
				mappings = {
					custom_only = false,
					list = {
						{ key = "l", action = "edit", action_cb = edit_or_open },
						{ key = "L", action = "vsplit_preview", action_cb = vsplit_preview },
						{ key = "h", action = "close_node" },
						{ key = "H", action = "collapse_all", action_cb = collapse_all }
					}
				},
			},
			actions = {
				open_file = {
					quit_on_open = false
				}
			},
			renderer = {
				group_empty = false,
			},
		}

		require("nvim-tree").setup(config)
	end,
}
