AddCSLuaFile()

local entity = FindMetaTable("Entity")

function entity:getTitle()
	if CLIENT then return self:getAristaString("title") end
	return self:getAristaVar("title") or ""
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
	return class:find("npc_") or class:find("arista_") or class:find("cider_") or class:find("prop_dynamic") or arista.entity.isDoor(self, true)
end

function entity:toolForbidden()
	local class = self:GetClass()
	return class:find("camera") or arista.entity.isDoor(self, true) or class:find("vehicle")
end

if SERVER then
function entity:setAristaVar(var, val)
	if not (self and IsValid(self)) then return end

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
		if ty == "number" and netType == "Float" then ty = "Float" end

		if ty ~= netType and ty ~= valType then
			arista.logs.event(arista.logs.E.FATAL, arista.logs.E.NETEVENT, "ATTEMPTING TO NETWORK DIFFERING DATATYPE FOR VAR '", var, "' <t=", ty, "><s=", netType, "> ON ", self, ".")

			return
		end

		self["SetNW3" .. netType](self, "arista_" .. var, val)
	end

	self._aristaVars[var] = val
end

function entity:getAristaVar(var)
	self._aristaVars = self._aristaVars or {}

	return self._aristaVars[var]
end

function entity:networkAristaVar(var, val, precision)
	local type = arista.utils.typeToNet(val)
	if type == "Int" and precision then type = "Float" end

	self._varsToNetwork = self._varsToNetwork or {}
	self._varsToNetwork[var] = type

	self:setAristaVar(var, val)
end

local defaults = {String = "RELOAD", Int = 0, Float = 0, Bool = false, Entity = game.GetWorld()}
function entity:forceNetworkUpdate()
	for k, v in pairs(self._varsToNetwork) do
		local val = self:getAristaVar(k)
		local def = defaults[v]

		self:setAristaVar(k, def)

		timer.Simple(FrameTime(), function()
			if not (self and self:IsValid()) then return end
			self:setAristaVar(k, val)
		end)
	end
end

else

local function createTypeNetworker(class)
	arista.logs.logNoPrefix(arista.logs.E.DEBUG, "Creating networker for '", class, "' (player.getArista", class, ").")

	entity["getArista" .. class] = function(self, key)
		return self["GetNW3" .. class](self, "arista_" .. key)
	end
end

createTypeNetworker("Int")
createTypeNetworker("Entity")
createTypeNetworker("String")
createTypeNetworker("Bool")
createTypeNetworker("Float")

end

