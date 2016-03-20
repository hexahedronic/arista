AddCSLuaFile()

arista.timer = {}

local conditionals = {}
function arista.timer.conditional(name, time, conditional, success, failure, ...)
	local args = {...}

	-- So we can violate it.
	conditionals[name] = {f = failure, a = args}

	-- todo: VarArgs are finicky, replace this if possible please.
	local suc = function()
		success(unpack(args))
	end
	timer.Create(name, time + 1, 1, suc)

	local tick = function()
		if conditional(unpack(args)) == false then
			failure(unpack(args))

			timer.Destroy(name)
			timer.Destroy(name .. "_tick")
		end
	end
	timer.Create(name .. "_tick", 1, time, tick)
end

function arista.timer.violate(name)
	timer.Destroy(name)
	timer.Destroy(name .. "_tick")

	local t = conditionals[name]
	if not t or not t.f then return end

	t.f(unpack(t.a))
end
