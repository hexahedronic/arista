ITEM.name					= "Empty Barrel"
ITEM.size					= 5
ITEM.cost					= 0.20
ITEM.batch					= 1
ITEM.store					= true
ITEM.model					= "models/props/de_inferno/wine_barrel.mdl"
ITEM.plural					= "Empty Barrels"
ITEM.description			= "A barrel for moonshine."

-- Called when a player drops the item.
function ITEM:onUse(ply)
	local trace = ply:GetEyeTraceNoCursor()
	local target = trace.Entity

	if not (target and target:IsValid() and target:GetClass() == "arista_distillery") then
		return false, "AL_INVALID_TARGET"
	end

	if not (target:GetNWBool("finishedDistilling", false)) then
		return false, "AL_DISTILLERY_NOT_FINISHED"
	end

	ply:notify("Please wait whilst the moonshine is extracted.")
	timer.Simple(5, function()
		if ply:GetEyeTraceNoCursor().Entity == target then
			arista.inventory.update(ply, "moonshine_barrel", 1, true)
			ply:notify("The barrel has been filled.")
		else
			ply:notify("You are not looking at the distillery!")
			arista.inventory.update(ply, "empty_barrel", -1, true)
		end
	end)
	return true
end
