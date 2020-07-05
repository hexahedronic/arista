SWEP.Author					=	"Chai_Latte";
SWEP.Base 					=	"weapon_base";
SWEP.PrintName 				= 	"Fishing Rod";

SWEP.ViewModel 				=	"models/oldprops/fishing_rod.mdl";
SWEP.ViewModelFlip 			=	false;
SWEP.UseHands				=	false;
SWEP.WorldModel 			= 	"models/oldprops/fishing_rod.mdl";
SWEP.SetHoldType 			= 	"melee";

SWEP.Weight 				= 	5;
SWEP.AutoSwitchTo 			= 	true;
SWEP.AutoSwitchFrom 		=	false;

SWEP.Slot 					=	0;
SWEP.SlotPos 				= 	0;

SWEP.DrawAmmo				=	false;
SWEP.DrawCrosshair 			= 	false;
 
SWEP.Spawnable 				= 	true;
SWEP.AdminSpawnable			=	true;

SWEP.Secondary.ClipSize		=	-1;
SWEP.Secondary.DefaultClip	=	-1;			
SWEP.Secondary.Ammo 		=	"none";
SWEP.Secondary.Automatic 	= 	false;

SWEP.Primary.ClipSize		=	-1;
SWEP.Primary.DefaultClip	=	-1;			
SWEP.Primary.Ammo 			=	"none";
SWEP.Primary.Automatic 		= 	false;

SWEP.ShouldDropOnDie 		=	false;


if CLIENT then
	local WorldModel = ClientsideModel(SWEP.WorldModel)

	-- Settings...
	WorldModel:SetSkin(1)
	WorldModel:SetNoDraw(true)

	function SWEP:DrawWorldModel()
		local _Owner = self:GetOwner()

		if (IsValid(_Owner)) then
            -- Specify a good position
			local offsetVec = Vector(-12, 0, -2)
			local offsetAng = Angle(-100, 90, 90)
			
			local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if !boneid then return end

			local matrix = _Owner:GetBoneMatrix(boneid)
			if !matrix then return end

			local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

			WorldModel:SetPos(newPos)
			WorldModel:SetAngles(newAng)

            WorldModel:SetupBones()
		else
			WorldModel:SetPos(self:GetPos())
			WorldModel:SetAngles(self:GetAngles())
		end

		WorldModel:DrawModel()
	end

	function SWEP:GetViewModelPosition(EyePos, EyeAng)
		self:SetRenderOrigin(self.Owner:EyePos());
		return self:LocalToWorld(Vector(11, -10, 12)), EyeAng + Angle(50, 0, 0);
	end

end

if SERVER then
	function SWEP:Initialize()
		self.Owner.RPresses = 0;
		self.Owner.catchIterator = 0;
	end


	function SWEP:PrimaryAttack()
		if(self.Owner.baitEnt) then
			self.Owner.baitEnt:Remove();
			self.Owner.baitEnt = nil;
		end
		self.Owner.baitEnt = ents.Create("prop_physics");
		self.Owner.baitEnt:SetOwner(self.Owner);
		self.Owner.baitEnt:SetModel("models/hunter/blocks/cube025x025x025.mdl");
		self.Owner.baitEnt:SetPos(self.Owner:EyePos() + self.Owner:EyeAngles():Forward() * 20 + Vector(0, 0, 100));
		--baitEnt:SetNoDraw(true);
		self.Owner.baitEnt:Spawn();
		self.Owner.baitEnt:AddCallback("PhysicsCollide", BaitCollide);
		local phys = self.Owner.baitEnt:GetPhysicsObject();
		phys:SetBuoyancyRatio(0.05);
		constraint.Rope(self.Owner, self.Owner.baitEnt, 0, 0, Vector(0, -1, 75), Vector(0, 0, 0), 600, 10, 0, 0.2, "cable/cable2", false);
		phys:SetVelocity(self.Owner:EyeAngles():Forward() * 1000 + self.Owner:EyeAngles():Up() * 500);
	end

	function SWEP:SecondaryAttack()
		ResetCast(self);
	end

	function SWEP:Holster()
		ResetCast(self);
		return true;
	end

	function SWEP:Think()
		if(self.Owner.baitEnt) then
			if(self.Owner.baitEnt:WaterLevel() > 0) then
				self.Owner.baitEnt:GetPhysicsObject():EnableMotion(false);
				math.randomseed(self.Owner:UserID());
				if(math.random(0, 10000) < 10) then
					self.Owner:ChatPrint("Caught a fish, spam R to catch!");
					catchIterator = (1/FrameTime() * 2);
					self.Owner:EmitSound("ambient/water/water_splash1.wav");
					util.ScreenShake(self.Owner:GetPos(), 2, 5, 2, 5000 )
				end
			end
			if(self.Owner.baitEnt:GetPos():DistToSqr(self.Owner:GetPos()) > 500000) then
				ResetCast(self);
			end
		end
		if(self.Owner.catchIterator > 0) then
			if(self.Owner:KeyPressed(8192)) then
				self.Owner.RPresses = self.Owner.RPresses + 1;
			else
				self.Owner.catchIterator = self.Owner.catchIterator - 1;
			end
		elseif(self.Owner.RPresses > 0) then
			if(self.Owner.RPresses > 5) then
				self.Owner:ChatPrint("You caught the fish!");
				ResetCast(self);
				self.Owner.catchIterator = 0;
				self.Owner.RPresses = 0;
			else
				self.Owner:ChatPrint("You didn't manage to catch the fish.");
				ResetCast(self);
				self.Owner.catchIterator = 0;
				self.Owner.RPresses = 0;
			end
		end
	end

	function BaitCollide(data, collider)
		local ent = collider.PhysObject:GetEntity()
		if(ent) then
			if(ent:WaterLevel() == 0) then
				ResetCast(ent);
			end
		end
	end

	function ResetCast(self)
		if SERVER then
			constraint.RemoveAll(self);
		end
		if self.Owner.baitEnt then self.Owner.baitEnt:Remove(); self.Owner.baitEnt = nil; end
		self.Owner.catchIterator = 0;
	end

end