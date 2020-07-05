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
	if ent:GetClass() != "arista_distillery" then
		ply:notify("You must look at a distillery to put in potato!")
		return
	end
	if !ent:GetNWBool("hasPotato") then
		ent:SetNWBool("hasPotato", true)
		arista.inventory.update(ply, "potato", -1, false)
		ply:notify("You have put potato into the distillery.")
	else
		ply:notify("This distillery already has potato in it!")
	end
end
