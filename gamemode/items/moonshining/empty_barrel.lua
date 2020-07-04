ITEM.name					= "Empty Barrel"
ITEM.size					= 5
ITEM.cost					= 0.20
ITEM.batch					= 1
ITEM.store					= true
ITEM.model					= "models/props/de_inferno/wine_barrel.mdl"
ITEM.plural					= "Empty Barrels"
ITEM.description			= "A barrel for moonshine."

-- Called when a player drops the item.
function ITEM:onUse(player)
	local trace = player:GetEyeTraceNoCursor()
	local target = trace.Entity

	if not (target and target:IsValid() and target:IsVehicle() and target:getAristaVar("petrol") < 100) then
		return false, "AL_INVALID_TARGET"
	end

	target:setAristaVar("petrol", math.min(target:getAristaVar("petrol") + 50, 100))
end
