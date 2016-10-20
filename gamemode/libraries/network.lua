AddCSLuaFile()
local Tag = "nw3v"
local Tag_ping = "nw3v_ping" -- FUCK YOU GARRY: PART 1

local ENTITY = debug.getregistry().Entity

local vars = {}
local types = {}
local proxy = {}

local noworries = {}
function noworries:__index(k)
	self[k] = {}
	return self[k]
end

setmetatable(vars, noworries)
setmetatable(types, noworries)
setmetatable(proxy, noworries)

function ENTITY:SetNW3VarProxy(var, callback)
	proxy[var] = callback
end

local function __get(ent, var, default)
	local r = vars[ent:EntIndex()][var]
	if r == nil then return default end
	return r
end

local function get(t)
	return function(ent, var, default)
		if default == nil then default = t end
		return __get(ent, var, default)
	end
end

function ENTITY:GetNW3Vars()
	return vars[self:EntIndex()]
end

ENTITY.GetNW3Angle = get(Angle())
ENTITY.GetNW3Bool = get(false)
ENTITY.GetNW3Entity = get(NULL)
ENTITY.GetNW3Float = get(0)
ENTITY.GetNW3Int = get(0)
ENTITY.GetNW3String = get""
ENTITY.GetNW3Vector = get(Vector())

local function check(v, ...)
	local n = debug.getinfo(2).name or "?"
	if not table.HasValue({...},type(v)) then
		error("bad argument #2 to '" .. n .. "' (" .. table.concat({...},"/") .. " expected, got " .. type(v) .. ")", -1)
	end
end

if SERVER then

	util.AddNetworkString(Tag)
	util.AddNetworkString(Tag_ping)

	local function NetworkEntities()
		for _, ent in pairs(ents.GetAll()) do
			ent:NetworkNW3Vars()
		end
	end

	net.Receive(Tag_ping, function(_,ply)
		-- THANKS GARRY
		if ply.__ping_recieved then return end
		ply.__ping_recieved = true
		timer.Remove("NW3_Ping_" .. ply:EntIndex())
		NetworkEntities()
		hook.Call("NW3PlayerActuallySpawned", gmod.GetGamemode(), ply)
	end)

	local NWs = {}

	NWs["int"] = function(val)
		net.WriteInt(val, 32)
	end

	NWs["float"] = function(val)
		net.WriteFloat(val)
	end

	NWs["boolean"] = function(val)
		net.WriteBit(val and 1 or 0)
	end

	NWs["string"] = function(val)
		net.WriteUInt(#val, 32)
		net.WriteData(val, #val)
	end

	NWs["angle"] = function(val)
		net.WriteAngle(val)
	end

	NWs["vector"] = function(val)
		net.WriteVector(val)
	end

	NWs["entity"] = function(val)
		net.WriteInt(val:EntIndex(), 32)
	end

	NWs["table"] = function(val)
		net.WriteTable(val)
	end

	local function network(ent, var, type, val, ply)
		local eid = ent:EntIndex()
		local oldval = vars[eid][var]
		if val == oldval then return end
		types[eid][var] = type
		vars[eid][var] = val
		if proxy[eid][var] then proxy[eid][var](ent, var, oldval, val) end
		net.Start(Tag)
		NWs["entity"](ent)
		net.WriteString(var)
		net.WriteString(type)
		NWs[type](val)
		if ply then net.Send(ply) else net.Broadcast() end
	end

	local function remove(ent, var)
		local eid = ent:EntIndex()
		local oldval = vars[eid][var]
		if oldval == nil then return end
		types[eid][var] = nil
		vars[eid][var] = nil
		if proxy[eid][var] then proxy[eid][var](ent, var, oldval, nil) end
		net.Start(Tag)
		NWs["entity"](ent)
		net.WriteString(var)
		net.WriteString("r")
		net.Broadcast()
	end

	function ENTITY:SetNW3Angle(name, v)
		if v == nil then remove(self, name) return end
		check(v, "Angle")
		network(self, name, "angle", v)
	end

	function ENTITY:SetNW3Bool(name, v)
		if v == nil then remove(self, name) return end
		network(self, name, "boolean", v)
	end

	function ENTITY:SetNW3Entity(name, v)
		if v == nil then remove(self, name) return end
		check(v,"Entity","Vehicle","Weapon","Player","NPC")
		network(self, name, "entity", v)
	end

	function ENTITY:SetNW3Float(name, v)
		if v == nil then remove(self, name) return end
		check(v,"number")
		network(self, name, "float", v)
	end

	function ENTITY:SetNW3Int(name, v)
		if v == nil then remove(self, name) return end
		check(v, "number")
		network(self, name, "int", math.floor(v))
	end

	function ENTITY:SetNW3String(name, v)
		if v == nil then remove(self, name) return end
		network(self, name, "string", tostring(v))
	end

	function ENTITY:SetNWVector(name, v)
		if v == nil then remove(self, name) return end
		check(v, "Vector")
		network(self, name, "vector", v)
	end

	function ENTITY:NetworkNW3Vars(ply)
		for var, val in pairs(self:GetNW3Vars()) do
			network(self, var, types[self:EntIndex()][var] or "string", --fallback
			val,ply)
		end
	end

	hook.Add("PlayerInitialSpawn", "NW3.Refresh", function(ply)
		local eid = ply:EntIndex()
		timer.Simple(0.1,function()
			timer.Create("NW3_Ping_" .. eid, 1, 0, function()
				if not IsValid(ply) then
					timer.Remove("NW3_Ping_" .. eid)
				return end
				net.Start(Tag_ping)
				net.WriteString("Ping!")
				net.Send(ply)
			end)
		end)
	end)
	hook.Add("PlayerDisconnected", "NW3.Hack",function(ply)
		-- just in case they never spawn
		timer.Remove("NW3_Ping_" .. ply:EntIndex())
	end)
	hook.Add("OnEntityCreated", "NW3.Refresh", NetworkEntities)
	hook.Add("EntityRemoved", "NW3.Refresh", NetworkEntities)

else

	net.Receive(Tag, function()

		local ent = net.ReadUInt(32)
		local var = net.ReadString()
		local vt = net.ReadString()

		if vt == "r" then
			vars[ent][var] = nil
		return end

		local nv

		if vt == "int" then
			nv = net.ReadInt(32)
		elseif vt == "float" then
			nv = net.ReadFloat(32)
		elseif vt == "string" then
			local len = net.ReadInt(32)
			nv = net.ReadData(len)
		elseif vt == "boolean" then
			nv = net.ReadBit() == 1
		elseif vt == "angle" then
			nv = net.ReadAngle()
		elseif vt == "vector" then
			nv = net.ReadVector()
		elseif vt == "entity" then
			local eid = net.ReadInt(32)
			nv = Entity(eid)
		end

		local oldval = vars[ent][var]
		if proxy[ent][var] then proxy[ent][var](ent, var, oldval, nv) end

		vars[ent][var] = nv

	end)

	net.Receive(Tag_ping, function()
		net.Start(Tag_ping)
		net.WriteString("Pong!")
		net.SendToServer()
	end)

	function ENTITY:SetNW3Angle(name, v)
		if v == nil then remove(self, name) return end
		check(v, "Angle")
		vars[name] = v
	end

	function ENTITY:SetNW3Bool(name, v)
		if v == nil then remove(self, name) return end
		vars[name] = not not v
	end

	function ENTITY:SetNW3Entity(name, v)
		if v == nil then remove(self, name) return end
		check(v,"Entity","Vehicle","Weapon","Player","NPC")
		vars[name] = v
	end

	function ENTITY:SetNW3Float(name, v)
		if v == nil then remove(self, name) return end
		check(v,"number")
		vars[name] = v
	end

	function ENTITY:SetNW3Int(name, v)
		if v == nil then remove(self, name) return end
		check(v, "number")
		vars[name] = math.floor(v)
	end

	function ENTITY:SetNW3String(name, v)
		if v == nil then remove(self, name) return end
		vars[name] = tostring(v)
	end

	function ENTITY:SetNW3Vector(name, v)
		if v == nil then remove(self, name) return end
		check(v, "Vector")
		vars[name] = v
	end

end

hook.Add("EntityRemoved", "NW3.GarbageCollect", function(ent)
	local e = ent:EntIndex()
	vars[e] = nil
	types[e] = nil
	proxy[e] = nil
end)
