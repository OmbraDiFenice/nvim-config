local utils = require('basicIde.utils')

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'nvim-telescope/telescope.nvim',
			branch = '0.1.x',
			requires = { 'nvim-lua/plenary.nvim' }
		}

		use {
			'nvim-telescope/telescope-fzf-native.nvim',
			run = 'make',
			cond = vim.fn.executable 'make' == 1
		}

		use {
			'nvim-telescope/telescope-smart-history.nvim',
			requires = { "kkharji/sqlite.lua" }, -- also requires to have sqlite3 binary installed on the system
		}
	end,

	configure = function()
		-- See `:help telescope` and `:help telescope.setup()`
		local telescope = require('telescope')
		local telescope_actions = require('telescope.actions')

		telescope.setup {
			defaults = {
				wrap_results = true,
				path_display = { "tail" },
				cache_picker = {
					num_pickers = 5,
				},
				history = {
					path = Get_data_directory() .. '/telescope_history.sqlite3',
					limit = 100,
				},
				mappings = {
					i = {
						['<C-u>'] = false,
						['<C-d>'] = false,
						['<C-j>'] = telescope_actions.cycle_history_next,
						['<C-k>'] = telescope_actions.cycle_history_prev,
					},
				},
			},
		}
		telescope.load_extension('smart_history')

		-- Enable telescope fzf native, if installed
		pcall(require('telescope').load_extension, 'fzf')

		-- See `:help telescope.builtin`
		local telescope_builtin = require('telescope.builtin')

		vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles, { desc = '[?] Find recently opened files' })
		vim.keymap.set('n', '<leader><space>', telescope_builtin.buffers, { desc = '[ ] Find existing buffers' })
		vim.keymap.set('n', '<leader>/', function()
			-- You can pass additional configuration to telescope to change theme, layout, etc.
			telescope_builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
				winblend = 10,
				previewer = false,
			})
		end, { desc = '[/] Fuzzily search in current buffer]' })

		vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, { desc = '[S]earch [F]iles' })
		vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = '[S]earch [H]elp' })
		vim.keymap.set('n', '<leader>sw', telescope_builtin.grep_string, { desc = '[S]earch current [W]ord' })
		vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep, { desc = '[S]earch by [G]rep' })
		vim.keymap.set('v', '<leader>sg', function () telescope_builtin.live_grep({ default_text = utils.get_visual_selection() }) end, { desc = '[S]earch by [G]rep' })
		vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
		vim.keymap.set('n', '<leader>sk', telescope_builtin.keymaps, { desc = '[S]earch [K]keymaps' })

		-- LSP searches
		vim.keymap.set('n', '<leader>su', telescope_builtin.lsp_references, { desc = '[S]earch [U]sage' })
		-- vim.keymap.set('n', '<leader>ds', telescope_builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols' })
		-- vim.keymap.set('n', '<leader>ws', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols' })
	end,
}
