AddCSLuaFile()

ENT.Type						= "anim"
ENT.Base						= "base_gmodentity"
ENT.PrintName 			= "Fire"
ENT.Author 					= "Kudomiku, Fearless & Q2F2"
ENT.Spawnable 			= false
ENT.AdminSpawnable	= false

if CLIENT then

function ENT:Draw()
end

function ENT:Think()
	if self.lastEffect + .15 < CurTime() then
		self.lastEffect = CurTime()

		local effect = EffectData()
			effect:SetOrigin(self:GetPos())
		util.Effect("arista_fire_effect", effect)
	end

	if self.lastPlayTime + self.inBetween < CurTime() then
		self.soundEffect:Stop()
		self.soundEffect:Play()
		self.lastPlayTime = CurTime()
	end
end

function ENT:Initialize()
	self.lastEffect = CurTime()
	self.soundID = math.random(1, 3)

	if self.SoundID == 1 then
		self.soundEffect = CreateSound(self, Sound('ambient/fire/fire_med_loop1.wav'))
		self.inBetween = 6.5
	elseif self.SoundID == 2 then
		self.soundEffect = CreateSound(self, Sound('ambient/fire/firebig.wav'))
		self.inBetween = 5
	else
		self.soundEffect = CreateSound(self, Sound('ambient/fire/fire_big_loop1.wav'))
		self.inBetween = 5
	end

	self.lastPlayTime = 0
end

function ENT:OnRemove()
	self.soundEffect:Stop()
end

else

local distance = 3
local numberOfFires = 0
local offset = Vector(0, 0, 10)

function ENT:Initialize()
	self:SetModel("models/props_junk/wood_pallet001a.mdl")

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetAngles(angle_zero)

	self:SetPos(self:GetPos() + offset)

	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(color_transparent)

	self.lastSpread = CurTime()
	self.spawnTime = CurTime()

	numberOfFires = numberOfFires + 1

	self.lastDamage = CurTime()
	self.extinguisherLeft = math.random(70, 100)

	self.spores = 0
	self.healthAdd = CurTime()

	self:DrawShadow(false)
end

function ENT:SpreadFire()
	if not arista.config.vars.fireSpread then return false end
	if numberOfFires >= arista.config.vars.maxFires then return false end

	for i = 1, 5 do
		local randomStart = self:GetPos() + Vector(math.random(-100, 100) * distance, math.random(-100, 100) * distance, 50)
		local usStart = self:GetPos() + Vector(0, 0, 10)

		local trace = {}
			trace.start = usStart
			trace.endpos = randomStart
			trace.filter = self
			trace.mask = MASK_OPAQUE
		local tr = util.TraceLine(trace)

		if not tr.Hit then
			local trStart = randomStart
			local trEnd = trStart - Vector(0, 0, 100)

			local trace = {}
				trace.start = trStart
				trace.endpos = trEnd
				trace.filter = self
			local tr2 = util.TraceLine(trace)

			if tr2.HitWorld then
				if util.IsInWorld(tr2.HitPos) then
					local fire = ents.Create("arista_fire")
						fire:SetPos(tr2.HitPos)
					fire:Spawn()

					self.spores = self.spores + 1
				end
			end
		end
	end
end

function ENT:HitByExtinguisher(player, hose)
	if hose then
		self.extinguisherLeft = self.extinguisherLeft - 15
	else
		self.extinguisherLeft = self.extinguisherLeft - 10
	end

	if self.extinguisherLeft <= 0 then
		numberOfFires = numberOfFires - 1

		self:Remove()
	end
end

local hurtDist = 140^2
local heavyDist = 70^2
function ENT:Think()
	--print(numberOfFires)
	if self.spores >= 60 or self:WaterLevel() > 0 then
		numberOfFires = numberOfFires - 1
		self:Remove()
	return false end

	if self.healthAdd + 10 < CurTime() then
		self.healthAdd = CurTime()
		self.extinguisherLeft = math.Clamp(self.extinguisherLeft + 1, 0, 120)
	end

	if self.lastSpread + 30 < CurTime() then
		self:SpreadFire()

		self.spores = self.spores + 1
		self.lastSpread = CurTime()
	end

	if self.lastDamage + .1 < CurTime() then
		local closeEnts = ents.FindInSphere(self:GetPos(), 70)
		self.lastDamage = CurTime()

		for k , v in pairs(closeEnts) do
			local dist = self:GetPos():DistToSqr(v:GetPos())

			if v:GetClass() == "prop_physics" or v:GetClass() == "arista_item" or v:GetClass():find("wire_", 1, true) then
				v.fireDamage = v.fireDamage or 60
				v.fireDamage = v.fireDamage - 1

				if v.fireDamage == 0 then
					local fireProp = arista.config.vars.fireProps[v:GetModel():lower()]

					if fireProp then
						--print("this shit fire")
						for i = 1, fireProp do
							self:SpreadFire()
						end
					end

					v:Remove()
				else
					if not v:IsOnFire() then
						v:Ignite(60, 100)
					end

					local c = (v.fireDamage / 60) * 255
					v:SetColor(Color(c, c, c, 255))
				end
			elseif v:IsPlayer() and v:Alive() and dist < hurtDist then
				local team = arista.team.get(v:Team())

				if not team.fire then
					v:TakeDamage(2, v, self)

					if dist < heavyDist then
						v:TakeDamage(10, v, self)
					end
				else
					v.lastFireDamage = v.lastFireDamage or 0

					if v.lastFireDamage + 1 < CurTime() then
						v:TakeDamage(1, v, self)

						v.lastFireDamage = CurTime()
					end
				end
			end
		end
	end
end

function ENT:Use()
end

end
