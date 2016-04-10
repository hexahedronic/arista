local item = FindMetaTable("Item")

if not item then
	arista.logs.log(arista.logs.E.FATAL, "COULD NOT FIND ITEM METATABLE!")

	return
end

---
-- Cause the item to call it's OnUse function then remove 1* itself from the player's library.
-- @param ply The player who has clicked 'use' on an item
-- @return True for success, false for failure.
function item:use(ply)
	local inventory = ply:getAristaVar("inventory")[self.uniqueID]
	if not self.onUse or not (inventory and inventory > 0) or self:onUse(ply) == false then
		return false
	end

	arista.inventory.update(ply, self.uniqueID, -1)

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, ply:Name(), "(", ply:SteamID(), ") used item '", self.name, "'.")

	return true
end

---
-- Cause the player to drop amt number of this item from their inventory as the specified position.
-- @param ply The player who is dropping the item
-- @param pos The position the items are to be dropped into
-- @param amt How many of the item to drop
function item:drop(ply, pos, amt)
	local inventory = ply:getAristaVar("inventory")[self.uniqueID]
	if not self.onDrop or not (inventory and inventory > 0) or self:onDrop(ply, pos, amt) == false then
		return false
	end

	arista.inventory.update(ply, self.uniqueID, -amt)

	self:make(pos, amt)

	if amt == 1 then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, ply:Name(), "(", ply:SteamID(), ") dropped item '", self.name, "'.")
	else
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, ply:Name(), "(", ply:SteamID(), ") dropped ", amt, " ", self.plural, ".")
	end
end

---
-- Delete every item the player has from their inventory.
-- @param ply The player whose inventory to delete the items from
-- @return True for success, false for failure.
function item:destroy(ply)
	local amt = ply:getAristaVar("inventory")[self.uniqueID]
	if not self.onDestroy or not (amt and amt > 0) then
		return false
	end

	local j = 0
	if self.recursiveDestroy then
		for i = 1, amt do
			if self:onDestroy(ply) == false then
				break
			end

			j = j + 1

			arista.inventory.update(ply, self.uniqueID, -1)
		end
	else
		j = amt

		arista.inventory.update(ply, self.uniqueID, -amt)
	end
	if j == 0 then
		return false
	end

	local text = (j == amt and "destroyed all") or "destroyed some"
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, ply:Name(), "(", ply:SteamID(), ") ", text, " of their ", self.plural, ".")

	-- Return true because we did it successfully.
	return true
end

local up = Vector(0, 0, 16)
---
-- Makes a copy of the item at the specified pos and amount
-- @param pos The position to make the item
-- @param amt The amount of the item to make
-- @return The newly made item entity
function item:make(pos, amt)
	local ent = ents.Create("arista_item")
		ent:setItem(self, amt)
		ent:SetPos(pos + up)
	ent:Spawn()
	ent:Activate()

	return ent
end

-- todo: Somehow have these done by the plugin not here, so implementations without the carmod don't get unneeded functions

---
-- Remove one of this item and give the player 1/2 the item's price (for cars)
-- @param ply The player from whose inventory to sell this item
-- @return True for success, false for failure.
function item:sell(ply)
	local amt = ply:getAristaVar("inventory")[self.uniqueID]
	if not self.onSell or not (amt and amt > 0) or self:onSell(ply) == false then
		return false
	end

	arista.inventory.update(ply, self.uniqueID, -1)

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, ply:Name(), "(", ply:SteamID(), ") sold a ", self.name, ".")

	local refund = self.refund or self.cost / 2
	ply:notify("AL_GOT_SECONDHAND", refund)
	ply:giveMoney(refund)

	return true
end

---
-- Call the 'onPickup' function of this item.
-- @param ply The player to pass to the function
-- @return True for success, false for failure.
function item:pickup(ply)
	local amt = ply:getAristaVar("inventory")[self.uniqueID]
	if not self.onPickup or not (amt and amt > 0) or self:onPickup(ply) == false then
		return false
	end

	return true
end
