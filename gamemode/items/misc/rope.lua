ITEM.name					= "Spool of Rope"
ITEM.size					= 1
ITEM.cost					= 200
ITEM.model				= "models/props_lab/pipesystem03d.mdl"
ITEM.batch				= 10
ITEM.store				= true
ITEM.plural				= "Spools of Rope"
ITEM.description	= "Can be used for tying people up"
ITEM.base					= "item"

local function conditional(ply, victim, plypos, victimpos)
	return ply:IsValid() and victim:IsValid() and ply:GetPos() == plypos and victim:GetPos() == victimpos
end

local function success(ply, victim)
	victim:tieUp()

	ply:emote("completes the final loop and pulls the knot tight.")

	victim._beTied = false
	ply._tying = false

	gamemode.Call("PlayerTied", ply, victim)
end

local function failure(ply, victim)
	if IsValid(victim) then
		victim:emote("breaks free and throws the rope to the floor.")

		arista.item.items["rope"]:make(victim:GetPos())

		victim._beTied = false
	end

	if IsValid(ply) then
		ply._tying = false
	end
end

local dist = 128 ^ 2

-- TODO: Ballgag item
function ITEM:onUse(player)
	local trace = player:GetEyeTraceNoCursor()
	local target = trace.Entity

	if target:isPlayerRagdoll() then target = target:getRagdollPlayer() end

	if not (IsValid(target) and target:IsPlayer() and player:GetPos():DistToSqr(trace.HitPos) <= dist) then
		player:notify("AL_CANNOT_TIE")

		return false
	end

	if gamemode.Call("PlayerCanTie", player, target) == false then return false end

	player:emote("grabs <N>'s arms and starts tying them up.", target)

	player._tying	= target
	target._beTied = player

	arista.timer.conditional(player:UniqueID() .. " Tying Timer", arista.config.vars.tyingTime, conditional, success, failure, player, target, player:GetPos(), target:GetPos())
end
