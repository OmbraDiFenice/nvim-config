local key_mapping = require('basicIde.key_mapping')
local utils = require('basicIde.utils')
local OS = utils.files.OS

local function get_close_strategy(buf)
	local strategies = {
		purge = function() vim.api.nvim_buf_delete(buf, { unload = false }) end,
		force_purge = function() vim.api.nvim_buf_delete(buf, { unload = false, force = true }) end,
		close_window = function() for _, win in ipairs(vim.fn.win_findbuf(buf)) do vim.api.nvim_win_close(win, true) end end,
	}

	local strategy = strategies['purge'] -- default strategy

	local buf_close_strategy = utils.get_buf_var(buf, 'close_strategy')
	if buf_close_strategy ~= nil and strategies[buf_close_strategy] ~= nil then
		strategy = strategies[buf_close_strategy]
	end

	return strategy
end

---Close the current buffer completely (not just unload) and switch to the buffer immediately on the left.
---If there's no buffer available on the left switch to the one on the right.
---If there's no buffer to the right either falls back to an empty buffer.
---Closing a buffer completely is necessary to remove it from the list of the buffers in the tab line
---@return nil
local close_current_buffer = function()
	local bufs = vim.fn.getbufinfo()
	if bufs == nil then bufs = {} end
	local current_buffer = vim.api.nvim_win_get_buf(0)
	local current_buffer_idx = nil

	for i, buf_info in ipairs(bufs) do
		if buf_info.bufnr == current_buffer then
			current_buffer_idx = i
		end
	end

	if current_buffer_idx == nil then
		vim.api.nvim_err_writeln('unable to find current buffer index')
		return
	end

	local prev_buf = nil
	local next_buf = nil

	for i = current_buffer_idx - 1, 0, -1 do
		local buf = bufs[i]
		if buf ~= nil and buf.listed == 1 then
			prev_buf = buf.bufnr
			break
		end
	end

	for i = current_buffer_idx + 1, #bufs, 1 do
		local buf = bufs[i]
		if buf ~= nil and buf.listed == 1 then
			next_buf = buf.bufnr
			break
		end
	end

	local close_fn = get_close_strategy(current_buffer)
	close_fn()

	if prev_buf then
		vim.cmd('buffer ' .. prev_buf)
	else
		if next_buf then
			vim.cmd('buffer ' .. next_buf)
		end
	end
end

---Close all buffers and quits nvim.
---Handles special types of buffers needing close in a particular way via special variables set on them, normally when they're created
---@return nil
local function close_all()
	for _, tab_info in ipairs(vim.fn.gettabinfo()) do
		for variable, value in pairs(tab_info.variables or {}) do
			if variable == 'diffview_tab' and value == true then -- variable is set in git.lua, during diffview hook
				vim.cmd(':tabclose ' .. tab_info.tabnr)
			end
		end
	end
	vim.cmd [[ qall ]]
end

local keymap_descriptions = {
	show_line_diagnostic = 'open diagnostic floating window for current line',
	show_buffer_diagnostic = 'show diagnostics for current buffer',
	search_lsp_symbol = '[S]earch [S]symbol - highlight symbol under cursor with LSP',
	clear_lsp_symbol_highlight = 'clear search symbol LSP highlight',
	show_opened_buffers = 'show opened buffers',
	close_buffer = 'close buffer',
	quit_nvim = 'quit neovim',
	open_undo_tree = 'open undo tree view',
}

---@type KeymapManager
local keymap_manager = {
	keymap_callbacks = {
		show_line_diagnostic = { callback = vim.diagnostic.open_float, opts = {} },
		show_buffer_diagnostic = { callback = function() require('trouble').open('diagnostics_buffer') end, opts = {} },
		search_lsp_symbol = {
			callback = function()
				vim.lsp.buf.clear_references()
				vim.lsp.buf.document_highlight()
			end,
			opts = {},
		},
		clear_lsp_symbol_highlight = { callback = vim.lsp.buf.clear_references, opts = {} },
		show_opened_buffers = {
			callback = function()
				require('telescope.builtin').buffers({ sort_mru = true, sort_lastused = true })
			end,
			opts = {}
		},
		close_buffer = { callback = close_current_buffer, opts = { silent = true, noremap = true } },
		quit_nvim = { callback = close_all, opts = {} },
		open_undo_tree = { callback = require('undotree').open, opts = {} },
	}
}

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'Pocco81/auto-save.nvim',
		}

		use {
			'chentoast/marks.nvim',
		}

		use {
			'OmbraDiFenice/floating-input.nvim',
		}

		use {
			"jiaoshijie/undotree",
			requires = {
				"nvim-lua/plenary.nvim",
			},
		}

		use {
			"dstein64/vim-startuptime",
		}

		use {
			'MeanderingProgrammer/render-markdown.nvim',
			requires = { 'nvim-tree/nvim-web-devicons' },
		}
	end,

	configure = function(project_settings)
		-- mouse popup menu
		utils.popup_menu.setup()
		local is_url = utils.popup_menu.make_enable_callback("is_url", function()
			return vim.startswith(vim.fn.expand("<cWORD>"), "http")
		end)
		local in_tree_view = utils.popup_menu.make_enable_callback("in_tree_view", function()
			local filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
			return type(filetype) == 'string' and filetype == 'NvimTree'
		end)
		utils.popup_menu.make_entry("Open in browser", "gx", { icon = "󰖟", enabled_by = is_url, is_keymap = true, mode = "n" })
		utils.popup_menu.make_entry("Open in browser", "gx", { icon = "󰖟", enabled_by = is_url, is_keymap = true, mode = "v" })
		utils.popup_menu.make_entry("Treesitter inspect", "Inspect", { icon = "" })
		utils.popup_menu.make_entry("Open treesitter tree", "InspectTree", { icon = "" })
		utils.popup_menu.make_entry("New file/folder", "a", { icon = "", enabled_by = in_tree_view, is_keymap = true, mode = "n" })

		require('auto-save').setup({
			enabled = project_settings.editor.autosave,
			condition = function(buf)
				local autosave_utils = require("auto-save.utils.data")
				local ide_autosave_var = vim.fn.getbufvar(buf, 'nvim_ide_autosave')

				return vim.fn.getbufvar(buf, "&modifiable") == 1 and
						autosave_utils.not_in(vim.fn.getbufvar(buf, "&filetype"), {}) and
						(ide_autosave_var == nil or ide_autosave_var)
			end
		})

		-- opens help windows on the right, taken from https://vi.stackexchange.com/questions/4452/how-can-i-make-vim-open-help-in-a-vertical-split
		local vimrc_help_group = vim.api.nvim_create_augroup('vimrc_help', { clear = true })
		vim.api.nvim_create_autocmd({ 'BufEnter' }, {
			desc = 'Move opened help windows to the right',
			group = vimrc_help_group,
			pattern = '*.txt',
			callback = function(args)
				if vim.api.nvim_get_option_value('buftype', { buf = args.buf }) == 'help' then
					vim.cmd 'wincmd L'
				end
			end
		})

		-- Add autocomplete support for lua classes from basicIde.
		-- Useful while editing PROJECT_SETTINGS_FILE in other projects, however it will be added to the generic lua LSP server
		vim.filetype.add({
			filename = {
				[project_settings.PROJECT_SETTINGS_FILE] = function()
					return 'lua', function()
						local ide_folder = table.concat({vim.fn.stdpath('config'), 'lua'}, OS.sep)
						require('lspconfig').lua_ls.setup({
							settings = {
								Lua = {
									workspace = {
										library = { ide_folder },
									}
								}
							}
						})
					end
				end
			}
		})

		-- Disable diagnostics sign on the left side bar
		-- This avoids that the signs override the markers used to show which line was changed with git.
		-- The diagnostic is still tracked and displayed as virtual text anyway
		vim.diagnostic.config({
			signs = false,
		})

		key_mapping.setup_keymaps(keymap_descriptions, keymap_manager, project_settings.editor.keymaps)

		-- ------------------- MARKS -------------------
		require('marks').setup({
			--default_mappings = false,
			mappings = {
				annotate = "<leader>ma",
			},
			force_write_shada = true,
			excluded_buftype = {
				"gitcommit",
				"gitrebase",
				"toggleterm",
				"NvimTree",
			},
		})

		-- ------------------- UNDOTREE -------------------
		vim.o.undodir = utils.get_data_directory() .. OS.sep .. "undodir" .. OS.sep .. OS.sep
		vim.o.undofile = true
		vim.o.undolevels = 1000
		vim.o.undoreload = 10000

		local undotree = require("undotree")
		undotree.setup({
			float_diff = true,
		})

		-- ------------------- MARKDOWN -------------------
		require('render-markdown').setup({
			completions = {
				lsp = {
					enabled = true
				}
			}
		})

	end
}
