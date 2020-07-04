ITEM.name					= "Barrel of Moonshine"
ITEM.size					= 5
ITEM.cost					= 1.75
ITEM.batch					= 1
ITEM.store					= false
ITEM.model					= "models/props/de_inferno/wine_barrel.mdl"
ITEM.plural					= "Barrels of Moonshine"
ITEM.description			= "A barrel of moonshine."

-- Called when a player drops the item.
function ITEM:onUse(player)
	local trace = player:GetEyeTraceNoCursor()
	local target = trace.Entity

	if not (target and target:IsValid() and target:IsVehicle() and target:getAristaVar("petrol") < 100) then
		return false, "AL_INVALID_TARGET"
	end

	target:setAristaVar("petrol", math.min(target:getAristaVar("petrol") + 50, 100))
end
