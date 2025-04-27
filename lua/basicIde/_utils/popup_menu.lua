local M = {}

---@class PopupMenuOpts
---@field icon string?
---@field mode string? defaults to "a"
---@field enabled_by string? key of a callback used to determine if the entry should be enabled. If nil it's always enabled
---@field is_keymap boolean? if true the command is treated as a keymap. Defaults to false

---@type PopupMenuOpts
local default_opts = {
	icon = nil,
	mode = "a",
	enabled_by = nil,
	is_keymap = false,
}

---Used to disambiguate divider entries
local uniq_counter = 1

---Maps the title with which the entry was created (via make_popup_menu_entry) to the full information it was created with.
---This can be used to uniquely indentify the actual menu entry in vim config via the (hopefully simpler) entry name.
---@type table<string, {title: string, opts: PopupMenuOpts}>
local entry_map = {}

---Map of callbacks to determine if menu entries should be enabled.
---These callbacks are kept separated from each menu entry so that they can be computed only once when the popup menu is opened.
---Use make_popup_menu_enable_callback to create a new one.
---@type table<string, fun(): boolean>
local enabled_callback_map = {}

---Internal utility function to convert a menu entry title to its displayable form
---@param title string
---@param opts PopupMenuOpts
local function get_title(title, opts)
	local key = opts.mode .. title
	if entry_map[key] then
		return entry_map[key].title
	end

	local final_title = title:gsub("^%l", string.upper)
	if opts.icon then
		final_title = opts.icon .. " " .. final_title
	end
	final_title = final_title:gsub(" ", "\\ ") -- done last so we don't have to escape spaces before

	entry_map[key] = { title = final_title, opts = opts }

	return final_title
end

---Internal utility to convert the command to the right string to be used in the menu entry definition
---@param command string?
---@param opts PopupMenuOpts
---@return string
local function get_command(command, opts)
	if command == nil then
		command = "<Nop>"
	else
		if not opts.is_keymap then
			command = ":<C-u>" .. command .. "<CR>"
		end
	end
	return command
end

---Enable or disable a menu entry
---@param title string
---@param enabled boolean
local function set_enabled(title, enabled)
	if entry_map[title] == nil then
		vim.notify("Tried to enable/disable unknown menu entry: " .. title, vim.log.levels.ERROR)
		return
	end

	local opts = entry_map[title].opts

	local enable = "enable"
	if not enabled then enable = "disable" end

	vim.cmd(opts.mode .. "menu " .. enable .. " PopUp." .. entry_map[title].title)
end

---Create a new menu entry
---@param title string the title of the menu entry. This is also the identifier for this entry
---@param command string? only vimscript is supported. If nil defaults to <Nop>
---@param opts PopupMenuOpts
function M.make_entry(title, command, opts)
	if title:sub(1, 1) == "-" then
		return M.make_divider()
	end

	if opts.is_keymap and opts.mode == "a" then
		vim.notify("Cannot create a menu entry with is_keymap true in mode 'a'\n"..
		           "See the note about added prefixes in :help amenu", vim.log.levels.ERROR)
		return
	end

	opts = vim.tbl_extend("force", default_opts, opts or {})

	command = get_command(command, opts)
	title = get_title(title, opts)

	local re_qualifier = "nore"
	if opts.is_keymap then
		re_qualifier = ""
	end

	vim.cmd(opts.mode .. re_qualifier .. "menu <silent> PopUp." .. title .. " " .. command)
end

---Create a menu divider
function M.make_divider()
	vim.cmd("amenu PopUp.-" .. uniq_counter .. "- <Nop>")
	uniq_counter = uniq_counter + 1
end

---Create a new enable callback
---The user is responsible to make sure the key is unique. If it's not an error is raised and the existing callback is not modified.
---@param callback_key string
---@param callback fun(): boolean
---@return string the same callback_key passed as an argument. Convenient to assign it to a variable in the caller to be reused without copying the literal string
function M.make_enable_callback(callback_key, callback)
	if enabled_callback_map[callback_key] == nil then
		enabled_callback_map[callback_key] = callback
	end
	return callback_key
end

function M.setup()
	vim.cmd [[
		aunmenu PopUp.How-to\ disable\ mouse
		aunmenu PopUp.-1-
	]]

	vim.api.nvim_create_autocmd('MenuPopup', {
		pattern = '*',
		group = vim.api.nvim_create_augroup('BasicIde.MouseMenu', { clear = true }),
		desc = 'Populate mouse popup menu',
		callback = function()
			local enabled_cb_result = {}
			for key, cb in pairs(enabled_callback_map) do
				enabled_cb_result[key] = cb()
			end

			for entry_map_key, entry_map_val in pairs(entry_map) do
				local enabled_by = entry_map_val.opts.enabled_by
				if enabled_by ~= nil then
					set_enabled(entry_map_key, enabled_cb_result[enabled_by])
				end
			end
		end,
	})
end

return M
