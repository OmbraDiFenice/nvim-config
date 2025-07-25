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

---@param elements string[]
---@return boolean success
---@return integer start row
---@return integer end row
local function get_range_of_first_enclosing(elements)
	local success, last_node = pcall(vim.treesitter.get_node)
	if not success or last_node == nil then
		vim.notify('unable to find current treesitter node', vim.log.levels.WARN)
		return false, -1, -1
	end
	local tree_root = last_node:tree():root()

	while last_node ~= nil and not last_node:equal(tree_root) do
		local node_type = last_node:type()
		if utils.tables.is_in_list(node_type, elements) then break end
		last_node = last_node:parent()
	end

	if last_node == nil then
		vim.notify('unable to find range treesitter node', vim.log.levels.WARN)
		return false, -1, -1
	end

	local start_row, _, end_row, _ = vim.treesitter.get_node_range(last_node)
	return true, start_row, end_row
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

		use {
			'folke/trouble.nvim'
		}
	end,

	configure = function(project_settings)
		-- Trouble settings (requires LSP)

		local trouble_highlights = require('trouble.config.highlights')
		trouble_highlights.colors.Count = "MiniTabLineModifiedVisible" -- tweak colors. The string is the name of another highlight group to link that element to

		local trouble = require("trouble")
		trouble.setup({
			preview = {
				type = "split",
				relative = "win",
				position = "right",
				size = 0.6,
				-- bo = { buf options },
				-- wo = { win options },
				on_mount = function(win_obj)
					vim.api.nvim_create_autocmd("WinResized", {
						group = win_obj:augroup(),
						callback = function()
							local event = vim.v.event
							for _, win in ipairs(event.windows) do
								if win == win_obj.win then
									win_obj.opts.size = vim.api.nvim_win_get_width(win_obj.win)
								end
							end
						end,
						desc = "Remember the preview width if it was changed by dragging the border",
					})
				end,
			},
			modes = {
				diagnostics_buffer = {
					mode = "diagnostics", -- inherit from diagnostics mode
					filter = { buf = 0 }, -- filter diagnostics to the current buffer
				},
				telescope_by_dir = {
					mode = "telescope",
					focus = true,
					groups ={
						{ "directory", format = "{directory_icon} {filename} {count}" },
						{ "filename", format = "{file_icon} {filename} {count}" },
					},
				},
			},
		})

		-- Telescope

		local telescope = require('telescope')
		local telescope_actions = require('telescope.actions')
		local telescope_actions_generate = require('telescope.actions.generate')

		local open_with_trouble = function(prompt_bufnr) require("trouble.sources.telescope").open(prompt_bufnr, "telescope_by_dir") end
		local add_to_trouble = function(prompt_bufnr) require("trouble.sources.telescope").add(prompt_bufnr, "telescope_by_dir") end

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
						["<C-t>"] = open_with_trouble,
						["<C-T>"] = add_to_trouble,
					},
					n = {
						['?'] = telescope_actions_generate.which_key({}),
						['g?'] = telescope_actions_generate.which_key({}),
						["<C-t>"] = open_with_trouble,
						["<C-T>"] = add_to_trouble,
					}
				},
			},
		}
		telescope.load_extension('smart_history')

		-- Enable telescope fzf native, if installed
		pcall(require('telescope').load_extension, 'fzf')

		-- Enable neoscopes-telescope
		local neoscopes_config_filename = project_settings.DATA_DIRECTORY.. utils.files.OS.sep .. "neoscopes.config.json"
		if not utils.files.path_exists(neoscopes_config_filename, false) then
			utils.files.touch_file(neoscopes_config_filename)
			vim.fn.writefile({ '{"last_scope":"default","scopes":[{"name":"default","dirs":["' .. project_settings.PROJECT_ROOT_DIRECTORY .. '"],"files":[]}]}' }, neoscopes_config_filename)
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

		vim.keymap.set('n', '<leader>sim', function()
			local success, start_row, end_row = get_range_of_first_enclosing({ 'function_definition' })
			if not success then return end
			vim.api.nvim_feedkeys('/\\%>' .. start_row .. 'l\\%<' .. end_row .. 'l', 'n', true)
		end, { desc = 'search within current function/method' })

		vim.keymap.set('n', '<leader>sic', function()
			local success, start_row, end_row = get_range_of_first_enclosing({ 'class_definition' })
			if not success then return end
			vim.api.nvim_feedkeys('/\\%>' .. start_row .. 'l\\%<' .. end_row .. 'l', 'n', true)
		end, { desc = 'search within current class' })

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
		vim.keymap.set('n', '<leader>sm', function() telescope_builtin.marks({ initial_mode = 'normal' }) end, { desc = '[S]search [M]arkers' })

		-- LSP searches
		vim.keymap.set('n', '<leader>su', telescope_builtin.lsp_references, { desc = '[S]earch [U]sage' })
		-- vim.keymap.set('n', '<leader>ds', telescope_builtin.lsp_document_symbols, { desc = '[D]ocument [S]ymbols' })
		-- vim.keymap.set('n', '<leader>ws', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols' })

		-- Highlight search without jumping
		vim.keymap.set('n', '<leader>*', function()
			local word = vim.fn.expand('<cword>')
			vim.cmd('let @/="' .. word .. '"')
			vim.api.nvim_set_vvar('hlsearch', 1)
		end, { desc = 'Search-highlight word under cursor without moving the cursor' })

		vim.keymap.set('v', '<leader>*', function()
			local word = utils.get_visual_selection()
			vim.cmd('let @/="' .. word .. '"')
			vim.api.nvim_set_vvar('hlsearch', 1)
		end, { desc = 'Search-highlight selected text without moving the cursor' })

		-- notify when search wraps around. With the notification popup plugin this is more visible than just a message in the command line
		local search_wrapped_notif = nil
		vim.api.nvim_create_autocmd('SearchWrapped', {
			callback = function()
				search_wrapped_notif = vim.notify('Search wrapped', vim.log.levels.INFO, {
					replace = search_wrapped_notif,
					on_close = function() search_wrapped_notif = nil end
				})
			end,
		})
	end,
}
