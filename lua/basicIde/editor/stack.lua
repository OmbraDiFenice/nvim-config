---@class Stack
---@field push fun(data: any): nil
---@field pop fun(): any
---@field top fun(): any
---@field empty fun(): boolean
---@field content fun(): any[]

local M = {}

---@return Stack
function M:new()
	local o = { data = {} }
	setmetatable(o, self)
	self.__index = self
	return o
end

function M:push(d)
	if d == nil then return end
	table.insert(self.data, d)
end

function M:pop()
	local d = self:top()
	table.remove(self.data)
	return d
end

function M:top()
	if self:empty() then return nil end
	return table[#self.data]
end

function M:empty()
	return #self.data == 0
end

function M:content()
	return self.data
end

return M
