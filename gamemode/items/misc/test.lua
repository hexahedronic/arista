ITEM.name = "Test Item"
ITEM.size = 1
ITEM.cost = 200
ITEM.model = "models/props_c17/FurnitureToilet001a.mdl"
ITEM.batch = 1
ITEM.store = true
ITEM.plural = "Test Items"
ITEM.description = "Used to test the inventory and such."
ITEM.base = "item"

function ITEM:onUse(player)
	arista.logs.log(arista.logs.E.DEBUG, player:Name(),"(", player:SteamID(), ") used the god damn test item!!!")
end
