AddCSLuaFile()

local entity = FindMetaTable("Entity")

function entity:getName()
	if CLIENT then return self:getAristaString("name") end
	return self:getAristaVar("name") or ""
end

function entity:isSealed()
	if CLIENT then return self:getAristaBool("sealed") or false end
	return self:getAristaVar("sealed") or false
end

function entity:isJammed()
	if CLIENT then return self:getAristaBool("jammed") or false end
	return self:getAristaVar("jammed") or false
end

function entity:isLocked()
	if CLIENT then return self:getAristaBool("locked") or false end
	return self:getAristaVar("locked") or false
end

function entity:isPlayerRagdoll()
	local ply = self:getRagdollPlayer()
	return ply and IsValid(ply)
end

function entity:getRagdollPlayer()
	if CLIENT then return self:getAristaEntity("player") or NULL end
	return self:getAristaVar("player") or NULL
end

function entity:isCorpse()
	if CLIENT then return self:getAristaBool("corpse") or false end
	return self:getAristaVar("corpse")
end

function entity:physgunForbidden()
	local class = self:GetClass()
	return class:find("npc_") or class:find("arista_") or class:find("cider_") or class:find("prop_dynamic") --[[or cider.entity.isDoor(class, true)]]
end

function entity:toolForbidden()
	local class = self:GetClass()
	return class:find("camera") or --[[cider.entity.isDoor(class, true) or]] class:find("vehicle")
end

if SERVER then
function entity:setAristaVar(var, val)

	self._aristaVars = self._aristaVars or {}
	if self:IsPlayer() then self._databaseVars = self._databaseVars or {} end
	self._varsToNetwork = self._varsToNetwork or {}

	if self:IsPlayer() and self._databaseVars[var] ~= nil then
		self._databaseVars[var] = val
	end

	local netType = self._varsToNetwork[var]
	if netType then
		local valType = arista.utils.netToType(netType)
		local ty = type(val)

		-- Fuck my life.
		if ty == "Player" then ty = "Entity" end

		if ty ~= netType and ty ~= valType then
			arista.logs.event(arista.logs.E.FATAL, arista.logs.E.NETEVENT, "ATTEMPTING TO NETWORK DIFFERING DATATYPE FOR VAR '", var, "' <t=", ty, "><s=", netType, "> ON ", self, ".")

			return
		end

		self["SetNW2" .. netType](self, "arista_" .. var, val)
	end

	self._aristaVars[var] = val
end

function entity:getAristaVar(var)

	self._aristaVars = self._aristaVars or {}

	return self._aristaVars[var]
end

function entity:networkAristaVar(var, val)

	self._varsToNetwork = self._varsToNetwork or {}
	self._varsToNetwork[var] = arista.utils.typeToNet(val)

	self:setAristaVar(var, val)
end

else

local function createTypeNetworker(class)
	arista.logs.logNoPrefix(arista.logs.E.DEBUG, "Creating networker for '", class, "' (player.getArista", class, ").")

	entity["getArista" .. class] = function(self, key)
		return self["GetNW2" .. class](self, "arista_" .. key)
	end
end

createTypeNetworker("Int")
createTypeNetworker("Entity")
createTypeNetworker("String")
createTypeNetworker("Bool")

end

