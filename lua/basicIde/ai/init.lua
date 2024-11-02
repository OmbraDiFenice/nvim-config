local CodeiumManager = require('basicIde.ai.codeium')
local key_mapping = require('basicIde.key_mapping')

local keymap_descriptions = {
	accept_current_suggestion = 'Accept AI suggestion',
	next_suggestion = 'Next AI suggestion',
	previous_suggestion = 'Previous AI suggestion',
	clear_current_suggestion = 'Clear AI suggestion',
}

---@param ai_config AiConfig
local function select_ai_manager(ai_config)
	if ai_config.engine == 'codeium' then
		return CodeiumManager:new(ai_config)
	end
	vim.notify('AI engine "' .. ai_config.engine .. '" not supported', vim.log.levels.WARN)
end

---@type IdeModule
return {
	use_deps = function(use)
		use 'Exafunction/codeium.vim'
	end,

	configure = function(project_settings)
		local config = project_settings.ai

		-- this needs to be done here because it's a vim global config and
		-- otherwise it would be enabled by default
		vim.g.codeium_enabled = config.enabled

		if not config.enabled then return end

		local manager = select_ai_manager(config)
		if manager == nil then return end

		manager:init()
		key_mapping.setup_keymaps(keymap_descriptions, manager, config.keymaps)
	end
}
