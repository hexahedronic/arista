AddCSLuaFile()

local player = FindMetaTable("Player")

function player:setAristaVar(var, val)
	if CLIENT then return end

	self._aristaVars = self._aristaVars or {}
	self._databaseVars = self._databaseVars or {}
	self._varsToNetwork = self._varsToNetwork or {}

	if self._databaseVars[var] ~= nil then
		self._databaseVars[var] = val
	end

	local netType = self._varsToNetwork[var]
	if netType then
		local valType = arista.utils.netToType(netType)
		local ty = type(val)

		if ty ~= netType and ty ~= valType then
			arista.logs.event(arista.logs.E.FATAL, arista.logs.E.NETEVENT, "ATTEMPTING TO NETWORK DIFFERING DATATYPE FOR VAR '", var, "' <t=", ty, "><s=", netType, "> ON ", self:Name(), "(", self:SteamID(), ").")

			return
		end

		self["SetNW2" .. netType](self, "arista_" .. var, val)
	end

	self._aristaVars[var] = val
end

function player:databaseAristaVar(var)
	if CLIENT then return end

	self._databaseVars = self._databaseVars or {}

	self._databaseVars[var] = self:getAristaVar(var)
end

function player:getAristaVar(var)
	if CLIENT then return end

	self._aristaVars = self._aristaVars or {}

	return self._aristaVars[var]
end

function player:networkAristaVar(var, val)
	if CLIENT then return end

	self._varsToNetwork = self._varsToNetwork or {}
	self._varsToNetwork[var] = arista.utils.typeToNet(val)

	self:setAristaVar(var, val)
end

if CLIENT then

local function createTypeNetworker(class)
	arista.logs.logNoPrefix(arista.logs.E.DEBUG, "Creating networker for '", class, "' (player.getArista", class, ").")

	player["getArista" .. class] = function(self, key)
		return self["GetNW2" .. class](self, "arista_" .. key)
	end
end

createTypeNetworker("Int")
createTypeNetworker("Entity")
createTypeNetworker("String")
createTypeNetworker("Bool")

end
