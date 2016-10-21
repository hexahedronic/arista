AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Fuel Pump"
ENT.Author = "Lexi, Q2F2"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:CanTool(ply)
	return ply:IsSuperAdmin()
end

function ENT:PhysgunPickup(ply)
	return ply:IsSuperAdmin()
end

if CLIENT then return end

-- This is called when the entity initializes.
function ENT:Initialize()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_BBOX)
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:CPPISetOwner(game.GetWorld())

	-- Get the physics object of the entity.
	local physicsObject = self:GetPhysicsObject()

	-- Check if the physics object is a valid entity.
	if IsValid(physicsObject) then
		physicsObject:EnableMotion(false)
	end
end

-- Called when the entity is used.
function ENT:Use(activator, caller)
end

function ENT:Think()
	if not GAMEMODE:GetPlugin("Vehicles") then
			self:NextThink(CurTime() + 100)
	return true end
	
	for k, v in ipairs(ents.FindInSphere(self:GetPos(), 128)) do
		if v:IsVehicle() and not v:getAristaVar("engineOn") then
			local petrol = v:getAristaVar("petrol")
			
			if petrol and petrol < 100 then
				v:setAristaVar("petrol", math.min(petrol + (arista.config.plugins.vehiclesPumpAmt or 1), 100))
			end
		end
	end
	
	self:NextThink(CurTime() + 0.5)
	return true
end

