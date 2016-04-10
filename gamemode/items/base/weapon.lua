include("item.lua")

ITEM.weapon			= true
ITEM.noVehicles	= true

local function conditional(ply, pos)
	return ply:IsValid() and ply:GetPos() == pos
end
local function success(ply, _, self)
	if not ply:IsValid() then return end

	ply:emote(arista.config.timers["equipmessage"]["Final"]:format(self.weaponType))
	ply._equipping = false

	ply:Give(self.uniqueID)
	ply:SelectWeapon(self.uniqueID)

	local counts = ply:getAristaVar("gunCounts")
		counts[self.weaponType] = counts[self.weaponType] + 1
	ply:setAristaVar("gunCounts", counts)

	arista.inventory.update(ply, self.uniqueID, -1)

	if self.onEquip then
		self:onEquip(ply)
	end
end

local function failure(ply)
	if not ply:IsValid() then return end

	ply:emote(arista.config.timers["equipmessage"]["Abort"])
	ply._equipping = false
end

function ITEM:onUse(ply)
	if ply:HasWeapon(self.uniqueID) then
		ply:SelectWeapon(self.uniqueID)
	return false end

	if self.ammo and not tobool(ply:GetAmmoCount(self.ammo)) then
		ply:notify("AL_CANNOT_NOAMMO")
	return false end

	if not (self.weaponType and arista.config.vars.maxWeapons[self.weaponType]) then
		ply:Give(self.uniqueID)
		ply:SelectWeapon(self.uniqueID)
	return true end

	local deploy = ply:getAristaVar("nextDeploy")
	if deploy and deploy > CurTime() then
		ply:notify("You must wait another %s before equipping another weapon!", string.ToMinutesSeconds(deploy - CurTime()))
	return false end

	local counts = ply:getAristaVar("gunCounts")
		counts[self.weaponType]	= counts[self.weaponType] or 0
	ply:setAristaVar("gunCounts", counts)

	if counts[self.weaponType] >= arista.config.vars.maxWeapons[self.weaponType] then
		ply:notify("You have too many %s weapons equipped!", self.weaponType)
	return false end

	ply._equipping	= true

	ply:emote(arista.config.timers["equipmessage"]["Start"])

	arista.timer.conditional(ply:UniqueID() .. " equipping", arista.config.timers["equiptime"][self.weaponType], conditional, success, failure, ply, ply:GetPos(), self);
	return false -- Removing the weapon from your inventory is handled in the timer
end
