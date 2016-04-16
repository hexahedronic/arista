ITEM.name							= "Jerry Can"
ITEM.size							= 3
ITEM.cost							= 800
ITEM.batch						= 1
ITEM.store						= true
ITEM.model						= "models/props_junk/metalgascan.mdl"
ITEM.plural						= "Jerry Cans"
ITEM.description			= "A tool that allows for you refuel cars on the go."

-- Called when a player drops the item.
function ITEM:onUse(player)
	local trace = player:GetEyeTraceNoCursor()
	local target = trace.Entity

	if not (target and target:IsValid() and target:IsVehicle() and target:getAristaVar("petrol") < 100) then
		return false, "AL_INVALID_TARGET"
	end

	target:setAristaVar("petrol", math.min(target:getAristaVar("petrol") + 50, 100))
end
