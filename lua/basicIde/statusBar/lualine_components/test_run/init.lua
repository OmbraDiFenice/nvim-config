---@class TestRun
---@field msg string
local TestRun_lualine_component = {
	msg = '',
}

---Constructor
---@return TestRun
function TestRun_lualine_component:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	vim.cmd [[ highlight! lualine_test_passed guifg=#98c379 guibg=#31353f ]]
	vim.cmd [[ highlight! lualine_test_failed guifg=#e86671 guibg=#31353f ]]

	vim.api.nvim_create_autocmd('User', {
		pattern = 'UpdateTestStatusBar',
		---@param data { data: { message: string } }
		callback = function(data)
			self.msg = data.data.message
			require('lualine').refresh()
		end
	})

	return o
end

return TestRun_lualine_component
