local utils = require('basicIde.utils')

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'nvim-treesitter/nvim-treesitter',
			run = function()
				pcall(require('nvim-treesitter.install').update { with_sync = true })
			end,
		}

		use {
			'nvim-treesitter/nvim-treesitter-textobjects',
			after = 'nvim-treesitter',
		}

		use { 'luukvbaal/statuscol.nvim' }
	end,

	configure = function(project_settings)
		require('nvim-treesitter.configs').setup {
			ensure_installed = vim.tbl_deep_extend('keep', project_settings.project_languages, utils.treesitter.default_languages),
			highlight = {
				enable = true,
				disable = project_settings.performance.disable_treesitter_highlight,
			},
			ignore_install = {
				"groovy", -- groovy query.lua is broken
				"ipkg", -- broken
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = '<c-space>',
					node_incremental = '<c-space>',
					scope_incremental = '<c-s>',
					node_decremental = '<c-backspace>',
				},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					keymaps = {
						-- You can use the capture groups defined in textobjects.scm
						['aa'] = '@parameter.outer',
						['ia'] = '@parameter.inner',
						['af'] = '@function.outer',
						['if'] = '@function.inner',
						['ac'] = '@class.outer',
						['ic'] = '@class.inner',
					},
				},
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						[']m'] = '@function.outer',
						[']]'] = '@class.outer',
					},
					goto_next_end = {
						[']M'] = '@function.outer',
						[']['] = '@class.outer',
					},
					goto_previous_start = {
						['[m'] = '@function.outer',
						['[['] = '@class.outer',
					},
					goto_previous_end = {
						['[M'] = '@function.outer',
						['[]'] = '@class.outer',
					},
				},
			}
		}

		vim.opt.foldmethod = 'expr'
		vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
		vim.opt.foldenable = true
		vim.opt.foldlevelstart = 99
		vim.opt.foldcolumn = '1'
		vim.opt.fillchars = 'foldopen:,foldclose:'

		vim.api.nvim_create_autocmd('User', {
			pattern = 'ProjectSettingsChanged',
			desc = 'install TreeSitter parser for new project languages',
			callback = function()
				utils.treesitter.ensure_installed(project_settings.project_languages)
			end,
		})

		-- status column

		local statuscol_builtin = require('statuscol.builtin')
		require('statuscol').setup({
			bt_ignore = { 'terminal' },
			segments = {
				--{ text = { "%C" }, click = "v:lua.ScFa" },
				{ text = { "%s" }, click = "v:lua.ScSa" },
				{
					text = { statuscol_builtin.lnumfunc, " " },
					condition = { true, statuscol_builtin.not_empty },
					click = "v:lua.ScLa",
				},
				{
					text = { " ", statuscol_builtin.foldfunc, " " },
					condition = { statuscol_builtin.not_empty, true, statuscol_builtin.not_empty },
					click = "v:lua.ScFa"
				},
			},
		})
	end,
}
