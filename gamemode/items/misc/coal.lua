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
	if ent:GetClass() != "arista_distillery" then
		ply:notify("You must look at a distillery to put in coal!")
		return
	end
	if !ent:GetNWBool("hasCoal") then
		ent:SetNWBool("hasCoal", true)
		arista.inventory.update(ply, "coal", -1, false)
		ply:notify("You have put coal into the distillery.")
	else
		ply:notify("This distillery already has coal in it!")
	end
end
