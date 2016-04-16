ITEM.name					= "Chloroform"
ITEM.plural				= "Chloroform"
ITEM.size					= 1
ITEM.cost					= 1000
ITEM.model				= "models/props_junk/garbage_newspaper001a.mdl"
ITEM.batch				= 10
ITEM.store				= true
ITEM.description	= "A material used to knock someone unconscious for a limited time."
ITEM.base					= "item"
ITEM.noVehicles		= true

if CLIENT then
	arista.lang:Add("AL_CHLOROFORM_BEHIND", {
		EN = "You must be right behind someone to chloroform them!",
	})
end

-- Called when a player uses the item.
function ITEM:onUse(ply)
	local tr = ply:GetEyeTraceNoCursor()
	local victim = tr.Entity

	if not (victim and IsValid(victim) and victim:IsPlayer()
	and victim:Alive() and not victim:isUnconscious()
	and ply:GetShootPos():Distance(tr.HitPos) <= 80
	and math.abs(victim:GetAimVector():Angle().y - tr.Normal:Angle().y) < 35) then
		ply:notify("AL_CHLOROFORM_BEHIND")
	return false end

	ply:emote("grabs <N> from behind, clasping a dirty rag over <O> mouth.", victim)
	victim:emote("struggles a bit before slumping to the floor.")

	victim:setAristaVar("sleeping", true)
	victim:knockOut(30)

	--GM:Log(EVENT_EVENT, "%s just chloroformed %s.", ply:Name(), victim:Name());

	gamemode.Call("PlayerKnockedOut", victim, ply)

	return true
end
