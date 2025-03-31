local utils = require('basicIde.utils')
local key_mapping = require('basicIde.key_mapping')

local keymap_descriptions = {
	new_chat = 'Open a new chat in a new tab',
	toggle = 'Toggle the last active chat',
	search = 'Search through chats',
	delete = 'Delete the current chat',
	rewrite = 'Ask for a prompt and rewrite the current line/selection in a new split window',
	stop = 'Stop any ongoing response',
}

local manager = {
	keymap_callbacks = {
		new_chat = { callback = function() vim.cmd('GpChatNew') end, opts = { silent = true } },
		toggle = { callback = function() vim.cmd('GpChatToggle') end, opts = { silent = true } },
		search = { callback = function() vim.cmd('GpChatFinder') end, opts = { silent = true } },
		delete = { callback = function() vim.cmd('GpChatDelete') end, opts = { silent = true } },
		rewrite = { callback = function() vim.cmd('GpVnew') end, opts = { silent = true } },
		stop = { callback = function() vim.cmd('GpStop') end, opts = { silent = true } },
	}
}

---@type IdeModule
return {
	use_deps = function(use)
		use "robitx/gp.nvim"
	end,

	configure = function(project_settings)
		local config = project_settings.ai_chat
		if not config.enabled then return end

		local gp_settings = {
			state_dir = table.concat({ utils.get_data_directory(), "gp", "persisted" }, utils.files.OS.sep),
			chat_dir = table.concat({ utils.get_data_directory(), "gp", "chats" }, utils.files.OS.sep),
			log_file = table.concat({ utils.get_data_directory(), "gp.nvim.log" }, utils.files.OS.sep),
			log_sensitive = false,

			providers = {
				openai = {
					endpoint = "https://api.openai.com/v1/chat/completions",
					secret = config.api_key,
				},
			},

			default_command_agent = "Dummy",
			default_chat_agent = "Dummy",

			agents = {
				{
					name = "ChatGPT4o",
					provider = "openai",
					secret = config.api_key,
					chat = true,
					command = false,
					-- string with model name or table with model name and parameters
					model = { model = "chatgpt-4o-latest", temperature = 1.1, top_p = 1 },
					-- system prompt (use this to specify the persona/role of the AI)
					system_prompt = require("gp.defaults").chat_system_prompt,
				},
			}
		}

		if config.provider == 'openai' then
			gp_settings.openai_api_key = config.api_key
		end

		gp_settings.providers[config.provider] = {
			disable = false,
			secret = config.api_key,
		}

		if config.endpoint ~= nil then
			gp_settings.providers[config.provider].endpoint = config.endpoint
		end

		require("gp").setup(gp_settings)

		key_mapping.setup_keymaps(keymap_descriptions, manager, config.keymaps)
	end
}
