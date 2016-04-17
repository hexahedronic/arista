ITEM.noVehicles = true
ITEM.size				= 3

function ITEM:checkCount(ply)
	if ply:GetCount(self.uniqueID) == self.max then
		-- todo: lang
		ply:notify("You have reached the maximum %s!", self.plural)
	return false end

	return true
end

function ITEM:doSpawn(ply, pos)
	local ent = ents.Create(self.uniqueID)
		ent:SetPos(pos)
		ent:CPPISetOwner(ply)
	ent:Spawn()

	ply:AddCount(self.uniqueID, ent)
end

-- Called when a player drops the item.
function ITEM:onDrop(ply, pos)
	if not self:checkCount(ply) then return false end

	-- Spawn it ourselves
	self:doSpawn(ply, pos)

	-- Remove the item from their inventory
	arista.inventory.update(ply, self.uniqueID, -1)

	-- Prevent the gamemode doing what it wants to
	return false
end

-- Called when a player destroys the item
function ITEM:onDestroy() end

-- Called when a player attempts to manufacture an item.
function ITEM:canManufacture(ply)
	return self:checkCount(ply)
end

-- Called when a player manufactures an item.
function ITEM:onManufacture(ply, ent)
	local pos = ent:GetPos()

	ent:Remove()
	self:doSpawn(ply, pos)
end
