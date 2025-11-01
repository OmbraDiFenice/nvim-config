local M = {}

M.default_languages = {
	"vimdoc",
	"markdown",
	"lua",
}


---Check if a parser for the given language is installed
---@param lang string
---@return boolean
M.is_parser_available = function(lang)
	local success, _ = pcall(vim.treesitter.language.inspect, lang)
	return success
end

M.is_language_supported = function(lang)
	local configs = require('nvim-treesitter.parsers').get_parser_configs()
	return configs[lang] ~= nil
end

---Ensure all the parsers in input are installed
---@param parsers string[]
M.ensure_installed = function(parsers)
	parsers = vim.tbl_deep_extend('force', parsers, M.default_languages)
	for _, lang in ipairs(parsers) do
		if M.is_language_supported(lang) and not M.is_parser_available(lang) then
			vim.cmd("TSInstallSync " .. lang)
		end
	end
end

return M
