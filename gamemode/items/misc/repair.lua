ITEM.name							= "Repair Kit"
ITEM.size							= 2
ITEM.cost							= 800
ITEM.store						= true
ITEM.model						= "models/props/cs_militia/circularsaw01.mdl"
ITEM.plural						= "Repair Kits"
ITEM.description			= "A tool that allows for you to repair cars on the go."

-- Called when a player drops the item.
function ITEM:onUse(ply)
	local trace = player:GetEyeTraceNoCursor()
	local target = trace.Entity

	if not (target and target:IsValid() and target:IsVehicle() and target:Health() < 100) then
		return false, "AL_INVALID_TARGET"
	end

	target:SetHealth(math.min(target:Health() + 50, 100))
end
