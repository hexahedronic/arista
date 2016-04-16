ITEM.name					= "Nitrazepam"
ITEM.size					= 1
ITEM.cost					= 60
ITEM.model				= "models/props_c17/trappropeller_lever.mdl"
ITEM.batch				= 5
ITEM.store				= true
ITEM.plural				= "Nitrazepam"
ITEM.description	= "An injection which puts you to sleep instantly."
ITEM.equippable		= true
ITEM.equipword		= "inject"
ITEM.base					= "item"

function ITEM:onUse(player)
	player:emote("unexpectedly collapses.")
	player:knockOut()

	-- Set sleeping to true because we are now sleeping.
	player:setAristaVar("sleeping", true)
end
