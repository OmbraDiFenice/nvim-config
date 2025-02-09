F = function()
	local internal = function()
		local local_var = 3
		local function local_func() end
	end
end

G = function(par)
end

local function some_local(param1, param2)
	return param1
end

local object = {
	member = "member",
	inline_function = function(x)
		local function inner_inner_func() end
		return x
	end,
}

function object.new(param1, param2)

end

function object:method() end

object.method2 = function(self, param) end

Global_var = 123

for _, val in pairs(object) do
	print(val)
end
