AddCSLuaFile()
SWEP.PrintName = "Hands"

-- Check if we're running on the client.
if CLIENT then
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.IconLetter = "H"
	SWEP.DrawCrosshair = false

	function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
		draw.SimpleText(self.IconLetter, "CSSelectIcons", x + 0.56 * wide, y + tall * 0.27, Color(255, 220, 0, 255), TEXT_ALIGN_CENTER)
		self:PrintWeaponInfo(x + wide + 20, y + tall * 0.95, alpha)
	end

	killicon.AddFont("hands", "CSKillIcons", SWEP.IconLetter, Color(255, 80, 0, 255))
end

-- Define some shared variables.
SWEP.Author	= "Lexi & Q2F2"

-- Bitchin smart lookin instructions o/
local title_color = "<color=230,230,230,255>"
local text_color = "<color=150,150,150,255>"
local end_color = "</color>"
SWEP.Instructions =	end_color..title_color.."Primary Fire:\t\t"..						end_color..text_color.." Punch / Throw\n"..
										end_color..title_color.."Secondary Fire:\t\t"..					end_color..text_color.." Knock / Pick Up / Drop\n"..
										end_color..title_color.."Sprint+Primary Fire:\t"..		end_color..text_color.." Lock\n"..
										end_color..title_color.."Sprint+Secondary Fire:\t"..	end_color..text_color.." Unlock"
SWEP.Purpose = "Picking stuff up, knocking on doors and punching people."

-- Set the view model and the world model to nil.
SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

-- Set the animation prefix and some other settings.
SWEP.AnimPrefix	= "admire"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands	= true
SWEP.ViewModelFOV	= 52

-- Set the primary fire settings.
SWEP.Primary.Damage = 1.5
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Force = 5
SWEP.Primary.PunchAcceleration = 100
SWEP.Primary.ThrowAcceleration = 200
SWEP.Primary.Super = false
SWEP.Primary.Refire = 1
SWEP.Primary.Sound = Sound("WeaponFrag.Throw")
SWEP.Primary.HolsterTime = 1.75

-- Set the secondary fire settings.
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= ""

-- Set the iron sight positions (pointless here).
SWEP.IronSightPos = Vector(0, 0, 0)
SWEP.IronSightAng = Vector(0, 0, 0)
SWEP.NoIronSightFovChange = true
SWEP.NoIronSightAttack = true
SWEP.heldEnt = NULL

-- To determine holster
SWEP.NextHolster = 0

-- Called when the SWEP is initialized.
function SWEP:Initialize()
	self.Primary.NextSwitch = CurTime()
	self:SetWeaponHoldType("normal")
	self.stamina = GAMEMODE:GetPlugin("stamina")
	self.Owner:SetNWBool("raisedFists", false)
end

function SWEP:Deploy()
	local vm = self.Owner:GetViewModel()
	
	if self.Owner:GetNWBool("raisedFists") then
		if SERVER then
			vm:SetNoDraw(false)
			vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
		end
		
		self:SetWeaponHoldType("fist")	
		self:UpdateNextIdle()	
	else	
		if SERVER then
			vm:SetNoDraw(true)
		end
		
		self:SetWeaponHoldType("normal")
		self:UpdateNextIdle()	
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 1, "NextIdle")
end

function SWEP:UpdateNextIdle()
	local vm = self.Owner:GetViewModel()
	self:SetNextIdle(CurTime() + vm:SequenceDuration())
end

local range = 128 ^ 2

-- Called when the player attempts to primary fire.

--Raise Fists--
function SWEP:Reload()
	local vm = self.Owner:GetViewModel()

	if CurTime() >= self.NextHolster then
		if self.Owner:GetNWBool("raisedFists") then
			if SERVER then
				vm:SetNoDraw(true)
			end
			
			self:SetWeaponHoldType("normal")
			self.Owner:PrintMessage(HUD_PRINTCENTER, "You lower your fists")
			self.Owner:SetNWBool("raisedFists", false)
			
			self.NextHolster = CurTime() + self.Primary.HolsterTime
		else
			if SERVER then
				vm:SetNoDraw(false)
				vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
			elseif vm:IsValid() then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
			end
			
			self:SetWeaponHoldType("fist")
			self.Owner:PrintMessage(HUD_PRINTCENTER, "You raise your fists")
			self.Owner:SetNWBool("raisedFists", true)
			
			self.NextHolster = CurTime() + self.Primary.HolsterTime
		end
	else
		return false
	end
end

function SWEP:PrimaryAttack(right)
	if not self.Owner:GetNWBool("raisedFists") then
		if SERVER then self.Owner:notify("AL_RAISE_FISTS") end
	return false end
	
	self:SetNextPrimaryFire(CurTime() + self.Primary.Refire)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Refire)
	
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	if IsValid(self.heldEnt)then
		self:dropObject(self.Primary.ThrowAcceleration)

		return
	end

	if not self.Owner:KeyDown(IN_SPEED) and self.Owner:isExhausted() then
		return
	end

	-- Set the animation of the weapon and play the sound.
	self:EmitSound(self.Primary.Sound)

	local vm = self.Owner:GetViewModel()
	if vm and vm:IsValid() then
		vm:SendViewModelMatchingSequence(right and vm:LookupSequence("fists_right") or vm:LookupSequence("fists_left"))

		self:UpdateNextIdle()
	end

	-- Get an eye trace from the owner.
	local trace = self.Owner:GetEyeTrace()
	local ent = trace.Entity

	-- Check the hit position of the trace to see if it's close to us.
	if IsValid(ent) and self.Owner:GetPos():DistToSqr(trace.HitPos) <= range then
		if ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" and not self.Owner:KeyDown(IN_SPEED) then
			if not self.Primary.Super and trace.Entity:IsPlayer() and ent:Health() - self.Primary.Damage <= 15 then
				if CLIENT then return true end

				arista.logs.event(arista.logs.E.LOG, arista.logs.E.DAMAGE, self.Owner:Name(), "(", self.Owner:SteamID(), ") knocked ", ent:Name(), " out with a punch.")

				ent:setAristaVar("stunned", true)
				ent:knockOut(ent:getAristaVar("knockOutTime") / 2)
			else
				local bullet = {}

				-- Set some information for the bullet.
				bullet.Num = 1
				bullet.Src = self.Owner:GetShootPos()
				bullet.Dir = self.Owner:GetAimVector()
				bullet.Spread = Vector(0, 0, 0)
				bullet.Tracer = 0
				bullet.Force = self.Primary.Force
				bullet.Damage = self.Primary.Damage

				if self.Primary.Super then
					if SERVER and ent:IsPlayer() then
						arista.logs.event(arista.logs.E.LOG, arista.logs.E.DAMAGE, self.Owner:Name(), "(", self.Owner:SteamID(), ") super punched ", ent:Name(), ".")
					end

					bullet.Callback	= function ( attacker, tr, dmginfo )
						if not IsValid(ent) then return end

						local effectData = EffectData()

						-- Set the information for the effect.
						effectData:SetStart(tr.HitPos)
						effectData:SetOrigin(tr.HitPos)
						effectData:SetScale(1)

						-- Create the effect from the data.
						util.Effect("Explosion", effectData)

					end
				end

				-- Fire bullets from the owner which will hit the trace entity.
				self.Owner:FireBullets(bullet)
			end
		else
			if self.Owner:KeyDown(IN_SPEED) then
				self:SetNextPrimaryFire(CurTime() + 0.75)
				self:SetNextSecondaryFire(CurTime() + 0.75)

				-- Keys!
				if CLIENT then return end

				if arista.entity.isOwnable(ent) and not ent:isJammed() then
					if arista.entity.hasAccess(ent, self.Owner) then
						trace.Entity:lock()
						trace.Entity:EmitSound("doors/door_latch3.wav")
					else
						self.Owner:notify("AL_CANNOT_NOACCESS")
					end
				end

				return
			else
				local phys = ent:GetPhysicsObject()

				if SERVER and IsValid(phys) and phys:IsMoveable() then
					ent:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector() * self.Primary.PunchAcceleration * phys:GetMass(), trace.HitPos)

					if self.Primary.Super then
						ent:TakeDamage(self.Primary.Damage, self.Owner)
					end
				end
			end
		end

		-- Check if the trace hit an entity or the world.
		if (trace.Hit or trace.HitWorld) then self:EmitSound("weapons/crossbow/hitbod2.wav") end


		if SERVER and self.stamina and not self.Primary.Super then
			local drain = arista.config.plugins.staminaPunch
			hook.Run("StaminaAdjustDrain", self.Owner, drain)

			self.Owner:setAristaVar("stamina", math.Clamp(self.Owner:getStamina() - drain, 0, 100))
		end
	end
end

-- Called when the player attempts to secondary fire.
function SWEP:SecondaryAttack()
	if not self.Owner:GetNWBool("raisedFists") then
		if SERVER then self.Owner:notify("AL_RAISE_FISTS") end
	return false end
	
	self:SetNextSecondaryFire(CurTime() + 0.25)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Refire)
	
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	if IsValid(self.heldEnt)then
		self:dropObject()

		return
	end

	-- Get a trace from the owner's eyes.
	local trace = self.Owner:GetEyeTrace()
	local ent = trace.Entity

	-- Check the hit position of the trace to see if it's close to us.
	if IsValid(ent) and self.Owner:GetPos():DistToSqr(trace.HitPos) <= range then
		if arista.entity.isOwnable(ent) then
			local vm = self.Owner:GetViewModel()
			if vm and IsValid(vm) then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_right"))

				self:UpdateNextIdle()
			end

			if self.Owner:KeyDown(IN_SPEED) then
				self:SetNextPrimaryFire(CurTime() + 0.75)
				self:SetNextSecondaryFire(CurTime() + 0.75)

				-- Keys!
				if CLIENT then return end

				if arista.entity.isOwnable(ent) and not ent:isJammed() then
					if arista.entity.hasAccess(ent, self.Owner) then
						trace.Entity:unLock()
						trace.Entity:EmitSound("doors/door_latch3.wav")
					else
						self.Owner:notify("AL_CANNOT_NOACCESS")
					end
				end

				return
			elseif arista.entity.isDoor(ent) then
				self:EmitSound("physics/wood/wood_crate_impact_hard2.wav")
				if self.Primary.Super and SERVER and self.Owner:IsSuperAdmin() then
					arista.entity.openDoor(ent, 0, true, true)
				end

				return
			end
		elseif ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" and not self.Owner:KeyDown(IN_SPEED) then
			self:PrimaryAttack(true)

			self:SetNextPrimaryFire(CurTime() + self.Primary.Refire)
			self:SetNextSecondaryFire(CurTime() + self.Primary.Refire)

			return
		end

		self:pickUp(ent, trace)
	end
end



function SWEP:Think()
	local vm = self.Owner:GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if idletime > 0 and CurTime() > idletime and vm and vm:IsValid() then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_idle_0" .. math.random(1, 2)))

		self:UpdateNextIdle()
	end

	if not self.heldEnt or CLIENT then return end

	if not IsValid(self.heldEnt) then
		if IsValid(self.entWeld) then self.entWeld:Remove() end

		self.Owner._holdingEnt, self.heldEnt.held, self.heldEnt, self.entWeld, self.entAngles, self.ownerAngles = nil
		self:speed()

		return
	elseif not IsValid(self.entWeld) then
		self.Owner._holdingEnt, self.heldEnt.held, self.heldEnt, self.entWeld, self.entAngles, self.ownerAngles = nil
		self:speed()

		return
	end

	if not self.heldEnt:IsInWorld() then
		self.heldEnt:SetPos(self.Owner:GetShootPos())
		self:dropObject()

		return
	end

	if self.NoPos then return end

	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()

	self.heldEnt:SetPos(pos + (ang * 60))
	self.heldEnt:SetAngles(Angle(self.entAngles.p, (self.Owner:GetAngles().y - self.ownerAngles.y) + self.entAngles.y, self.entAngles.r))
end

function SWEP:speed(down)
	if down then
		self.Owner:incapacitate()
	else
		self.Owner:recapacitate()
	end
end

function SWEP:Holster()
	if CLIENT then return true end

	self:dropObject()
	self.Primary.NextSwitch = CurTime() + 1

	local vm = self.Owner:GetViewModel()
		vm:SetNoDraw(false)

	return true
end

function SWEP:pickUp(ent, trace)
	if CLIENT or ent.held then return end
	if constraint.HasConstraints(ent) or ent:IsVehicle() or ent:IsNPC() or ent:GetClass():lower():find("npc_", 1, true) then
		return false
	end

	local pent = ent:GetPhysicsObject()
	if not IsValid(pent) then return end

	if pent:GetMass() > (self.Primary.Super and 150 or 60) or not pent:IsMoveable() then
		return
	end

	if ent:GetClass() == "prop_ragdoll" or ent:IsPlayer() or ent:IsWorld() then
		return false
	else
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		local entWeld = {}
		entWeld.ent = ent

		function entWeld:IsValid()
			return IsValid(self.ent)
		end

		function entWeld:Remove()
			if IsValid(self.ent) then
				self.ent:SetCollisionGroup(COLLISION_GROUP_NONE)
			end
		end

		self.NoPos = false
		self.entWeld = entWeld
	end

	self.Owner._holdingEnt = true
	self.heldEnt = ent
	self.heldEnt = ent
	self.heldEnt.held = true

	self.entAngles = ent:GetAngles()
	self.ownerAngles = self.Owner:GetAngles()

	self:speed(true)
end

function SWEP:dropObject(acceleration)
	if CLIENT then return true end

	acceleration = acceleration or 0.01

	if not IsValid(self.heldEnt) then return true end
	if IsValid(self.entWeld) then self.entWeld:Remove() end

	local pent = self.heldEnt:GetPhysicsObject()

	if pent:IsValid() then
		pent:ApplyForceCenter(self.Owner:GetAimVector() * pent:GetMass() * acceleration)
	end

	self.Owner._holdingEnt, self.heldEnt.held, self.heldEnt, self.entWeld, self.entAngles, self.ownerAngles = nil

	self:speed()
end

function SWEP:OnRemove()
	if CLIENT then return true end

	self:dropObject()

	return true
end
