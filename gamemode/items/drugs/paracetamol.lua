ITEM.name					= "Paracetamol"
ITEM.size					= 1
ITEM.cost					= 100
ITEM.model				= "models/props_junk/garbage_metalcan002a.mdl"
ITEM.batch				= 5
ITEM.store				= true
ITEM.plural				= "Paracetamol"
ITEM.description	= "A small pill which unblurs vision when low on health."
ITEM.equippable		= true
ITEM.equipword		= "pop"
ITEM.base					= "item"

function ITEM:onUse(player)
	-- todo: lang
	if player:Health() >= 50 then
		player:notify("You do not need any paracetamol!")
	return false end

	player:setAristaVar("hideHealthEffects", true)
end
