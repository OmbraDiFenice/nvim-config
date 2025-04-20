-- inspired from original lsp_status component https://github.com/nvim-lualine/lualine.nvim/blob/master/lua/lualine/components/lsp_status.lua
local utils = require('basicIde.utils')
local key_mapping = require('basicIde.key_mapping')
local lualine_require = require('lualine_require')

local M = lualine_require.require('lualine.component'):extend()

local default_options = {
	--icon = '',
	symbols = {
		spinner = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' },
		--spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
		done = ' ',
		separator = '',
	},

	config = {},
}

function M:open_log()
	local buf = utils.proc.openFloatWindow()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, utils.tables.map(self.log, function(line) return line.title end))
	vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
	vim.api.nvim_set_option_value('buflisted', false, { buf = buf })
	vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
	vim.keymap.set('n', 'q', function() vim.api.nvim_buf_delete(buf, { force = true }) end, { buffer = buf })
end

function M:get_keymap_manager()
	---@type KeymapManager
	return {
		keymap_callbacks = {
			show_log = {
				callback = function() self:open_log() end,
				opts = {}
			},
		}
	}
end

local keymap_description = {
	show_log = "Show activity log",
}

---@class ActivityEvent
---@field group string
---@field pattern string

---@class ActivityEvents
---@field start ActivityEvent
---@field stop ActivityEvent

---@class ActivityEventHandlerData
---@field text string?

---List of the events tracked by this activy component.
---The integration with this component is done through the events defined here rather than having each integrating component
---call some method of this object explicitly. This is done because:
---  1. this object is istantiated and used within the lualine plugin, so getting its instance is not that easy
---  2. having the definition of each event here ensures that each tracked event has a unique key.
---     If the responsibility of subscribing to the component is left to the integrating component there's the chance that
---     2 different integrating components will use the same key, which should instead be unique
---
--- The general advantage is that there's no code dependency between this component and any other component you might want to
--- integrate in this one besides the fact that the event groups mentioned here must exist. Everything is done through event names.
---
--- The drawback is that the event handler from this component cannot enforce a typing on the argument it expects.
--- It is responsibility of the integrating components to send a message with the correct content so that the integration
--- works.
--- As a result it might be necessary for the integrating component to emit a dedicated event just so that the conversion
--- from whatever data the original event contains is converted to something this component can handle.
---@type table<string, ActivityEvents> activity key -> start/stop event
local tracked_events = {
	remote_sync = {
		start = {
			group = 'BasicIde.RemoteSync',
			pattern = 'SyncStart',
		},
		stop = {
			group = 'BasicIde.RemoteSync',
			pattern = 'SyncEnd',
		},
	}
}

function M:init(options)
	-- Some defaults need reference to self.
	-- These need to be set before calling super.init
	default_options.on_click = function() self:open_log() end
	self.options = vim.tbl_deep_extend('keep', options or {}, default_options)

	M.super.init(self, self.options)

	self.symbols = self.options.symbols or {}

	self.log = {}
	self.activity_in_progress_by_id = {}
	self.activities_in_progress = 0

	key_mapping.setup_keymaps(keymap_description, self:get_keymap_manager(), self.options.config.keymaps)

	for event_key, events in pairs(tracked_events) do
		vim.api.nvim_create_autocmd('User', {
			group = events.start.group,
			pattern = events.start.pattern,
			callback = function(args) self:start_event_handler(event_key, args.data) end,
		})
		vim.api.nvim_create_autocmd('User', {
			group = events.stop.group,
			pattern = events.stop.pattern,
			callback = function(args) self:stop_event_handler(event_key, args.data) end,
		})
	end
end

---@param event_key string
---@param data ActivityEventHandlerData
function M:start_event_handler(event_key, data)
	if self.activity_in_progress_by_id[event_key] then return end
	self.activity_in_progress_by_id[event_key] = true
	self.activities_in_progress = self.activities_in_progress + 1
	self.log[#self.log + 1] = { title = os.date('%H:%M:%S') .. ' ' .. event_key .. ' started', msg = data.text }
end

---@param event_key string
---@param data ActivityEventHandlerData
function M:stop_event_handler(event_key, data)
	if not self.activity_in_progress_by_id[event_key] then return end
	self.activity_in_progress_by_id[event_key] = false
	self.activities_in_progress = self.activities_in_progress - 1
	self.log[#self.log + 1] = { title = os.date('%H:%M:%S') .. ' ' .. event_key .. ' done', msg = data.text }
end

function M:update_status()
	-- Backwards-compatible function to get the current time in nanoseconds.
	local hrtime = (vim.uv or vim.loop).hrtime

	-- Advance the spinner every 80ms
	local spinner_symbol = self.symbols.spinner[math.floor(hrtime() / (1e6 * 80)) % #self.symbols.spinner + 1]

	local status
	if self.activities_in_progress > 0 then
		status = spinner_symbol
	else
		status = self.symbols.done
	end

	return status
end

return M
