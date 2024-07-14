local lualine = require('lualine')

---@class CodeBreadcrumbs
---@field msg string
local M = {
	msg = '',
}

---@class LanguageBreadcrumbHandler
---@field find_breadcrumbs fun(tree_root: TSNode, starting_node: TSNode): string Find the treesitter node path from `tree_root` to the given `starting_node`

---@type table<string, LanguageBreadcrumbHandler>
local language_handlers = {
	python = require('basicIde.statusBar.lualine_components.code_breadcrumbs.languages.python'),
	json = require('basicIde.statusBar.lualine_components.code_breadcrumbs.languages.json'),
	lua = require('basicIde.statusBar.lualine_components.code_breadcrumbs.languages.lua'),
	c = require('basicIde.statusBar.lualine_components.code_breadcrumbs.languages.c'),
	cpp = require('basicIde.statusBar.lualine_components.code_breadcrumbs.languages.c'), -- C headers are still identified as cpp file type
}

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

	vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
		desc = 'Update code breadcrumbs statusline info',
		callback = function() self:update() end,
	})

	return o
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

	local language_handler = language_handlers[file_type]
	if language_handler == nil then return {} end

	self.msg = find_breadcrumbs(tree_node, language_handler)
	lualine.refresh()
end

return M
