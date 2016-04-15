arista.inventory = {}

function arista.inventory.update(player, id, amount, force)
	if not (IsValid(player) and type(amount) == "number") then
		arista.logs.log(arista.logs.E.ERROR, "inventory.update was passed an invalid amount or player.")

		return
	end

	arista.logs.logNoPrefix(arista.logs.E.DEBUG, "inventory.update called with '", id, "' (", amount, ").")

	local inventory = player:getAristaVar("inventory")
	inventory[id] = inventory[id] or 0

	local item = arista.item.items[id]

	if not item then
		arista.logs.log(arista.logs.E.ERROR, "inventory.update was passed an invalid item (", id, ").")

		return false, "That is not a valid item!"
	end

	-- todo: lang

	local size = item.size * amount
	local newAmt = inventory[id] + amount

	if not (amount < 1 or arista.inventory.canFit(player, size) or force) then
		return false, "You do not have enough inventory space!"
	end

	if item.onUpdate then
		local ret, msg = item:onUpdate(player, newAmt)

		if ret ~= nil then --Allow onUpdate to bypass the system
			return ret, msg
		end
	end

	if not force and item.max and newAmt > item.max then
		return false, "You can't carry any more %s!", item.plural
	end

	inventory[id] = math.Clamp(newAmt, 0, 2147483647)

	-- Check to see if we do not have any of this item now.
	if inventory[id] <= 0 then
		if amount > 0 then
			inventory[id] = amount
		else
			inventory[id] = nil
		end
	end

	player:setAristaVar("inventory", inventory)

	local finAmt = inventory[id]

	-- Send a net message to the player to tell them their items have been updated.
	net.Start("arista_inventoryItem")
		net.WriteString(id)
		net.WriteUInt(finAmt or 0, 32)
	net.Send(player)

	-- Return true because we updated the inventory successfully.
	return true
end

-- Get the maximum amount of space a player has.
function arista.inventory.getMaximumSpace(player, inventory)
	local size = player:getAristaVar("inventorySize")
	local inv = inventory or player:getAristaVar("inventory")

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

-- Get the size of a player's inventory.
function arista.inventory.getSize(player, inventory)
	local size = 0
	local inv = inventory or player:getAristaVar("inventory")

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

-- Check if a player can fit a specified size into their inventory.
function arista.inventory.canFit(player, size, inventory)
	return size <= 0 or arista.inventory.getSize(player, inventory) + size <= arista.inventory.getMaximumSpace(player, inventory)
end

local function playerInitInventory(player)
	local inventory = player:getAristaVar("inventory")

	for k, v in pairs(inventory) do
		arista.inventory.update(player, k, 0, true)
	end
end
hook.Add("PlayerInitialized", "Player Init Inventory", playerInitInventory)

timer.Simple(1, function()
	if #player.GetAll() > 0 then
		arista.logs.log(arista.logs.E.WARNING, "lua reload detected: resending inventories.")

		for k, v in pairs(player.GetAll()) do
			if v._inited then playerInitInventory(v) end
		end
	end
end)
