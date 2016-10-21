ITEM.name					= "Lockpick"
ITEM.plural				= "Lockpicks"
ITEM.size					= 1
ITEM.cost					= 650
ITEM.model				= "models/props_c17/FurnitureDrawer001a_Shard01.mdl"
ITEM.batch				= 5
ITEM.store				= true
ITEM.description	= "A single-use device used to open a locked door."
ITEM.base					= "item"
ITEM.noVehicles		= true

if CLIENT then
	arista.lang:Add("AL_INVALID_DOOR", {
		EN = "That is not a valid door!",
	})

	arista.lang:Add("AL_CANNOT_PICK", {
		EN = "You are unable to pick this lock.",
	})
	
	arista.lang:Add("AL_NOT_LOCKED", {
		EN = "That door is not locked.",
	})
end

local function conditional(ply, door, plypos)
	return ply:IsValid() and door:IsValid() and door:isLocked() and ply:GetPos() == plypos
end

local function success(ply, door)
	ply:emote("stands up and unlocks the door.")
	
	door._picking = false
	ply._picking = false
	
	door:unLock()
	gamemode.Call("LockPicked", door, ply)
end

local function failure(ply, door)
	if IsValid(door) then
		door._picking = false
	end
	
	if IsValid(ply) then
		ply:emote("gives up and drops the lockpick.")
		arista.item.items["lockpick"]:make(ply:GetPos())
		
		ply._picking = false
	end
end

-- Called when a player uses the item.
function ITEM:onUse(ply)
	local tr = ply:GetEyeTraceNoCursor()
	local door = tr.Entity

	if not (door and IsValid(door) and arista.entity.isDoor(door)
	and ply:GetShootPos():Distance(tr.HitPos) <= 80) then
		ply:notify("AL_INVALID_DOOR")
	return false end
	
	if gamemode.Call("CanLockPick", door, ply) == false or door._picking or ply._picking then
		ply:notify("AL_CANNOT_PICK")
	return false end
	
	if not door:isLocked() then
		ply:notify("AL_NOT_LOCKED")
	return false end

	ply:emote("ducks down and starts using a lockpick to open the door.")
	
	door._picking = true
	ply._picking = true
		
	arista.timer.conditional(ply:UniqueID() .. " Picking Timer", arista.config.vars.pickingTime, conditional, success, failure, ply, door, ply:GetPos())
	return true
end
