ITEM.name					= "Health Kit"
ITEM.size					= 1
ITEM.cost					= 400
ITEM.model				= "models/items/healthkit.mdl"
ITEM.batch				= 5
ITEM.store				= true
ITEM.plural				= "Health Kits"
ITEM.description	= "A health kit which restores 75 health."
ITEM.equippable		= true
ITEM.equipword		= "heal yourself"
ITEM.base					= "item"

function ITEM:onUse(player)
	-- todo: lang
	if player:Health() >= 100 then
		player:notify("You do not need any more health!")
	return false end

	player:SetHealth(math.Clamp(player:Health() + 75, 0, 100))
end
