local cars = (GM or GAMEMODE):GetPlugin"vehicles"
ITEM.autoClose	= true
ITEM.noVehicles = true
ITEM.size				= 5
ITEM.batch			= 1
ITEM.max				= 1

function ITEM:onUse(ply)
	cars:SpawnCar(ply, self)

	return false --Otherwise the item goes byebye.
end

function ITEM:onSell(ply)
	return cars:SellCar(ply, self) or false
end

function ITEM:onPickup(ply)
	return cars:PickupCar(ply, self) or false
end

-- Called when a ply attempts to manufacture an item.
function ITEM:canManufacture(ply)
	return cars:CanManufactureCar(ply, self) or false
end

-- On Manufacture.
function ITEM:onManufacture(ply, entity)
	cars:ManufactureCar(ply, entity, self)
end

-- Can put in container
function ITEM:canContainer(ply, amount, force, entity)
	return false, "You cannot put this in there!"
end
