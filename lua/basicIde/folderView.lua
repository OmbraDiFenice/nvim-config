local key_mapping = require('basicIde.key_mapping')
local utils = require('basicIde.utils')

local git_add = function()
	local api = require("nvim-tree.api")
	local core = require("nvim-tree.core")
	local explorer = core.get_explorer()
	assert(explorer ~= nil, "No explorer found")

	local node = explorer:get_node_at_cursor()

	if not node then return end

	local gs = node.git_status.file

	-- If the file is untracked, unstaged or partially staged, we stage it
	if gs == "??" or gs == "MM" or gs == "AM" or gs == " M" then
		vim.cmd("silent !git add " .. node.absolute_path)

		-- If the file is staged, we unstage
	elseif gs == "M " or gs == "A " then
		vim.cmd("silent !git restore --staged " .. node.absolute_path)
	end

	api.tree.reload()
end

local synchronize_file_or_dir_remotely = function()
	local core = require("nvim-tree.core")
	local explorer = core.get_explorer()
	assert(explorer ~= nil, "No explorer found")

	local node = explorer:get_node_at_cursor()
	if node == nil then return end

	local cmd = "SyncFile"
	local path = node.absolute_path
	if node.type == "directory" or node.name == '..' then
		cmd = "SyncDir"
	end
	if node.name == '..' then
		path = core.get_cwd()
	end

	vim.api.nvim_exec_autocmds('User', {
		group = 'BasicIde.RemoteSync',
		pattern = cmd,
		data = {
			path = path,
		},
	})
end

local nvim_tree_keymap_descriptions = {
	open = 'nvim-tree: Open',
	close_tree_view = 'nvim-tree: Close tree view',
	vsplit_preview = 'nvim-tree: vsplit preview',
	close_dir = 'nvim-tree: Close Directory',
	collapse = 'nvim-tree: Collapse all',
	git_add = 'nvim-tree: git add',
	synchronize_file_or_dir_remotely = 'nvim-tree: synchronize file or dir on remote',
	search_in_marked_locations = 'nvim-tree: search in marked locations',
	grep_in_marked_locations = 'nvim-tree: grep in marked locations',
}

---@return KeymapManager
local function make_nvim_tree_keymap_manager(bufnr)
	local api = require('nvim-tree.api')
	local common_opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }

	return {
		keymap_callbacks = {
			open = { callback = api.node.open.edit, opts = common_opts },
			close_tree_view = { callback = api.tree.close, opts = common_opts },
			vsplit_preview = { callback = api.node.open.vertical, opts = common_opts },
			close_dir = { callback = api.node.navigate.parent_close, opts = common_opts },
			collapse = { callback = api.tree.collapse_all, opts = common_opts },
			git_add = { callback = git_add, opts = common_opts },
			synchronize_file_or_dir_remotely = { callback = synchronize_file_or_dir_remotely, opts = common_opts },
			search_in_marked_locations = {
				callback = function()
					require('telescope.builtin').find_files({
						search_dirs = utils.tables.map(api.marks:list(), function(node) return node.absolute_path end),
					})
				end,
				opts = common_opts
			},
			grep_in_marked_locations = {
				callback = function()
					require('telescope.builtin').live_grep({
						search_dirs = utils.tables.map(api.marks:list(), function(node) return node.absolute_path end),
					})
				end,
				opts = common_opts
			},
		}
	}
end

---Sets the nvim-tree keybindings on the nvim-tree buffer
---@param bufnr integer nvim-tree bufnr
---@param editor_config EditorConfig
local nvim_tree_key_mappings = function(bufnr, editor_config)
	local api = require('nvim-tree.api')

	api.config.mappings.default_on_attach(bufnr)

	local nvim_tree_keymap_manager = make_nvim_tree_keymap_manager(bufnr)
	key_mapping.setup_keymaps(nvim_tree_keymap_descriptions, nvim_tree_keymap_manager, editor_config.tree_view.keymaps)
end

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'nvim-tree/nvim-tree.lua',
			requires = {
				'nvim-tree/nvim-web-devicons',
			},
			branch = 'master'
		}

		use {
			'antosha417/nvim-lsp-file-operations',
			requires = {
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-tree.lua",
			}
		}

		-- "tab" (buffer) bar
		use { 'akinsho/bufferline.nvim', tag = "v3.*", requires = 'nvim-tree/nvim-web-devicons' }
	end,

	configure = function(project_settings)
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		vim.opt.termguicolors = true

		vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeFocus<cr>",
			{ silent = true, noremap = true, desc = "focus tree view" })
		vim.api.nvim_set_keymap("n", "<C-u>", ":bp<cr>", { silent = true, noremap = true, desc = "previous buffer" })
		vim.api.nvim_set_keymap("n", "<C-o>", ":bn<cr>", { silent = true, noremap = true, desc = "next buffer" })

		if project_settings.editor.recenter_viewport.enabled then
			local ignore_filetypes = utils.tables.deepcopy(project_settings.editor.recenter_viewport.ignore_filetypes)
			table.insert(ignore_filetypes, 'NvimTree') -- NvimTree already restores the cursor where it was by itself
			vim.api.nvim_create_autocmd({"BufLeave", "CursorMoved", "CursorMovedI"}, {
				callback = function(ev)
					local filetype = vim.api.nvim_get_option_value('filetype', { buf = ev.bufnr })
					if utils.tables.is_in_list(filetype, ignore_filetypes) then return end

					if vim.fn.exists('b:BasicIdeWinState') == 0 then
						vim.api.nvim_buf_set_var(0, 'BasicIdeWinState', vim.json.encode({}))
					end
					local win_state = vim.json.decode(vim.api.nvim_buf_get_var(0, 'BasicIdeWinState'))
					local current_win = tostring(vim.api.nvim_get_current_win())
					win_state[current_win] = vim.fn.winsaveview()
					vim.api.nvim_buf_set_var(0, 'BasicIdeWinState', vim.json.encode(win_state))
				end
			})

			vim.api.nvim_create_autocmd({"BufEnter"}, {
				callback = function()
					if vim.fn.exists('b:BasicIdeWinState') == 0 then return end
					local win_state = vim.json.decode(vim.api.nvim_buf_get_var(0, 'BasicIdeWinState'))
					local current_win = tostring(vim.api.nvim_get_current_win())
					local state = win_state[current_win]
					if state ~= nil then
						vim.fn.winrestview(state)
					end
				end
			})
		end

		vim.api.nvim_set_keymap("n", "<leader>f", ":NvimTreeFindFile<CR>",
			{ silent = true, noremap = true, desc = "find current buffer in tree view" })

		local config = {
			view = {
				width = "20%",
			},
			on_attach = function(bufnr) nvim_tree_key_mappings(bufnr, project_settings.editor) end,
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
					"^\\.git$",
				},
			},
		}

		require("nvim-tree").setup(config)
		require("basicIde/folderViewExtensions/treeState").setup()

		require("lsp-file-operations").setup()

		--

		require("bufferline").setup({
			options = {
				numbers = "buffer_id",
				right_mouse_command = "",
				middle_mouse_command = "bdelete! %d",
				show_buffer_icons = false,
				get_element_icon = nil,
				show_close_icon = false,
				show_duplicate_prefix = true,
				always_show_bufferline = true,
				sort_by = "id",
			},
		})
	end,
}
