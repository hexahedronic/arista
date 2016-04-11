AddCSLuaFile()

arista.utils = {}

-- Never rely on gmod devs not borking things.
function arista.utils.nextFrame(func, ...)
	local args = {...}

	timer.Simple(0, function() func(unpack(args)) end)
end

function arista.utils.validModel(mdl)
	return util.IsValidModel(mdl)
end

function arista.utils.isModelChair(mdl)
	return mdl:find("chair") or mdl:find("seat")
end

function arista.utils.vecWithinBox(pos, topleft, bottomright)
	if not (pos.z < math.min(topleft.z, bottomright.z) or pos.z > math.max(topleft.z, bottomright.z) or
			pos.x < math.min(topleft.x, bottomright.x) or pos.x > math.max(topleft.x, bottomright.x) or
			pos.y < math.min(topleft.y, bottomright.y) or pos.y > math.max(topleft.y, bottomright.y)) then
		return true
	end

	return false
end

function arista.utils.deSerialize(str)
	return util.JSONToTable(str)
end

function arista.utils.serialize(str)
	return util.TableToJSON(str)
end

do
	local typeTranslation = {
		Int = "number",
		String = "string",
		Bool = "boolean",
	}

	local netTranslation = {
		number = "Int",
		string = "String",
		boolean = "Bool",
		Player = "Entity",
	}

	function arista.utils.typeToNet(var)
		local t = type(var)

		return netTranslation[t] or t
	end

	function arista.utils.netToType(type)
		return typeTranslation[type] or type
	end
end
