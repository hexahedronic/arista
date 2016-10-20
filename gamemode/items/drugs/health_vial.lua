ITEM.name					= "Health Vial"
ITEM.size					= 1
ITEM.cost					= 100
ITEM.model				= "models/healthvial.mdl"
ITEM.batch				= 5
ITEM.store				= true
ITEM.plural				= "Health Vials"
ITEM.description	= "A health vial which restores 25 health."
ITEM.equippable		= true
ITEM.equipword		= "heal yourself"
ITEM.base					= "item"

function ITEM:onUse(player)
	-- todo: lang
	if player:Health() >= 100 then
		player:notify("You do not need any more health!")
	return false end

	player:SetHealth(math.Clamp(player:Health() + 25, 0, 100))
end
