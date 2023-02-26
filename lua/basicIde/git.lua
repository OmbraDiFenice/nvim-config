return {
	use_deps = function(use)
		use {
			'tpope/vim-fugitive',
		}
		use {
			'lewis6991/gitsigns.nvim',
		}
	end,

	configure = function()
		require('gitsigns').setup {
		 on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					opts.silent = true
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then return ']c' end
					vim.schedule(function() gs.next_hunk() end)
					return '<Ignore>'
				end, {expr=true})

				map('n', '[c', function()
					if vim.wo.diff then return '[c' end
					vim.schedule(function() gs.prev_hunk() end)
					return '<Ignore>'
				end, {expr=true})

				-- Actions
				map({'n', 'v'}, '<leader>hs', ':Gitsigns stage_hunk<CR>')
				map({'n', 'v'}, '<leader>hr', ':Gitsigns reset_hunk<CR>')
				map('n', '<leader>hp', gs.preview_hunk)
				map('n', '<leader>hS', gs.stage_buffer)
				map('n', '<leader>hu', gs.undo_stage_hunk)
				map('n', '<leader>hR', gs.reset_buffer)
				map('n', '<leader>hd', gs.diffthis)
				map('n', '<leader>hD', function() gs.diffthis('~') end)
			end
		}
	end,
}
