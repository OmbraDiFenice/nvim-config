local utils = require('basicIde.utils')

local CodeiumManager = {
	keymap_callbacks = {
		accept_current_suggestion = { callback = function() return vim.fn['codeium#Accept']() end, opts = { expr = true, silent = true } },
		next_suggestion = { callback = function() return vim.fn['codeium#CycleCompletions'](1) end, opts = { expr = true, silent = true } },
		previous_suggestion = { callback = function() return vim.fn['codeium#CycleCompletions'](-1) end, opts = { expr = true, silent = true } },
		clear_current_suggestion = { callback = function() return vim.fn['codeium#Clear']() end, opts = { expr = true, silent = true } },
	}
}

function CodeiumManager:init()
	vim.g.codeium_enabled = self.config.enabled
	vim.g.codeium_manual = self.config.manual
	vim.g.codeium_render = self.config.render_suggestion

	vim.g.codeium_disable_bindings = true

	vim.g.codeium_disable_for_all_filetypes = self.config.disable_for_all_filetypes
	local default_filetype = {
		TelescopePrompt = false,
	}
	vim.g.codeium_filetypes = utils.tables.deepmerge(default_filetype, self.config.filetypes)
end

---@param ai_config AiConfig
function CodeiumManager:new(ai_config)
	local obj = {
		config = ai_config,
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

return CodeiumManager
