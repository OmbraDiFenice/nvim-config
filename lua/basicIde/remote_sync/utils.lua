local utils = require('basicIde.utils')

---Convert a local absolute path to the pair [local relative path, remote absolute path]
---@param mappings string[][] # the path mappings from |RemoteSyncSettings|
---@param file_path string # local path to be mapped. If the path doesn't start with a path separator it's assumed to be a relative path, and it's prepended with the root path
---@return string|nil, string|nil # local relative path, remote absolute path. Both nil if it wasn't possible to map the input
local function map_file_path(mappings, file_path)
	if file_path:sub(1, 1) ~= utils.files.OS.sep then
		file_path = table.concat({utils.paths.ensure_no_trailing_slash(vim.fn.getcwd()), file_path}, utils.files.OS.sep)
	end

	local selected_prefix = ''
	local source_relative_path = nil
	local destination_root_path = nil

	for _, mapping in ipairs(mappings) do
		local local_prefix = mapping[1]
		local remote_prefix = mapping[2]

		if file_path:find(local_prefix, 1, true) == 1 and #selected_prefix < #local_prefix then
			source_relative_path = utils.paths.ensure_no_leading_slash(string.sub(file_path, #local_prefix+1))
			destination_root_path = remote_prefix
			selected_prefix = local_prefix
		end
	end

	if source_relative_path ~= nil then
		source_relative_path = utils.paths.ensure_no_leading_slash("./" .. source_relative_path)
	end

	return source_relative_path, destination_root_path
end

---@param exclude_paths string[]
---@param exclude_git_ignored_files boolean
---@return string[]
local function build_ignore_list(exclude_paths, exclude_git_ignored_files)
	local ignore_list = {}

	-- first exclude user defined files and dir so they will have precedence over the rest
	ignore_list = vim.tbl_extend('force', ignore_list, exclude_paths)

	if exclude_git_ignored_files then
		local git_output, git_exit_code = utils.proc.runAndReturnOutputSync('git ls-files --other --ignored --exclude-standard')
		if git_exit_code ~= 0 then vim.notify(git_output, vim.log.levels.ERROR); goto exit end
		for _, exclude in ipairs(git_output) do
			if #exclude == 0 then goto continue end
			table.insert(ignore_list, exclude)

			::continue::
		end
	end

	::exit::
	return ignore_list
end

local function build_ignore_table(ignore_list)
	local ignore_table = {}
	local project_root = vim.fn.getcwd(-1, -1)
	for _, exclude in ipairs(ignore_list) do
		local exclude_full_path = table.concat({ project_root, utils.paths.ensure_no_leading_slash(exclude) }, utils.files.OS.sep)
		ignore_table[exclude_full_path] = true
	end
	return ignore_table
end

return {
	map_file_path = map_file_path,
	build_ignore_list = build_ignore_list,
	build_ignore_table = build_ignore_table,
}
