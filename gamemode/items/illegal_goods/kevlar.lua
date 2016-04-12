ITEM.name					= "Kevlar Vest"
ITEM.size					= 2
ITEM.cost					= 550
ITEM.model				= "models/props_c17/suitcase_passenger_physics.mdl"
ITEM.batch				= 10
ITEM.store				= true
ITEM.plural				= "Kevlar Vests"
ITEM.description	= "Reduces the damage you receive by 50%."
ITEM.equippable		= true
ITEM.equipword		= "put on"
ITEM.base					= "item"

if CLIENT then
	arista.lang:Add("AL_KEVLAR_WEARING", {
		EN = "You are already wearing Kevlar!",
	})
end

-- Called when a player uses the item.
function ITEM:onUse(player)
	if player:getAristaVar("scaleDamage") == 0.5 then
		player:notify("AL_KEVLAR_WEARING")

		return false
	else
		player:setAristaVar("scaleDamage", 0.5)
	end
end
