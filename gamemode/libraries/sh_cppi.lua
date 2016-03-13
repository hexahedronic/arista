function GM:CPPIAssignOwnership(ply, ent, uid)
end

function GM:CPPIFriendsChanged(ply, friends)
end

if CPPI then return end

CPPI = {}
CPPI.CPPI_DEFER = 100100
CPPI.CPPI_NOTIMPLEMENTED = 7080

function CPPI:GetName()
	return "arista CPPI Fallback"
end

function CPPI:GetVersion()
	return "1.0"
end

function CPPI:GetInterfaceVersion()
	return 1.3
end

function CPPI:GetNameFromUID(uid)
	if UID == nil then return nil end

	local ply = player.GetByUniqueID(UID)

	if not (ply and IsValid(ply)) then return nil end

	return ply:Name()
end

local player = FindMetaTable("Player")
function player:CPPIGetFriends()
	return CPPI.CPPI_NOTIMPLEMENTED
end

local entity = FindMetaTable("Entity")
function entity:CPPIGetOwner()
	return NULL, CPPI.CPPI_NOTIMPLEMENTED
end

if SERVER then
	function entity:CPPISetOwner(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPISetOwnerUID(UID)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanTool(ply, tool)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanPhysgun(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanPickup(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanPunt(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanUse(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanDamage(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanDrive(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanProperty(ply, property)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entity:CPPICanEditVariable(ply, key, val, edit)
		return CPPI.CPPI_NOTIMPLEMENTED
	end
end
