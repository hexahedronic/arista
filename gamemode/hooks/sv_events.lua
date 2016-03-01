arista.eventHooks = {}

local function succeed(ply, ent)
	if IsValid(ply) then
		ply:emote("somehow manages to cut through the rope and puts " .. ply._GenderWord .. " knife away, job done.");
		ply._Untying = false;
	end

	if IsValid(ent) then
		ent:emote("shakes the remains of the rope from " .. ent._GenderWord .. " wrists and rubs them");
		ent:unTie()
		ent._beUnTied = false
	end

	gamemode.Call("PlayerUnTied", ply, ent)
end

local function fail(ply, ent)
	if (IsValid(ent) and ent:Alive()) then
		ent:Emote("manages to dislodge " .. ply:Name() .. "'s attempts.");
		ent._beUnTied = false;
	end if (IsValid(ply) and ply:Alive()) then
		ply:Emote("swears and gives up.");
		ply._UnTying = false;
	end
end

local function test(ply, ent, ppos, epos)
	return IsValid(ply) and ply:Alive() and ply:GetPos() == ppos and IsValid(ent) and ent:Alive() and ent:GetPos() == epos;
end

-- Called when a player presses a key.
function arista.eventHooks.keyPress(ply, key)
	if (key == IN_USE) then
		-- Grab what's infront of us.
		local ent = ply:GetEyeTraceNoCursor().Entity
		if (not IsValid(ent)) then
			return;
		elseif (IsValid(ent._Player)) then
			ent = ent._Player;
		end
		if (ent:IsPlayer()
		and ply:KeyDown(IN_SPEED)
		and gamemode.Call("PlayerCanUntie", ply, ent)
		and ent:GetPos():Distance(ply:GetPos()) < 200) then
			ply:Emote("starts ineffectually sawing at " .. ent:Name() .. "'s bonds with a butter knife");
			timer.Conditional(ply:UniqueID() .. " untying timer", self.Config['UnTying Timeout'], uttest, utwin, utfail, ply, ent, ply:GetPos(), ent:GetPos())
			ply._UnTying = true;
			ent._beUnTied = true;
		end
	end
end
hook.Add("KeyPress", "arista.eventHooks.keyPress", arista.eventHooks.keyPress)
