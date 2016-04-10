AddCSLuaFile()

-- Check if we're running on the client.
if CLIENT then
	SWEP.PrintName = "Electrical Baton"
	SWEP.Slot = 0
	SWEP.SlotPos = 0
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.IconLetter = "!"

	function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
		draw.SimpleText(self.IconLetter, "HL2MPTypeDeath", x + 0.5 * wide, y + tall * 0.3, Color(255, 220, 0, 255), TEXT_ALIGN_CENTER )
		self:PrintWeaponInfo(x + wide + 20, y + tall * 0.95, alpha)
	end
	killicon.AddFont("arista_baton", "HL2MPTypeDeath", SWEP.IconLetter, Color(255, 80, 0, 255))
end

-- Define some shared variables.
SWEP.Author	= "kuro, Lexi, Q2F2 et al." --Admitedly, mostly made up of kudo's parts.
SWEP.Instructions = "Primary Fire: Knock Out. Use+Primary Fire: Damage\nSecondary Fire: Arrest/breach door."
SWEP.Purpose = "General Purpous Electrical Baton"

-- Set the view model and the world model to nil.
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"

-- Set the animation prefix and some other settings.
SWEP.AnimPrefix	= "stunstick"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModelFOV	= 50

-- Set the primary fire settings.
SWEP.Primary.Delay = 0.75
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

-- Set the secondary fire settings.
SWEP.Secondary.Delay = 0.75
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= ""

-- Set the iron sight positions (pointless here).
SWEP.IronSightPos = Vector(0, 0, 0)
SWEP.IronSightAng = Vector(0, 0, 0)
SWEP.NoIronSightFovChange = true
SWEP.NoIronSightAttack = true

-- Called when the SWEP is initialized.
function SWEP:Initialize()
	self:SetWeaponHoldType("melee")
end

local dist = 96 ^ 2

-- Do the SWEP's hit effects. <-- Credits to kuromeku
function SWEP:doHitEffects(sound)
	local trace = self.Owner:GetEyeTrace()

	-- Check if the trace hit or it hit the world.
	if (trace.Hit or trace.HitWorld) and self.Owner:GetPos():DistToSqr(trace.HitPos) <= dist then
		local ent = trace.Entity

		if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
			self:SendWeaponAnim(ACT_VM_HITCENTER)
			self:EmitSound(sound or "weapons/stunstick/stunstick_fleshhit"..math.random(1, 2)..".wav")
		elseif IsValid(ent) and ent:isPlayerRagdoll() then
			self:SendWeaponAnim(ACT_VM_HITCENTER)
			self:EmitSound(sound or "weapons/stunstick/stunstick_fleshhit"..math.random(1, 2)..".wav")
		else
			self:SendWeaponAnim(ACT_VM_HITCENTER)
			self:EmitSound(sound or "weapons/stunstick/stunstick_impact"..math.random(1, 2)..".wav")
		end

		-- Create new effect data.
		local effectData = EffectData()

		-- Set some information about the effect.
		effectData:SetStart(trace.HitPos)
		effectData:SetOrigin(trace.HitPos)
		effectData:SetScale(32)

		-- Create the effect.
		util.Effect("StunstickImpact", effectData)
	else
		self:SendWeaponAnim(ACT_VM_HITCENTER)
		self:EmitSound("weapons/stunstick/stunstick_swing1.wav")
	end
end

local dist2 = 128 ^ 2

function SWEP:getPlayer(ent)
	if self.Owner.LagCompensation then
		self.Owner:LagCompensation(true)
	end

	local tr = self.Owner:GetEyeTrace()

	if self.Owner.LagCompensation then
		self.Owner:LagCompensation(false)
	end

	local ent = tr.Entity

	if not IsValid(ent) or self.Owner:GetPos():DistToSqr(tr.HitPos) > dist2 then
		return false
	elseif IsValid(ent) and ent:isPlayerRagdoll() then -- Player Ragdoll
		ent = ent:getRagdollPlayer()
	elseif ent:IsVehicle() then
		if ent:GetClass() ~= "prop_vehicle_jeep" and ent:validDriver() then
			ent = ent:GetDriver()
		else
			tr = util.QuickTrace(tr.HitPos, tr.Normal * 512, ent)

			if IsValid(tr.Entity) then
				ent = tr.Entity

				if ent:IsVehicle() and ent:GetClass() == "prop_vehicle_prisoner_pod" and ent:validDriver() then
					ent = ent:GetDriver()
				elseif not (ent:IsPlayer() and ent:InVehicle()) then
					return false
				end
			end
		end
	end

	if ent:IsPlayer() and not (ent:Alive() and (ent:GetMoveType() ~= MOVETYPE_NOCLIP or ent:InVehicle())) then
		return false
	end

	return ent
end
-- Called when the player attempts to primary fire.
function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	-- Set the animation of the owner and weapon and play the sound.
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:doHitEffects()

	-- Check if we're running on the client.
	if (CLIENT) then return end

	local player = self:getPlayer(true)

	-- Check to see if the entity is a player and that it's close to the owner.
	if player then
		if not player:IsPlayer() then
			--if GM.Config["Contraband"][player:GetClass()] then -- Theese lets us remove contra with a single baton blast
			--	player:TakeDamage(player:Health(),self.Owner,self.Owner)
			--end
			-- todo: contra
		elseif not player:Alive() then
			return false
		elseif self.Owner:KeyDown(IN_USE) and gamemode.Call("PlayerCanStun", self.Owner, player) ~= false then
			local normal = (player:GetPos() - self.Owner:GetPos())
			normal:Normalize()

			local push = 256 * normal

			-- Set the velocity of the player.
			player:SetLocalVelocity(push)
			player:TakeDamage(10, self.Owner, self.Owner)
		elseif not player:isUnconscious() and gamemode.Call("PlayerCanKnockOut", self.Owner, player) ~= false then
			if player:InVehicle() then player:ExitVehicle() end

			player:knockOut(12)

			if player.ragdoll then
				player.ragdoll.time = CurTime() + 2
			end

			player:setAristaVar("stunned", true)

			-- Let the administrators know that this happened.
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, self.Owner:Name(), "(", self.Owner:SteamID(), ") stunned ", player:Name(), ".")

			-- Call a hook.
			gamemode.Call("PlayerKnockedOut", player, self.Owner)
		elseif player:isUnconscious() and gamemode.Call("PlayerCanWakeUp", self.Owner, player) ~= false then
			player:wakeUp()

			-- Let the administrators know that this happened.
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, self.Owner:Name(), "(", self.Owner:SteamID(), ") woke up ", player:Name(), ".")

			-- Call a hook.
			gamemode.Call("PlayerWokenUp", player, self.Owner)
		end
	end
end

-- Called when the player attempts to secondary fire.
function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	-- Set the animation of the owner and weapon and play the sound.
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:doHitEffects()

	-- Check if we're running on the client.
	if (CLIENT) then return end

	local player = self:getPlayer(true)

	-- Check to see if the entity is a player and that it's close to the owner.
	if player and player:IsPlayer() then
		if player:isArrested() and gamemode.Call("PlayerCanUnarrest", self.Owner, player) ~= false then
			if player:isUnconscious() then player:wakeUp() end

			player:unArrest()

			-- Let the administrators know that this happened.
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, self.Owner:Name(), "(", self.Owner:SteamID(), ") unarrested ", player:Name(), ".")

			-- Call a hook.
			gamemode.Call("PlayerUnarrest", self.Owner, player)
		elseif not player:isArrested() and gamemode.Call("PlayerCanArrest", self.Owner, player) ~= false then
			if player:isUnconscious() then player:wakeUp() end
			if player:InVehicle() then player:ExitVehicle() end

			player:arrest()

			-- Let the administrators know that this happened.
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, self.Owner:Name(), "(", self.Owner:SteamID(), ") arrested ", player:Name(), ".")

			-- Call a hook.
			gamemode.Call("PlayerArrest", self.Owner, player)
		end
	elseif arista.entity.isDoor(player, true) and gamemode.Call("PlayerCanRamDoor", GAMEMODE, self.Owner, player) ~= false then
		arista.entity.openDoor(player, 0.25, true, true, gamemode.Call("PlayerCanJamDoor",GAMEMODE,self.Owner, player))
	end
end
