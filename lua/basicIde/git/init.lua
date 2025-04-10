local Monitor = require('basicIde.git.monitor')

local git_monitor = nil

---Originally the purpose was to open the commit win in a custom float window, but turns out that
---doing git editing inside the current nvim instance is more challenging that expected.
---For now just add some convenience wrappers around the fugitive command
---@param options? string # simple string of options to append after `git commit`
local function open_commit_win(options)
	if options == nil then options = '' end

	vim.api.nvim_command('Git commit ' .. options)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.api.nvim_command('startinsert')
	--vim.api.nvim_buf_set_var(buf, 'nvim_ide_autosave', false)
end

local function setup_diffview_keymaps()
	vim.keymap.set('n', '<leader>gd', function() vim.cmd [[ :DiffviewOpen ]] end, { desc = 'Open git diff' })
	vim.keymap.set({ 'n', 'v' }, '<leader>gh', function() vim.cmd [[ :DiffviewFileHistory ]] end,
		{ desc = 'Open git file/lines history' })
end

---@type IdeModule
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

	configure = function(project_settings)
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
		local diffview_actions = require('diffview.actions')
		local diffview_lib = require('diffview.lib')
		require('diffview').setup {
			keymaps = {
				view = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
					{ 'n', '<C-H>', diffview_actions.focus_files, { desc = 'Diffview: goto file panel' } },
				},
				diff1 = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
				},
				diff2 = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
				},
				diff3 = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
				},
				diff4 = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
				},
				file_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
					{ 'n', '<C-H>', diffview_actions.focus_entry, { desc = 'Diffview: focus entry' } },
				},
				file_history_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } },
					{ 'n', '<C-H>', diffview_actions.focus_entry, { desc = 'Diffview: focus entry' } },
					{ 'n', '<C-s>', function()
						local view = diffview_lib.get_current_view()
						if view ~= nil and view.panel:is_focused() then
							local item = view.panel:get_item_at_cursor()
							if item then
								local commit_hash = item.commit.hash
								if commit_hash ~= nil then
									local remote_commit_url = project_settings.build_remote_url(commit_hash)
									if remote_commit_url == nil then return end

									local exit_code, error = vim.ui.open(remote_commit_url)
									if error ~= nil then
										vim.notify(error .. '(exit code: ' .. vim.inspect(exit_code) .. ')', vim.log.levels.ERROR)
									end
								end
							end
						end
					end,
					{	desc = 'Diffview (file history): open current commit in browser' } }
				},
			},
			hooks = {
				view_opened = function(view)
					vim.api.nvim_tabpage_set_var(view.tabpage, 'diffview_tab', true)
				end,
			},
		}
		setup_diffview_keymaps()

		vim.keymap.set('n', '<leader>gc', open_commit_win, { desc = 'git commit' })
		vim.keymap.set('n', '<leader>gca', function() open_commit_win('--amend') end, { desc = 'git commit --amend' })
		vim.keymap.set('n', '<leader>gcan', function() vim.api.nvim_command('Git commit --amend --no-edit') end, { desc = 'git commit --amend --no-edit' })
		vim.keymap.set('n', '<leader>gb', function() vim.api.nvim_command('Git blame') end, { desc = 'git blame' })

		-- monitor
		git_monitor = Monitor:new(project_settings)
		git_monitor:init()
		git_monitor:start()
	end,
}
