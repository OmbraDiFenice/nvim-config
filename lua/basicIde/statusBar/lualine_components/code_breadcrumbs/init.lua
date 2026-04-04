---@class CodeBreadcrumbs
---@field msg string
---@field _timer uv_timer_t?
local M = {
	msg = '',
	_timer = nil,
}

---@class LanguageBreadcrumbHandler
---@field find_breadcrumbs fun(tree_root: TSNode, starting_node: TSNode): string Find the treesitter node path from `tree_root` to the given `starting_node`

---@type table<string, string>
local language_handler_modules = {
	python = 'basicIde.statusBar.lualine_components.code_breadcrumbs.languages.python',
	json = 'basicIde.statusBar.lualine_components.code_breadcrumbs.languages.json',
	lua = 'basicIde.statusBar.lualine_components.code_breadcrumbs.languages.lua',
	c = 'basicIde.statusBar.lualine_components.code_breadcrumbs.languages.c',
	cpp = 'basicIde.statusBar.lualine_components.code_breadcrumbs.languages.c', -- C headers are still identified as cpp file type
}

---@type table<string, LanguageBreadcrumbHandler>
local loaded_language_handlers = {}

---@param file_type string
---@return LanguageBreadcrumbHandler?
local function get_language_handler(file_type)
	if loaded_language_handlers[file_type] ~= nil then
		return loaded_language_handlers[file_type]
	end

	local module_name = language_handler_modules[file_type]
	if module_name == nil then return nil end

	local handler = require(module_name)
	loaded_language_handlers[file_type] = handler
	return handler
end

---Find the treesitter node path from root of the file to the given `tree_node`
---@param tree_node TSNode
---@param language_handler LanguageBreadcrumbHandler
---@return string
local function find_breadcrumbs(tree_node, language_handler)
	local root = tree_node:tree():root()
	return language_handler.find_breadcrumbs(root, tree_node)
end

---Constructor
---@return CodeBreadcrumbs
function M:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	vim.api.nvim_create_autocmd({ 'CursorMoved', 'BufEnter' }, {
		desc = 'Update code breadcrumbs statusline info',
		callback = function() o:schedule_update() end,
	})

	return o
end

---Throttle breadcrumb recomputation while moving around the buffer.
---@return nil
function M:schedule_update()
	if self._timer ~= nil then
		self._timer:stop()
		self._timer:close()
	end

	self._timer = vim.uv.new_timer()
	self._timer:start(75, 0, vim.schedule_wrap(function()
		if self._timer ~= nil then
			self._timer:stop()
			self._timer:close()
			self._timer = nil
		end
		self:update()
	end))
end

---Recompute the value of the `msg` field and trigger `lualine.refresh()`
---@return nil
function M:update()
	local lang = vim.bo.filetype
	local parsers = vim.treesitter.language.get_filetypes(lang)
	if #parsers == 0 then return end

	local success, tree_node = pcall(vim.treesitter.get_node)
	if not success or tree_node == nil then return end

	local file_type = vim.api.nvim_get_option_value('filetype', { scope = 'local' })
	if file_type == nil then return end

	local language_handler = get_language_handler(file_type)
	if language_handler == nil then return {} end

	local next_msg = find_breadcrumbs(tree_node, language_handler)
	if next_msg == self.msg then return end

	self.msg = next_msg
	require('lualine').refresh()
end

return M
