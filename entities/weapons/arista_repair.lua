if CLIENT then
	SWEP.PrintName = "Repair Tool"
	SWEP.Slot = 1
	SWEP.SlotPos = 3
	SWEP.DrawAmmo = false
	SWEP.IconLetter = "p"
	SWEP.DrawCrosshair = false

	function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
		draw.SimpleText(self.IconLetter, "CSSelectIcons", x + 0.56 * wide, y + tall * 0.27, Color(255, 220, 0, 255), TEXT_ALIGN_CENTER )
		self:PrintWeaponInfo(x + wide + 20, y + tall * 0.95, alpha)
	end

	killicon.AddFont("hands", "CSKillIcons", SWEP.IconLetter, Color(255, 80, 0, 255))
end

SWEP.Author = "Q2F2"
SWEP.Instructions = "Use LMB to repair vehicles."

SWEP.Slot = 5
SWEP.SlotPos = 35
SWEP.Weight = 1

SWEP.DrawAmmo = false

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = true

SWEP.DrawWeaponInfoBox = false
SWEP.Spawnable = false
SWEP.UseHands = true
SWEP.ViewModelFOV = 30

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.ViewModelFOV = 55
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Refire = 1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"


SWEP.SwingSound = "Weapon_Crowbar.Single"
SWEP.HitSound = "friends/friend_join.wav"

function SWEP:Deploy()
	self:SetWeaponHoldType("normal")
end

local range = 128 ^ 2

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Refire)

	-- Get an eye trace from the owner.
	local trace = self.Owner:GetEyeTrace()
	local ent = trace.Entity

	-- Check the hit position of the trace to see if it's close to us.
	if IsValid(ent) and ent:IsVehicle() and ent:Health() < 100 and self.Owner:GetPos():DistToSqr(trace.HitPos) <= range then
		if SERVER then
			ent:SetHealth(math.min(ent:Health() + 10, 100))
			self.Owner:giveMoney(15)
		end

		self:SendWeaponAnim(ACT_VM_HITCENTER)
		self:EmitSound(self.HitSound)
	else
		self:SendWeaponAnim(ACT_VM_MISSCENTER)
		self:EmitSound(self.SwingSound)
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end
