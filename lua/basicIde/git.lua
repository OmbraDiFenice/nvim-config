local utils = require('basicIde/utils')

local function open_commit_win()
	local function _edit_commit()
		local buf = utils.openFloatWindow({
			title = 'Commit message',
			title_pos = 'center',
		})
		utils.runAndReturnOutput({ 'git', 'commit' }, function() -- regenerates default commit message
			vim.cmd.edit('.git/COMMIT_EDITMSG')                -- TODO: get file from git config (is it possible?), possibly allowing to commit in submodules
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
			vim.api.nvim_buf_set_var(buf, 'nvim_ide_autosave', false)
			vim.cmd('startinsert')

			vim.keymap.set('n', '<esc>', function()
				vim.api.nvim_buf_delete(buf, { force = true })
			end, { desc = 'Close float window', buffer = buf })
		end, {
			env = {
				GIT_EDITOR = false,
			}
		})
	end

	local function remove_trailing_empty_lines(lines)
		local cleaned_lines = {}
		local non_empty_found = false

		for i = #lines, 1, -1 do
			if #(lines[i]) ~= 0 or non_empty_found then
				non_empty_found = true
				table.insert(cleaned_lines, 1, lines[i])
			end
		end

		return cleaned_lines
	end


	utils.runAndReturnOutput({ 'git', 'diff', '--cached', '--numstat' }, -- gets 1 line per file in staging area
		function(output, exit_code)
			output = remove_trailing_empty_lines(output)
			P(output)
			if #output == 0 then
				utils.runAndReturnOutput({ 'git', 'status' }, Printlines) -- notify the output of git status in nvim
			else
				_edit_commit()
			end
		end
	)
end

local function setup_diffview_keymaps()
	vim.keymap.set('n', '<leader>gd', function() vim.cmd [[ :DiffviewOpen ]] end, { desc = 'Open git diff' })
	vim.keymap.set({ 'n', 'v' }, '<leader>gh', function() vim.cmd [[ :DiffviewFileHistory ]] end,
		{ desc = 'Open git file/lines history' })
end

return {
	use_deps = function(use)
		use {
			'tpope/vim-fugitive',
		}
		use {
			'lewis6991/gitsigns.nvim',
		}
		use {
			"sindrets/diffview.nvim",
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
				end, { expr = true, desc = 'goto next hunk' })

				map('n', '[c', function()
					if vim.wo.diff then return '[c' end
					vim.schedule(function() gs.prev_hunk() end)
					return '<Ignore>'
				end, { expr = true, desc = 'goto previous hunk' })

				-- Actions
				map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', { desc = 'stage hunk' })
				map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', { desc = 'reset hunk' })
				map('n', '<leader>hp', gs.preview_hunk, { desc = 'git preview hunk' })
				map('n', '<leader>hS', gs.stage_buffer, { desc = 'git stage buffer' })
				map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
				map('n', '<leader>hR', gs.reset_buffer, { desc = 'git reset buffer' })
				map('n', '<leader>hd', gs.diffthis, { desc = 'git diff this' })
				map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'git diff ~' })
			end
		}

		-- diffview

		require('diffview').setup {
			keymaps = {
				view = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff1 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff2 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff3 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff4 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				file_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				file_history_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
			},
			hooks = {
				view_opened = function(view)
					vim.api.nvim_tabpage_set_var(view.tabpage, 'diffview_tab', true)
				end,
			},
		}
		setup_diffview_keymaps()

		-- custom commit float

		vim.keymap.set('n', 'gc', open_commit_win, { desc = 'open float window to commit changes' })
	end,
}
