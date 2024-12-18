local CopilotManager = {
	keymap_callbacks = {
		accept_current_suggestion = { callback = function() require("copilot.suggestion").accept() end, opts = {} },
		next_suggestion = { callback = function() require("copilot.suggestion").next() end, opts = {} },
		previous_suggestion = { callback = function() require("copilot.suggestion").prev() end, opts = {} },
		clear_current_suggestion = { callback = function() require("copilot.suggestion").dismiss() end, opts = {} },
	}
}

function CopilotManager:init()
	local filetypes = self.config.filetypes
	if self.config.disable_for_all_filetypes then
		filetypes["*"] = false
	end

	require("copilot").setup({
		panel = {
			auto_refresh = true,
		},
		suggestion = {
			enabled = self.config.enabled,
			auto_trigger = not self.config.manual,
			keymap = { -- keymaps are configured with the manger keymap_callbacks mechanism
				accept = false,
				accept_word = false,
				accept_line = false,
				next = false,
				prev = false,
				dismiss = false,
			},
		},
		filetypes = filetypes,
	})
end

---@param ai_config AiConfig
function CopilotManager:new(ai_config)
	local obj = {
		config = ai_config,
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

return CopilotManager
