AddCSLuaFile()

arista.timer = {}

function arista.timer.conditional(name, time, conditional, success, failure, ...)
	local args = {...}

	-- todo: VarArgs are finicky, replace this if possible please.
	local suc = function()
		success(unpack(args))
	end
	timer.Create(name, time + 1, 1, suc)

	local tick = function()
		if conditional(unpack(args)) then
			failure(unpack(args))

			timer.Destroy(name)
			timer.Destroy(name .. "_tick")
		end
	end
	timer.Create(strName .. "_tick", 1, time, tick)
end
