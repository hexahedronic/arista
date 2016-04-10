include("item.lua")

ITEM.equippable	= true
ITEM.equipword	= "load"
ITEM.ammo				= {"", 0}

function ITEM:onUse(ply)
	ply:GiveAmmo(self.ammo[2], self.ammo[1])
end
