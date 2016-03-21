ITEM.name							= "Small Pocket"
ITEM.size							= -5
ITEM.model						= "models/props_junk/garbage_bag001a.mdl"
ITEM.plural						= "Small Pockets"
ITEM.description			= "A small pocket which allows you to hold more."
ITEM.becomes					= "boxed_pocket"
ITEM.recursiveDestroy	= true

-- Called when a player drops the item.
function ITEM:onDrop(player, position, amount)
	if arista.inventory.canFit(player, -self.size * amount) then
		-- Remove the item from the player's inventory.
		local boxed = arista.item.items[self.becomes]

		-- todo: potential log

		arista.inventory.update(player, self.uniqueID, -amount)
		boxed:make(position, amount)
	else
		player:notify("AL_CANNOT_X_ENCUMBERED", "AL_DROP_THAT")
	end

	return false
end

-- Called when a player destroys the item.
function ITEM:onDestroy(player)
	if not arista.inventory.canFit(player, -self.size) then
		player:notify("AL_CANNOT_X_ENCUMBERED", "AL_DESTROY_THAT")

		return false
	end
end
