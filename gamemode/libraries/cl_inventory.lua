arista.inventory = {}
arista.inventory.stored = {}
arista.inventory.updatePanel = true

-- Hook into when the server sends the client an inventory item.
net.Receive("arista_inventoryItem", function()
	local item = net.ReadString()
	local amount = net.ReadUInt(32)

	arista.logs.log(arista.logs.E.DEBUG, "mixtape.fire_", item)

	-- Check to see if the amount is smaller than 1.
	if amount < 1 then
		arista.inventory.stored[item] = nil
	else
		arista.inventory.stored[item] = amount
	end

	-- Tell the inventory panel that we should update.
	arista.inventory.updatePanel = true
end)

-- Get the maximum amount of space a player has.
function arista.inventory.getMaximumSpace(inv, intial)
	local size = intial or arista.lp:getAristaInt("inventorySize")
	inv = inv or arista.inventory.stored

	-- Loop through the player's inventory.
	for k, v in pairs(inv) do
		local item = arista.item.items[k]

		if item and item.size < 0 then
			size = size + (item.size * -v)
		end
	end

	-- Return the size.
	return size
end

-- Get the size of the local player's inventory.
function arista.inventory.getSize(inv)
	local size = 0
	inv = inv or arista.inventory.stored

	-- Loop through the player's inventory.
	for k, v in pairs(inv) do
		local item = arista.item.items[k]

		if item and item.size > 0 then
			size = size + (item.size * v)
		end
	end

	-- Return the size.
	return size
end

-- Check if the local player can fit a specified size into their inventory.
function arista.inventory.canFit(size, inv)
	if arista.inventory.getSize(inv) + size > arista.inventory.getMaximumSpace(inv) then
		return false
	else
		return true
	end
end
