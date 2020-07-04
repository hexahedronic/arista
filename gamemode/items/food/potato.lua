ITEM.name					= "Potato"
ITEM.size					= 1
ITEM.cost					= 0.06
ITEM.batch					= 1
ITEM.store					= false
ITEM.model					= "models/props_phx/misc/potato.mdl"
ITEM.plural					= "Potatoes"
ITEM.description			= "A potato for brewing moonshine."

-- Called when a player uses the item.
function ITEM:onUse(ply)
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity

end
