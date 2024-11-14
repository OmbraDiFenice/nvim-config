local utils = require('basicIde.utils')

local function build_search_in_scope_prompt_title(default_prompt_title)
	local neoscopes = require('neoscopes')
	local prompt_title = default_prompt_title
	local current_scope = neoscopes.get_current_scope()
	if current_scope then
		prompt_title = prompt_title .. ' in ' .. current_scope.name .. ' scope'
	end

	return prompt_title
end

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

		use {
			'OmbraDiFenice/neoscopes-telescope',
			requires = {
				'nvim-telescope/telescope.nvim',
				'smartpde/neoscopes',
			}
		}
	end,

	configure = function(project_settings)
		-- See `:help telescope` and `:help telescope.setup()`
		local telescope = require('telescope')
		local telescope_actions = require('telescope.actions')
		local telescope_actions_generate = require('telescope.actions.generate')

		telescope.setup {
			defaults = {
				wrap_results = true,
				path_display = { "smart" },
				cache_picker = {
					num_pickers = 5,
				},
				history = {
					path = table.concat({project_settings.DATA_DIRECTORY , 'telescope_history.sqlite3'}, utils.files.OS.sep),
					limit = 100,
				},
				mappings = {
					i = {
						['<C-u>'] = false,
						['<C-d>'] = false,
						['<C-j>'] = telescope_actions.cycle_history_next,
						['<C-k>'] = telescope_actions.cycle_history_prev,
					},
					n = {
						['?'] = telescope_actions_generate.which_key({}),
					}
				},
			},
		}
		telescope.load_extension('smart_history')

		-- Enable telescope fzf native, if installed
		pcall(require('telescope').load_extension, 'fzf')

		-- Enable neoscopes-telescope
		local neoscopes_config_filename = project_settings.DATA_DIRECTORY.. utils.files.OS.sep .. "neoscopes.confg.json"
		if not utils.files.path_exists(neoscopes_config_filename, false) then
			utils.files.touch_file(neoscopes_config_filename)
			vim.fn.writefile({ "{}" }, neoscopes_config_filename)
		end
		local neoscopes_telescope = require('neoscopes-telescope')
		neoscopes_telescope.setup({ -- must be done before configuring neoscopes so we can load the last used scope
			scopes = {
				persist_file = neoscopes_config_filename,
			}
		})
		require('neoscopes').setup({
			neoscopes_config_filename = neoscopes_config_filename,
			current_scope = neoscopes_telescope.get_last_scope(),
		})

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

		local search_files_options = {
			hidden = false,
			no_ignore = false,
			no_ignore_parent = false,
		}
		vim.keymap.set('n', '<leader>sf', function()
			neoscopes_telescope.file_search({
				use_last_scope = true,
				remember_last_scope_used = true,
				dynamic_prompt_title = function() return build_search_in_scope_prompt_title('Find Files') end,
				telescope_options = search_files_options,
			})
		end, { desc = '[S]earch [F]iles' })

		vim.keymap.set('n', '<leader>sF', function()
			neoscopes_telescope.file_search({
				use_last_scope = false,
				remember_last_scope_used = true,
				dynamic_prompt_title = function() return build_search_in_scope_prompt_title('Find Files') end,
				telescope_options = search_files_options,
			})
		end, { desc = '[S]earch [F]iles (explicitly select scope)' })

		vim.keymap.set('n', '<leader>sg', function()
			neoscopes_telescope.grep_search({
				use_last_scope = true,
				remember_last_scope_used = true,
				dynamic_prompt_title = function() return build_search_in_scope_prompt_title('Live Grep') end,
				telescope_options = search_files_options,
			})
		end, { desc = '[S]earch by [G]rep' })

		vim.keymap.set('v', '<leader>sg', function()
			neoscopes_telescope.grep_search({
				use_last_scope = true,
				remember_last_scope_used = true,
				dynamic_prompt_title = function() return build_search_in_scope_prompt_title('Live Grep') end,
				telescope_options = vim.tbl_deep_extend('force', search_files_options, {
					initial_mode = 'normal',
					default_text = utils.get_visual_selection(),
				}),
			})
		end, { desc = '[S]earch selection by [G]rep' })

		vim.keymap.set('n', '<leader>Ss', neoscopes_telescope.select_scope, { desc = '[S]cope [s]elect' })
		vim.keymap.set('n', '<leader>Sc', neoscopes_telescope.new_scope, { desc = '[S]cope [c]reate' })
		vim.keymap.set('n', '<leader>Sd', neoscopes_telescope.delete_scope, { desc = '[S]cope [d]elete' })
		vim.keymap.set('n', '<leader>SC', neoscopes_telescope.clone_scope, { desc = '[S]cope [C]lone' })

		vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = '[S]earch [H]elp' })
		vim.keymap.set('n', '<leader>sw', telescope_builtin.grep_string, { desc = '[S]earch current [W]ord' })
		vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
		vim.keymap.set('n', '<leader>sk', telescope_builtin.keymaps, { desc = '[S]earch [K]keymaps' })

		-- LSP searches
		vim.keymap.set('n', '<leader>su', telescope_builtin.lsp_references, { desc = '[S]earch [U]sage' })
		-- vim.keymap.set('n', '<leader>ds', telescope_builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols' })
		-- vim.keymap.set('n', '<leader>ws', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols' })
	end,
}
