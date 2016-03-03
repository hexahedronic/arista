AddCSLuaFile()

-- arista: RolePlay FrameWork --
arista = {}

-- Used to store things that don't have their own home.
arista._internaldata = {}

-- Derive functionality from sandbox
DeriveGamemode("Sandbox")

-- This replaces GM/GAMEMODE.
arista.gamemode = {
	name = "arista Framework",
	author = "kuromeku, Lexi, Q2F2, et al.",
	email = "N/A",
	website = "https://github.com/hexahedronic/arista/",

	info = [[
	A re-write of AppleJack (https://github.com/Lexicality/applejack-old).
	This gamemode consists mostly of applejack's code (which was built on cider),
	and we only take credit for the modifications made, not the source material.

	The idea of Arista is to provide an open-source, up-to-date, bugfixed version of applejack.

	With this idea we hope to give smaller servers the ability to run a gamemode other
	than DarkRP, due to the saturation of DarkRP's servers.

	Note: This is not CityRP, I beleive at some point in the past CityRP was based on
	either cider/applejack, but this does not MEAN THEY ARE THE SAME THING.

	DO NOT REMOVE KURO OR LEXI FROM THE AUTHOR FIELD.
	]],

	folder = GM.Folder .. "/",
	luaFolder = GM.Folder:sub(11, -1) .. "/",
	gmFolder = GM.Folder:sub(11, -1) .. "/gamemode/",
}

-- Stupid garry compat.
GM.Name = arista.gamemode.name

GM.Author = arista.gamemode.author
GM.Email = arista.gamemode.email
GM.Website = arista.gamemode.website

GM.Info = arista.gamemode.info

GM.Folder = arista.gamemode.folder
GM.LuaFolder = arista.gamemode.luaFolder
GM.GMFolder = arista.gamemode.gmFolder

include("libraries/logs.lua")
include("libraries/file.lua")

-- This makes more sense tbh
function gamemode.Call(name, ...)
	local gm = gmod.GetGamemode() or GM or GAMEMODE or {}

	if not gm[name] then
		arista.logs.log(arista.logs.E.WARNING, "Hook called '", name, "' called that does not have a GM: function!\n")
	end

	return hook.Call(name, gm, ...)
end

--includecs("sh_enumerations.lua")
include("sh_config.lua")

-- Check if we're running on the server.
if SERVER then
	include("sv_config.lua")
	AddCSLuaFile("cl_language.lua")
else
	include("cl_language.lua")
end

-- This needs to be here, since it may not get defined, but gets called regardless.
function GM:LibrariesLoaded()
end

-- Called when a bullet tries to ricochet
function GM:CanRicochet(trace, force, swep)
	return force > 5
end
-- Called when a bullet tries to penetrate
function GM:CanPenetrate(trace, force, swep)
	return force > 7.5
end

if CLIENT then arista.derma = {} end

arista.file.loadDir("extensions/", "Extension", "Extensions")

arista.file.loadDir("derma/", "Panel", "Panels")

arista.file.loadDir("libraries/", "Library", "Libraries")
arista.file.loadDir("metatables/", "Metatable", "Metatables")

arista.file.loadDir("hooks/", "Hook Library", "Hook Libraries")

-- Libs have been loaded
gamemode.Call("LibrariesLoaded")

-- Check if we're running on the server.
if SERVER then
	--include("sv_commands.lua")
	--include("sv_umsgs.lua")
	--AddCSLuaFile("cl_content.lua")
else
	--include("cl_content.lua")
end

--GM:LoadPlugins()
--GM:LoadItems()

--This stuff needs to be after plugins but before everything else
--includecs("sh_events.lua")
--includecs("sh_jobs.lua")

-- A table that will hold entities that were there when the map started.
arista._internaldata.entities = {}

-- Called when a player attempts to punt an entity with the gravity gun.
function GM:GravGunPunt(ply, entity)
	return arista.utils.isAdmin(ply)
end

-- Called when a player attempts to pick up an entity with the physics gun.
function GM:PhysgunPickup(ply, entity)
	if not entity:IsValid() then return false end

	-- Ugly casing, nothing I can do to hack this without overcomplicating everything.
	if entity.PhysgunPickup and isfunction(entity.PhysgunPickup) then
		return entity:PhysgunPickup(ply)
	elseif entity.PhysgunDisabled then
		return false
	elseif arista._internaldata.entities[entity] then--and not arista.utils.isAdmin(ply) then -- Fed up with admins physgunning fucking doors
			return false
	elseif entity:IsVehicle() and not entity:isTouchable(ply) then
		return false
	elseif arista.utils.isAdmin(ply) then
		if entity:IsPlayer() then
			if entity:InVehicle() then
				return false
			else
				--entity:SetMoveType(MOVETYPE_NOCLIP)
				--ply._Physgunnin = true
				-- todo: only do this if arista is incharge of admin systems.
			end
		end

		-- Admins can pick up forbidden, ect, so return here.
		return self.BaseClass:PhysgunPickup(ply, entity)
	end

	-- Check if this entity is a player's ragdoll.
	if entity:isPlayerRagdoll() then return false end

	-- Check if the entity is a forbidden class.
	-- Kept cider_ for potential backwards compat.
	if entity:physgunForbidden() then
		return false
	end

	-- Call the base class function.
	return self.BaseClass:PhysgunPickup(ply, entity)
end

-- Called when a player attempts to drop an entity with the physics gun.
function GM:PhysgunDrop(ply, entity)
	--[[if ( entity:IsPlayer() ) then
		entity:SetMoveType(MOVETYPE_WALK)
		ply._Physgunnin = false
	end]]
	-- todo: only do this if arista is incharge of admin systems.

	-- Call the base class function.
	return self.BaseClass:PhysgunDrop(ply, entity)
end

function GM:OnPhysgunFreeze(weapon, phys, entity, ply)
	if entity:IsVehicle() and not entity:isTouchable(ply) then
		return false
	end

	return self.BaseClass:OnPhysgunFreeze(weapon, phys, entity, ply)
end

-- Called when a player attempts to use a tool.
function GM:CanTool(ply, trace, tool)
	local ent = trace.Entity
	local doLog = SERVER and tool ~= "precision"
	-- todo: maybe config for ignored tools?

	-- Check if the trace entity is valid.
	if IsValid(ent) then
		-- Overwrite certain ents that should not be tooled no matter what
		if tool ~= "remover" and not arista.utils.isAdmin(ply) and ent:toolForbidden() then
			if doLog then arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (ent.toolForbbiden).") end

			return false
		end

		-- Built-in allowed tools.
		if ent.m_tblToolsAllowed then
			local vFound = false

			for k, v in pairs(ent.m_tblToolsAllowed) do
				if tool == v then vFound = true end
			end

			if not vFound then
				if doLog then arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (ent.m_tblToolsAllowed).") end

				return false
			end
		end

		-- Give the entity a chance.
		if ent.CanTool and isfunction(ent.CanTool) then
			return ent:CanTool(ply, trace, tool)
		end

		do
			local owner = cider.entity.getOwner(ent)

			if tool == "remover" and ent._removeable and arista.entity.isDoor(ent) and cider.entity.isOwned(ent) and type(owner) == "Player" and not ply:KeyDown(IN_RELOAD) then
				-- todo: language
				owner:takeDoor(ent)
			end
		end

		--[[if !ply:HasAccess("w") and string.sub(tool, 1, 5) == "wire_" then
			ply:ConCommand("gmod_toolmode \"\"\n")

			-- Return false because we cannot use the tool.
			return false
		end]]
		-- todo: hasaccess

		-- Check if this entity cannot be used by the tool.
		if arista._internaldata.entities[trace.Entity] then
			if doLog then arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (Map Entity).") end

			return false
		end

		-- Check if we're using the remover tool and we're trying to remove constrained entities.
		if tool == "remover" and ply:KeyDown(IN_ATTACK2) and not ply:KeyDownLast(IN_ATTACK2) then
			local entities = constraint.GetAllConstrainedEntities(ent)

			-- Loop through the constained entities.
			for k, v in pairs(entities) do
				-- Do not allow touching world entities.
				if arista._internaldata.entities[v] then
					if doLog then arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (Map Entity Constrained).") end

					return false
				end
				-- Do not allow touching forbidden.
				if v:toolForbidden() then
					if doLog then arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (Forbidden Constrained).") end

					return false
				end
			end
		end

		-- Check if this entity is a player's ragdoll.
		if doLog and ent:isPlayerRagdoll() and not arista.utils.isAdmin(ply, true) then
			arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.USE, ply, " tried (and failed) to use tool ", tool, " on ", ent, " (Player Ragdoll).")

			return false
		end

		if doLog then arista.logs.event(arista.logs.E.LOG, arista.logs.E.USE, ply, " used tool ", tool, " on ", ent, ".") end
	elseif doLog then
		local hitPos = trace.HitPos
		local hitString = math.Round(hitPos.x, 1) .. ", " .. math.Round(hitPos.y, 1) .. ", " .. math.Round(hitPos.z, 1)

		arista.logs.event(arista.logs.E.LOG, arista.logs.E.USE, ply, " used tool ", tool, " on position ", hitString, ".")
	end

	-- Call the base class function.
	return self.BaseClass:CanTool(ply, trace, tool)
end
