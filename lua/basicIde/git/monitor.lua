local utils = require('basicIde.utils')

local augroup = vim.api.nvim_create_augroup('BasicIde.GitMonitor', {})

local M = {}

function M:init()
	local _, exit_code = utils.proc.runAndReturnOutputSync('git rev-parse --is-inside-git-dir', { cwd = self.project_settings.PROJECT_ROOT_DIRECTORY })
	if exit_code ~= 0 then vim.notify('not in a git repo, disabling git monitor'); return end

	self._monitor = vim.loop.new_fs_event()
	if self._monitor == nil then vim.notify('unable to create watch event for git monitor'); return end

	local git_dir_lines, err = utils.proc.runAndReturnOutputSync('git rev-parse --path-format=absolute --git-dir')
	if err ~= 0 then vim.notify('unable to find git dir. Files won\'t be synchronized automatically'); return end
	self.git_dir = table.concat(git_dir_lines, "") -- rev-parse returns multiple lines but some of them are empty and the order is inconsistent

	local git_common_dir_lines = utils.proc.runAndReturnOutputSync('git rev-parse --path-format=absolute --git-common-dir')
	self.git_common_dir = table.concat(git_common_dir_lines, "") -- rev-parse returns multiple lines but some of them are empty and the order is inconsistent

	self.in_git_worktree = self.git_common_dir ~= self.git_dir
	self.git_head_path = table.concat({ self.git_dir, 'HEAD' }, utils.files.OS.sep)
end

---@param project_settings ProjectSettings
function M:new(project_settings)
	local o = {
		project_settings = project_settings,
		_monitor = nil,
		git_dir = '',
		git_common_dir = '',
		git_head_path = '',
		in_git_worktree = false,
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

---Setup file watcher to trigger repository sync on git worktree changes (checkout, stash etc)
function M:start()
	if self._monitor == nil then return end

	local function start_monitoring()
		self._monitor:start(self.git_head_path,
			{ watch_entry = true },
			function(err, _, events)
				if err ~= nil then vim.notify(err, vim.log.levels.ERROR); return end
				self._monitor:stop()
				start_monitoring()
				if events.change == nil then return end

				vim.schedule_wrap(function()
					local monitored_paths = { self.project_settings.PROJECT_ROOT_DIRECTORY }
					if self.in_git_worktree then
						table.insert(monitored_paths, self.git_common_dir)
					end

					vim.api.nvim_exec_autocmds('User', {
						group = augroup,
						pattern = 'Change',
						data = {
							paths = monitored_paths
						},
					})
				end)()
		end)
	end

	start_monitoring()
end

return M
