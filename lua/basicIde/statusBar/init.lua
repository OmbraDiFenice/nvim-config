local CodeBreadcrumbs = require('basicIde.statusBar.lualine_components.code_breadcrumbs')
local TestRun = require('basicIde.statusBar.lualine_components.test_run')

---@param ai_config AiConfig
local function get_ai_component(ai_config)
	if not ai_config.enabled or not ai_config.show_in_status_bar then return end

	if ai_config.engine == 'codeium' then
		return function()
			local success, res = pcall(vim.fn['codeium#GetStatusString'])
			if not success then return '' end
			return res
		end
	elseif ai_config.engine == 'copilot' then
		return { 'copilot' ,'encoding', 'fileformat', 'filetype' }
	end
end

---@param project_settings ProjectSettings
---@return string|function|table|nil element to be added to one of the lualine sections
local function get_lualine_code_breadcrumnbs_section(project_settings)
	local provider = project_settings.editor.status_bar.code_breadcrumb.provider
	if provider == "treesitter" then
		local breadcrumbs = CodeBreadcrumbs:new()
		return function() return breadcrumbs.msg end
	elseif provider == "trouble" then
		local trouble = require("trouble")
		local symbols = trouble.statusline({
			mode = "lsp_document_symbols",
			groups = {},
			title = false,
			filter = { range = true },
			format = "{kind_icon}{symbol.name:Normal}",
			-- The following line is needed to fix the background color
			-- Set it to the lualine section you want to use
			hl_group = "lualine_c_normal",
		})
		return { symbols.get, { cond = symbols.has } }
	end
	vim.notify('Unknown code breadcrumb provider: ' .. provider, vim.log.levels.WARN)
end

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'nvim-lualine/lualine.nvim',
			requires = { 'kyazdani42/nvim-web-devicons' }
		}

		use {
			'AndreM222/copilot-lualine',
			requires = { 'kyazdani42/nvim-web-devicons' }
		}
	end,

	configure = function(project_settings)
		-- ensure that the statusline color is consistent with lualine.
		-- This requires the color scheme to be already loaded, see https://github.com/folke/trouble.nvim/issues/569#issuecomment-2682633198
		vim.api.nvim_set_hl(0, "StatusLine", { link = "lualine_c_normal" })

		local testRun = TestRun:new()

		local right_side = {
			function() return testRun.msg end,
		}
		local left_side = {
			{ 'filename', path = 1, },
		}

		local ai_component = get_ai_component(project_settings.ai)
		if ai_component ~= nil then
			table.insert(right_side, ai_component)
		end

		if project_settings.editor.activity_monitor.enabled then
			local activity = require('basicIde.statusBar.lualine_components.activity')
			table.insert(right_side, { activity, config = project_settings.editor.activity_monitor })
		end

		table.insert(right_side, 'encoding')
		table.insert(right_side, 'fileformat')
		table.insert(right_side, 'filetype')

		if project_settings.editor.status_bar.code_breadcrumb.enabled then
			local code_breadcrumb_element = get_lualine_code_breadcrumnbs_section(project_settings)
			if code_breadcrumb_element ~= nil then
				table.insert(left_side, code_breadcrumb_element)
			end
		end

		require('lualine').setup {
			options = {
				globalstatus = true,
				-- to enable fancy fonts in the terminal follow these steps:
				--   1. choose and download a monospace regular font from https://github.com/ryanoasis/nerd-fonts#patched-fonts
				--   2. copy the downloaded font in the user fonts directory
				--      On linux it can be any subfolder of ~/.local/share/fonts/
				--   3. [linux] refresh the font cache with `fc-cache`
				--   4. set the new font as default font used by your terminal
				-- steps taken from https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh#L214
				icons_enabled = true,
				theme = 'onedark',
			},
			sections = {
				lualine_c = left_side,
				lualine_x = right_side,
			}
		}
	end,
}
