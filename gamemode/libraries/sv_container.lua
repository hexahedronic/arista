arista.container = {}

--Make an entity into a container
function arista.container.make(entity, size, name, initialContents)
	if arista.container.isContainer(entity) then
		return true
	end

	entity._inventory = {
		name = name or "Container",
		size = size or 30,
		contents = {},
	}

	entity:networkAristaVar("container", true)
	entity:networkAristaVar("title", entity._inventory.name)

	entity:SetUseType(SIMPLE_USE)

	entity:CallOnRemove("Contents Dumper", arista.container.dumpContents)

	if initialContents then
		for item, amount in pairs(initialContents) do
			local ret, msg = arista.container.update(entity, item, amount, true)

			if not ret then
				arista.logs.log(arista.logs.E.WARNING, "container.make: ", msg)
			end
		end
	end
end

--Get the contents of a container
function arista.container.getContents(entity, player, forMenu)
	if not arista.container.isContainer(entity) then
		return nil
	end

	if player then
		local contents, io, filter = gamemode.Call("PlayerGetContainerContents", entity, player, forMenu)

		if contents then
			return contents, io, filter
		end
	end

	return entity._inventory.contents, bit.bor(CONTAINER_CAN_TAKE, CONTAINER_CAN_PUT)
end

-- Get the limit of a container
function arista.container.getLimit(entity)
	if arista.container.isContainer(entity) then
		return entity._inventory.size
	end
end

-- Get the current space used
function arista.container.getContentsSize(entity,player)
	if not arista.container.isContainer(entity) then return end

	local contents = arista.container.getContents(entity, player)

	local size = 0

	for id, amount in pairs(contents) do
		local item = arista.item.items[id]

		if item and item.size > 0 then
			size = size + item.size * math.abs(amount)
		end
	end

	return size
end

-- Get the space left
function arista.container.getSpaceLeft(entity,player)
	if not arista.container.isContainer(entity) then return end

	return arista.container.getLimit(entity) - arista.container.getContentsSize(entity, player)
end

-- Can an item fit in?
function arista.container.canFit(entity,item,amount,player)
	if not arista.container.isContainer(entity) then return end

	if player then
		local ret = gamemode.Call("PlayerCanFitContainer", entity, player)

		if ret ~= nil then
			return ret
		end
	end

	return arista.container.getSpaceLeft(entity, player) - arista.item.items[item].size * amount >= 0
end

-- Update a container's contents
function arista.container.update(entity, id, amount, force, player)
	if not arista.container.isContainer(entity) then return false, "AL_INVALID_CONTAINER" end

	local item = arista.item.items[id]
	if not item then
		return false, "AL_INVALID_ITEM"
	end

	local amount = amount or 0

	if player then
		local ret, msg = gamemode.Call("PlayerUpdateContainerContents", player, entity, id, amount, force)

		if ret ~= nil then
			return ret, msg
		end
	end

	if item.canContainer then
		local ret, msg = item:canContainer(player, amount, force, entity)
		if not ret then
			return ret, msg
		end
	end

	if not (force or arista.container.canFit(entity, id, amount, player)) then
		return false, "AL_CANNOT_CONTAINER_FIT"
	end

	entity._inventory.contents[id] = (entity._inventory.contents[id] or 0) + amount

	if entity._inventory.contents[id] <= 0 then
		entity._inventory.contents[id] = nil
	end

	if player then
		if id == "money" then
			player:giveMoney(-amount)
		else
			arista.inventory.update(player, id, -amount, force)
		end

		gamemode.Call("PlayerUpdatedContainerContents", player, entity, id, amount, force)
	end

	return true
end

--Set the name of a cointainer
function arista.container.setName(entity, name)
	if not arista.container.isContainer(entity) then return end

	entity._inventory.name = name
	entity:setAristaVar("name", entity._inventory.name)
end

-- Get hte name of a container
function arista.container.getName(entity)
	if not arista.container.isContainer(entity) then return end

	return entity._inventory.name
end

--See if an entity is a cointainer
function arista.container.isContainer(entity)
	return tobool(entity._inventory)
end

local up = Vector(0, 0, 32)

-- Dump the contents of a container at the pos
function arista.container.dumpContents(entity,pos)
	if not arista.container.isContainer(entity) then return end

	local pos = pos or entity:GetPos()
	pos = pos + up

	local contents = arista.container.getContents(entity)
	local items = {}

	for name, amount in pairs(contents) do
		table.insert(items, arista.item.items[name]:make(pos, amount))
		arista.container.update(entity, name, -amount, true)
	end

	-- Ensure our items don't go flying
	for _, v in ipairs(items) do
		for _, v2 in ipairs(items) do
			if v ~= v2 and IsValid(v) and IsValid(v2) then
				constraint.NoCollide(v, v2, 0, 0)
			end
		end
	end
end

-- Quick concommand for clients to say when they're done
concommand.Add("_arista_containerfinished", function(player)
	if not IsValid(player) then return end
	gamemode.Call("PlayerClosedContainerWindow", player)
end)
