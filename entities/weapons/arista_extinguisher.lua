
AddCSLuaFile()
AddCSLuaFile( "effects/rb655_extinguisher_effect.lua" )

if ( SERVER ) then resource.AddWorkshop( "104607228" ) end

SWEP.PrintName = "Extinguisher"
SWEP.Author = "Robotboy655 & Q2F2"
SWEP.Contact = "robotboy655@gmail.com"
SWEP.Purpose = "To extinguish fire!"
SWEP.Category = "Robotboy655's Weapons"
SWEP.Instructions = "Shoot into a fire, to extinguish it."

SWEP.Slot = 5
SWEP.SlotPos = 35
SWEP.Weight = 1

SWEP.DrawAmmo = false

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = true

SWEP.DrawWeaponInfoBox = false
SWEP.Spawnable = false
SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/c_fire_extinguisher.mdl"
SWEP.ViewModelFOV = 55
SWEP.WorldModel = "models/weapons/w_fire_extinguisher.mdl"
SWEP.HoldType = "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "NextIdle" )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() )

	self:Idle()

	return true
end

function SWEP:DoEffect( effectscale )

	local effectdata = EffectData()
	effectdata:SetAttachment( 1 )
	effectdata:SetEntity( self.Owner )
	effectdata:SetOrigin( self.Owner:GetShootPos() )
	effectdata:SetNormal( self.Owner:GetAimVector() )
	effectdata:SetScale( effectscale or 1 )
	util.Effect( "rb655_extinguisher_effect", effectdata )

end

function SWEP:DoExtinguish( pushforce, effectscale )
	--if ( self:Ammo1() < 1 ) then return end

	if ( CLIENT ) then
		if ( self.Owner == LocalPlayer() ) then self:DoEffect( effectscale ) end -- FIXME
		return
	end

	--self:TakePrimaryAmmo( 1 )

	effectscale = effectscale or 1
	pushforce = pushforce or 0

	local tr
	if ( self.Owner:IsNPC() ) then
		tr = util.TraceLine( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 16384,
			filter = self.Owner
		} )
	else
		tr = self.Owner:GetEyeTrace()
	end

	local pos = tr.HitPos

	for id, prop in pairs( ents.FindInSphere( pos, 80 ) ) do
		if ( prop:GetPos():Distance( self:GetPos() ) < 256 ) then
			if ( prop:IsValid() and math.random( 0, 1000 ) > 500 ) then
				if ( prop:IsOnFire() ) then prop:Extinguish() end

				local class = prop:GetClass()
				if ( string.find( class, "ent_minecraft_torch" ) and prop:GetWorking() ) then
					prop:SetWorking( false )
				elseif ( string.find( class, "env_fire" ) ) then -- Gas Can support. Should work in ravenholm too.
					prop:Fire( "Extinguish" )
				elseif class == "arista_fire" then
					prop:HitByExtinguisher(self.Owner, false)
				end
			end

			if ( pushforce > 0 ) then
				local physobj = prop:GetPhysicsObject()
				if ( IsValid( physobj ) ) then
					physobj:ApplyForceOffset( self.Owner:GetAimVector() * pushforce, pos )
				end
			end
		end
	end

	for id, prop in pairs( ents.FindInSphere( self.Owner:GetPos(), 80 ) ) do
		if ( prop:GetPos():Distance( self:GetPos() ) < 256 ) then
			if ( prop:IsValid() and math.random( 0, 1000 ) > 500 ) then

				local class = prop:GetClass()
				if class == "arista_fire" then
					prop:HitByExtinguisher(self.Owner, false)
				end
			end
		end
	end

	self:DoEffect( effectscale )

end

function SWEP:PrimaryAttack()
	if ( self:GetNextPrimaryFire() > CurTime() ) then return end

	if ( IsFirstTimePredicted() ) then

		self:DoExtinguish( 196, 1 )

		if ( SERVER ) then

			if ( self.Owner:KeyPressed( IN_ATTACK ) || !self.Sound ) then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

				self.Sound = CreateSound( self.Owner, Sound( "weapons/extinguisher/fire1.wav" ) )

				self:Idle()
			end

			--if ( self:Ammo1() > 0 ) then if ( self.Sound ) then self.Sound:Play() end end
			if ( SERVER and self.Sound and not self.Sound:IsPlaying() ) then self.Sound:Play() end

		end
	end

	self:SetNextPrimaryFire( CurTime() + 0.05 )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:PlaySound()
	self:EmitSound( "weapons/extinguisher/release1.wav", 100, math.random( 95, 110 ) )
end

function SWEP:Think()

	if ( self:GetNextIdle() > 0 && CurTime() > self:GetNextIdle() ) then

		self:DoIdleAnimation()
		self:Idle()

	end

	if ( self:GetNextSecondaryFire() > CurTime() || CLIENT ) then return end

	--[[if ( ( self.NextAmmoReplenish or 0 ) < CurTime() ) then
		local ammoAdd = 0
		if ( self.Owner:WaterLevel() > 1 ) then ammoAdd = 25 end

		self.Owner:SetAmmo( math.min( self:Ammo1() + ammoAdd, self.Primary.DefaultClip * 2 ), self:GetPrimaryAmmoType() )
		self.NextAmmoReplenish = CurTime() + 0.1
	end]]

	if ( self.Owner:KeyReleased( IN_ATTACK ) || ( !self.Owner:KeyDown( IN_ATTACK ) && self.Sound ) ) then

		self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )

		if ( self.Sound ) then
			self.Sound:Stop()
			self.Sound = nil
			if ( self:Ammo1() > 0 ) then
				self:PlaySound()
				if ( !game.SinglePlayer() ) then self:CallOnClient( "PlaySound", "" ) end
			end
		end

		self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() )
		self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() )

		self:Idle()

	end
end

function SWEP:Holster( weapon )
	if ( CLIENT ) then return end

	if ( self.Sound ) then
		self.Sound:Stop()
		self.Sound = nil
	end

	return true
end

function SWEP:DoIdleAnimation()
	if ( self.Owner:KeyDown( IN_ATTACK ) && self:Ammo1() > 0 ) then self:SendWeaponAnim( ACT_VM_IDLE_1 ) return end
	if ( self.Owner:KeyDown( IN_ATTACK ) && self:Ammo1() < 1 ) then self:SendWeaponAnim( ACT_VM_IDLE_EMPTY ) return end
	self:SendWeaponAnim( ACT_VM_IDLE )
end

function SWEP:Idle()

	self:SetNextIdle( CurTime() + self:GetAnimationTime() )

end

function SWEP:GetAnimationTime()
	local time = self:SequenceDuration()
	if ( time == 0 && IsValid( self.Owner ) && !self.Owner:IsNPC() && IsValid( self.Owner:GetViewModel() ) ) then time = self.Owner:GetViewModel():SequenceDuration() end
	return time
end

if ( SERVER ) then return end

SWEP.WepSelectIcon = Material( "rb655_extinguisher_icon.png" )

function SWEP:DrawWeaponSelection( x, y, w, h, a )
	surface.SetDrawColor( 255, 255, 255, a )
	surface.SetMaterial( self.WepSelectIcon )

	local size = math.min( w, h ) - 32
	surface.DrawTexturedRect( x + w / 2 - size / 2, y + h * 0.05, size, size )
end
