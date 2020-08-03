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
	local function Ragdoll(self, ent)
		if(not IsValid(ent) or IsValid(ent) and ent:Health() <= 0) then return end

		if (ent:IsNPC()) then
		    ent:ClearCondition(68);
		    ent:SetCondition(67);
		end

		ent:SetNWBool("chai_lassoed", true);

		local ragdoll = ents.Create("prop_ragdoll");
		if (not IsValid(ragdoll)) then return end

		ragdoll:SetModel(ent:GetModel());
		ragdoll:SetPos(ent:GetPos());
		ragdoll:SetAngles(ent:GetAngles());
		ragdoll:SetVelocity(ent:GetVelocity());
		ragdoll:Spawn();

		ragdoll:SetHealth(ent:Health());
		ragdoll.OwnerEnt = ent;
		ent:SetNWEntity("chai_lassoed_ragdoll", ragdoll);

		local num = ragdoll:GetPhysicsObjectCount() - 1;
		local v = ent:GetVelocity();

		for i=0, num do
		    local bone = ragdoll:GetPhysicsObjectNum(i);

		    if (IsValid(bone)) then
		        local bp, ba = ent:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i));
		        if (bp and ba) then
		            bone:SetPos(bp);
		            bone:SetAngles(ba);
		        end

		        bone:SetVelocity(v);
		    end
		end
		self.rag = ragdoll;
		if(ent:IsPlayer()) then
			sound.Play(HitSound, ent:GetPos());
			ent.WeaponsTable = {};
			for k,v in pairs(ent:GetWeapons()) do
				table.insert(ent.WeaponsTable, v:GetClass());
			end
			ent:Spectate(OBS_MODE_CHASE);
			ent:SpectateEntity(ragdoll);
			ent:DrawViewModel(false);
			local weapon = ent:GetActiveWeapon()
   			if (IsValid(weapon)) then
       			 weapon:SetNoDraw(true);
       		end
       		ent:StripWeapons();
		end
		return ragdoll;
	end

	function ENT:Initialize()
		self:SetModel("models/hunter/blocks/cube025x025x025.mdl");
	    self:SetModelScale(1);
	    self:SetMaterial("models/debug/debugwhite");
	    self:SetColor(Color( 255, 100 ,100 ));

	    self:SetNoDraw(false); --CHANGE TO TRUE ON RELEASE
		
		self:SetMoveType(MOVETYPE_VPHYSICS);
		self:SetSolid(SOLID_VPHYSICS);
		self:PhysicsInit(SOLID_VPHYSICS);
		
		local phys = self:GetPhysicsObject();
		if (phys and IsValid(phys)) then
			phys:Wake();
		end
	end

	function ENT:PhysicsCollide(data, phys) 
		local ent = data.HitEntity;
		local ply = phys:GetEntity():GetOwner();
		if((ent:IsPlayer()) and not ent:GetNWBool("chai_lassoed", false)) then
			local rag = Ragdoll(self, ent);
			hook.Call("Chai_LassoHit_"..ply:SteamID64(), nil, unpack({rag, ent, ply}));
			self:SetCollisionGroup(COLLISION_GROUP_NONE);
			self.hit = ent; 
		end
		self.Owner:DrawViewModel(true);
		self:Remove();
	end

	/*
	function ENT:Think()	     
		if(self:GetOwner():GetNWBool("chai_lassoed", false)) then
			self:GetOwner():SetPos(self.rag:GetPos());
			self:NextThink( CurTime() ) 
			return true;
		end		
	end
	*/
end