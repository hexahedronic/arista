ITEM.name					= "Coal"
ITEM.size					= 1
ITEM.cost					= 0.10
ITEM.batch					= 1
ITEM.store					= false
ITEM.model					= "models/props_phx/games/chess/black_dama.mdl"
ITEM.plural					= "Coal"
ITEM.description			= "Coal to burn."

-- Called when a player uses the item.
function ITEM:onUse(ply)
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity

end
