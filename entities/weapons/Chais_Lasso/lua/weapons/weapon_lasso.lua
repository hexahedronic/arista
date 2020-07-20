AddCSLuaFile();

SWEP.Author					=	"Chai_Latte";
SWEP.Base 					=	"weapon_base";
SWEP.PrintName 				= 	"Lasso";

SWEP.ViewModel 				=	"models/weapons/v_lasso.mdl";
SWEP.ViewModelFlip 			=	false;
SWEP.UseHands				=	true;
SWEP.WorldModel 			= 	"models/weapons/w_lasso.mdl";
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

local SwingSound = Sound("WeaponFrag.Throw");

if CLIENT then
	local WorldModel = ClientsideModel(SWEP.WorldModel)
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
		--self:SetRenderOrigin(self.Owner:EyePos());
		--return self:LocalToWorld(Vector(11, -10, 12)), EyeAng + Angle(50, 0, 0);
	end
end

if SERVER then
	util.AddNetworkString("LassoHUD");
	function SWEP:Deploy()
		hook.Add("Chai_LassoHit_"..self.Owner:SteamID64(), "chai", function(rag, ent, ply)
			constraint.RemoveAll(ply); 
			timer.Simple(0.1, function()
				constraint.Winch(ply, ply, rag, 0, 0, Vector(0, 0, 50), Vector(0, 0, 0), 0.6, KEY_PAGEUP, KEY_PAGEDOWN, 100, 100, "cable/rope", false);
			end)
			self.ply = ent;
			net.Start("LassoHUD");
			net.Send(ply);
			timer.Simple(20, function()
				UnLasso(ent, self);
			end)
		end)
	end
	function SWEP:PrimaryAttack()
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self.Owner:DrawViewModel(false);
		sound.Play(SwingSound, self.Owner:GetPos())
		if(self.ply) then
			UnLasso(self.ply, self);
		end
		local ply = self.Owner;
		self.noose = ents.Create("lasso_noose");
		self.noose:SetRenderMode( RENDERMODE_NONE );
		self.noose:DrawShadow( false )
		self.noose:SetNotSolid( true )
		self.noose:SetPos(ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1")) + ply:EyeAngles():Forward() * 50);
		self.noose:Spawn();
		self.noose:SetOwner(self.Owner);
		self.noose:GetPhysicsObject():SetMass(100);
		self.noose:GetPhysicsObject():AddVelocity((ply:EyeAngles():Forward() * 1000) + ply:EyeAngles():Up() * 100);
		constraint.Rope(ply, self.noose, 0, 0, Vector(0, 0, 50), Vector(0, 0, 0), 800, 0, 0, 1, "cable/rope", false)
		self:SetNextPrimaryFire(CurTime() + 2);
	end

	function SWEP:SecondaryAttack()
		if(self.ply) then
			UnLasso(self.ply, self);
		end
	end
	function SWEP:Holster()
		if(self.ply) then
			UnLasso(self.ply, self);
		end
		return true;
	end
	function SWEP:Reload()
		if(self.ply) then
			UnLasso(self.ply, self);
		end
	end

	function UnLasso(ply, self)
		self.Owner:DrawViewModel(true);
		print(self.Owner);
		if(ply:GetNWBool("chai_lassoed")) then
			ply:UnSpectate();
			local rag = ply:GetNWEntity("chai_lassoed_ragdoll");
			ply:SetNWBool("chai_lassoed", false);
			ply:Spawn();
			ply:SetPos(rag:GetPos());
			ply:DrawViewModel(true);
			rag:Remove();
			constraint.RemoveAll(ply);
			self.ply = nil;
			ply:StripWeapons();
			if(ply.WeaponsTable) then
				for k,v in pairs(ply.WeaponsTable) do
					ply:Give(v);
				end
			end
			net.Start("LassoHUD");
			net.Send(self.Owner);
		end
	end
end

