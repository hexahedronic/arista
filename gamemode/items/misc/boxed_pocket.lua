ITEM.name					= "Boxed Pocket"
ITEM.size					= 2
ITEM.cost					= 5000
ITEM.model				= "models/props_junk/cardboard_box004a.mdl"
ITEM.batch				= 10
ITEM.store				= true
ITEM.plural				= "Boxed Pockets"
ITEM.becomes			= "small_pocket"
ITEM.description	= "Open this box to reveal a small pocket."
ITEM.max					= 10
ITEM.equippable		= true
ITEM.equipword		= "open"
ITEM.base					= "item"

function ITEM:onUse(ply)
	if (ply:getAristaVar("inventory")[self.becomes] or 0) >= self.max then
		local becomes = (arista.item.items[self.becomes] or {}).name
		if becomes then ply:notify("AL_CANNOT_X_MAX", becomes) end

		return false
	end

	arista.inventory.update(ply, self.becomes, 1)
end
