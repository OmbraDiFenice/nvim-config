local function get_close_strategy(buf)
	local strategies = {
		purge = function() vim.api.nvim_buf_delete(buf, { unload = false }) end,
		force_purge = function() vim.api.nvim_buf_delete(buf, { unload = false, force = true }) end,
		close_window = function() for _, win in ipairs(vim.fn.win_findbuf(buf)) do vim.api.nvim_win_close(win, true) end end,
	}

	local strategy = strategies['purge'] -- default strategy

	local buf_close_strategy = Get_buf_var(buf, 'close_strategy')
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

local function setup_diagnostics_keybindings()
	vim.api.nvim_set_keymap('n', '<leader>d?', '', {
		callback = vim.diagnostic.open_float,
		desc = 'open diagnostic floating window for current line',
	})

	vim.api.nvim_set_keymap('n', '<C-l>', '', {
		callback = function()
			require('telescope.builtin').diagnostics()
		end,
		desc = 'show diagnostics for all loaded buffers',
	})
end

local function setup_highlight_identifier_keybindings()
	vim.api.nvim_set_keymap('n', '<leader>ss', '', {
	  callback = function()
			vim.lsp.buf.clear_references()
			vim.lsp.buf.document_highlight()
		end,
	  desc = '[S]earch [S]symbol - highlight symbol under cursor with LSP',
	})
	vim.api.nvim_set_keymap('n', '<leader>sS', '', {
		callback = vim.lsp.buf.clear_references,
	  desc = 'clear search symbol LSP highlight',
	})
end

local function setup_navigation_keybindings()
	vim.api.nvim_set_keymap('n', '<leader>b', '', {
		callback = function()
			require('telescope.builtin').buffers({ sort_mru = true, sort_lastused = true })
		end,
		desc = 'show opened buffers',
	})

	vim.api.nvim_set_keymap('n', '<leader>u', '', {
		callback = function()
			require('telescope.builtin').oldfiles()
		end,
		desc = 'show/reopen recent buffers',
	})
end

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
	end,

	configure = function(project_settings)
		require('auto-save').setup({
			enabled = project_settings.editor.autosave,
			condition = function(buf)
				local utils = require("auto-save.utils.data")
				local ide_autosave_var = vim.fn.getbufvar(buf, 'nvim_ide_autosave')

				return vim.fn.getbufvar(buf, "&modifiable") == 1 and
						utils.not_in(vim.fn.getbufvar(buf, "&filetype"), {}) and
						(ide_autosave_var == nil or ide_autosave_var)
			end
		})

		vim.keymap.set("n", "<leader>q", close_current_buffer, { silent = true, noremap = true, desc = "close buffer" })
		vim.keymap.set('n', '<leader>Q', close_all, { desc = 'close all windows' })

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

		setup_diagnostics_keybindings()
		setup_navigation_keybindings()

		setup_highlight_identifier_keybindings()

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
	end
}
