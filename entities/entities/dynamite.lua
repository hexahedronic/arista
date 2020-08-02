AddCSLuaFile();

ENT.Type = "anim";
ENT.Base = "base_gmodentity";
 
ENT.PrintName = "Lasso Noose";
ENT.Author = "Chai_Latte";
ENT.Spawnable = false;
ENT.Released = true;

local HitSound = Sound("Flesh.ImpactHard");

if(CLIENT) then 
	function ENT:Draw()
		self:DrawModel()
	end

	return 
end

if(SERVER) then
	function ENT:Initialize()
		self:SetModel("models/weapons/w_dynamite_pack.mdl");
	    self:SetModelScale(1);

	    self:SetNoDraw(false);
		
		self:SetMoveType(MOVETYPE_NONE);
		self:SetSolid(SOLID_VPHYSICS);
		self:PhysicsInit(SOLID_VPHYSICS);
		
		local phys = self:GetPhysicsObject();
		if (phys and IsValid(phys)) then
			phys:Wake();
		end
	end
end