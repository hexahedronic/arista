AddCSLuaFile()

local entity = FindMetaTable("Entity")

function entity:isPlayerRagdoll()
	local ply = self:getRagdollPlayer()
	return ply and IsValid(ply)
end

function entity:getRagdollPlayer()
	return self._player or NULL
end

function entity:isCorpse()
	return self._corpse
end

function entity:physgunForbidden()
	local class = self:GetClass()
	return class:find("npc_") or class:find("arista_") or class:find("cider_") or class:find("prop_dynamic") --[[or cider.entity.isDoor(class, true)]]
end

function entity:toolForbidden()
	local class = self:GetClass()
	return class:find("camera") or --[[cider.entity.isDoor(class, true) or]] class:find("vehicle")
end
