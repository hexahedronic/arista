arista.eventHooks = {}

-- todo: language?

local function succeed(ply, ent)
	if IsValid(ply) then
		ply:emote("somehow manages to cut through the rope and puts <P> knife away, job done.")

		ply._unTying = false
	end

	if IsValid(ent) then
		ent:emote("shakes the remains of the rope from <P> wrists and rubs them.")
		ent:unTie()

		ent._beUnTied = false
	end

	gamemode.Call("PlayerUnTied", ply, ent)
end

local function fail(ply, ent)
	if IsValid(ent) and ent:Alive() then
		ent._beUnTied = false
	end

	if IsValid(ply) and ply:Alive() then
		ply:emote("swears and gives up.")

		ply._unTying = false
	end
end

local function test(ply, ent, plystart, entstart)
	return IsValid(ply) and ply:Alive() and ply:GetPos() == plystart and IsValid(ent) and ent:Alive() and ent:GetPos() == entstart
end

-- Called when a player presses a key.
function arista.eventHooks.keyPress(ply, key)
	if key == IN_USE then
		-- Grab what's infront of us.
		local ent = ply:GetEyeTraceNoCursor().Entity

		if not IsValid(ent) then
			return
		elseif ent:isPlayerRagdoll() then
			ent = ent:getRagdollPlayer()
		end

		-- 200 ^ 2, more efficent
		if ent:IsPlayer() and ply:KeyDown(IN_SPEED) and gamemode.Call("PlayerCanUntie", ply, ent) and ent:GetPos():DistToSqr(ply:GetPos()) < 40000 then
			ply:emote("starts ineffectively sawing at <N>'s bonds with a butter knife.", ent)

			timer.Conditional(ply:UniqueID() .. " untying timer", arista.config.vars.untyingTime, test, succeed, fail, ply, ent, ply:GetPos(), ent:GetPos())

			ply._unTying = true
			ent._beUnTied = true
		end
	end
end
hook.Add("KeyPress", "arista.eventHooks.keyPress", arista.eventHooks.keyPress)
