hook.Add("Initialize", "test", function()
	game.AddAmmoType(
	{
		name = "chai_dynamite",
		dmgtype = DMG_SLASH,
		force = 0,
		npcdmg = 100,
		plydmg = 0,
		maxcarry = -1,
	});
	game.BuildAmmoTypes();
end);

SWEP.Author					=	"Chai_Latte";
SWEP.Base 					=	"weapon_base";
SWEP.PrintName 				= 	"Dynamite";
SWEP.Category 				= 	"Chai's SWEPs"

SWEP.ViewModel 				=	"models/weapons/v_dynamite_pack.mdl";
SWEP.ViewModelFlip 			=	false;
SWEP.UseHands				=	true;
SWEP.WorldModel 			= 	"models/weapons/w_dynamite_pack.mdl";
SWEP.SetHoldType 			= 	"melee";

SWEP.Weight 				= 	5;
SWEP.AutoSwitchTo 			= 	true;
SWEP.AutoSwitchFrom 		=	false;

SWEP.Slot 					=	0;
SWEP.SlotPos 				= 	0;

SWEP.DrawAmmo				=	true;
SWEP.DrawCrosshair 			= 	false;
 
SWEP.Spawnable 				= 	true;
SWEP.AdminSpawnable			=	true;

SWEP.Secondary.ClipSize		=	-1;
SWEP.Secondary.DefaultClip	=	-1;			
SWEP.Secondary.Ammo 		=	"none";
SWEP.Secondary.Automatic 	= 	false;

SWEP.Primary.ClipSize		=	1000000;
SWEP.Primary.DefaultClip	=	1;			
SWEP.Primary.Ammo 			=	"chai_dynamite";
SWEP.Primary.Automatic 		= 	false;	

SWEP.ShouldDropOnDie 		=	false;


local SwingSound = Sound("WeaponFrag.Throw");
	
if CLIENT then
	function SWEP:GetViewModelPosition(EyePos, EyeAng)
	end
	function SWEP:PrimaryAttack()
		return false
	end
end

if SERVER then
	function SWEP:PrimaryAttack()
		if(self:Clip1() <= 0) then return end;
		local ply = self.Owner;
		local trace = ply:GetEyeTrace();
		if(trace and trace.Entity and IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_physics" and ply:GetPos():DistToSqr(trace.HitPos) < 8500) then
			self.Owner.dyno = ents.Create("dynamite");
			self.Owner.dyno:SetParent(trace.Entity);
			self.Owner.dyno:SetPos(trace.HitPos);
			self.Owner.dyno:Spawn();

			timer.Simple(self.fuse or 5, function()
				if(trace.Entity and self.Owner.dyno and IsValid(trace.Entity) and IsValid(self.Owner.dyno)) then
					local explode = ents.Create( "env_explosion" ) -- creates the explosion
					explode:SetPos( self.Owner.dyno:GetPos() ) -- this creates the explosion where you were looking
					explode:SetOwner( self.Owner ) -- this sets you as the person who made the explosion
					explode:Spawn() -- this actually spawns the explosion
					explode:SetKeyValue( "iMagnitude", "220" ) -- the magnitude
					explode:Fire( "Explode", 0, 0 )
					explode:EmitSound( "weapon_AWP.Single", 400, 400 )

					self.Owner.dyno:Remove();
					trace.Entity:Remove();
				end
			end)
			self:SetClip1(self:Clip1() - 1);
		elseif(trace and trace.Entity and IsValid(trace.Entity) and trace.Entity:GetClass() == "player" and ply:GetPos():DistToSqr(trace.HitPos) < 8500) then
			self.Owner.dyno = ents.Create("dynamite");
			self.Owner.dyno:SetParent(trace.Entity);
			self.Owner.dyno:SetPos(trace.HitPos);
			self.Owner.dyno:Spawn();

			timer.Simple(self.fuse or 5, function()
				if(trace.Entity and self.Owner.dyno and IsValid(trace.Entity) and IsValid(self.Owner.dyno)) then
					local explode = ents.Create( "env_explosion" ) -- creates the explosion
					explode:SetPos( self.Owner.dyno:GetPos() ) -- this creates the explosion where you were looking
					explode:SetOwner( self.Owner ) -- this sets you as the person who made the explosion
					explode:Spawn() -- this actually spawns the explosion
					explode:SetKeyValue( "iMagnitude", "220" ) -- the magnitude
					explode:Fire( "Explode", 0, 0 )
					explode:EmitSound( "weapon_AWP.Single", 400, 400 )

					self.Owner.dyno:Remove();
				end
			end)
			self:SetClip1(self:Clip1() - 1);
		end
	end

	function SWEP:SecondaryAttack()
		local ply = self.Owner;
		if(not self.fuse) then self.fuse = 5; end
		if(self.fuse < 30) then
			self.fuse = self.fuse + 5;
		else
			self.fuse = 5;
		end
		ply:ChatPrint("Fuse set to ".. self.fuse .. " seconds.")
	end
end

