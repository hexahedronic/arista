local fireEmitter = ParticleEmitter(Vector(0, 0, 0))

function EFFECT:Init(data)
	local pos = data:GetOrigin() - Vector(0, 0, 5)

	local trace = {}
		trace.start = pos
		trace.endpos = pos + Vector(0, 0, 500)
		trace.mask = MASK_VISIBLE
	local tr = util.TraceLine(trace)

	local p = fireEmitter:Add("effects/fireflames", pos)
	if tr.Hit then
		p:SetVelocity(Vector(math.random(-30, 30), math.random(-30, 30), math.random(0, 70)))
	else
		p:SetVelocity(Vector(math.random(-30, -20), math.random(20, 30), math.random(0, 70)))
	end

	p:SetDieTime(math.Rand(2, 3))

	p:SetStartAlpha(230)
	p:SetEndAlpha(0)
	p:SetStartSize(math.random(70, 80))
	p:SetEndSize(10)

	p:SetRoll(math.Rand(0, 10))
	p:SetRollDelta(math.Rand(-0.2, 0.2))
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
