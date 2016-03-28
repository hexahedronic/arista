include("item.lua") -- Inherit baseclass.

ITEM.batch				= 5
ITEM.size					= 1
ITEM.hunger				= 0
ITEM.equippable		= true
ITEM.equipword		= "eat"

-- Called when a player drops the item.
function ITEM:onUse(ply)
	local hunger = ply:getAristaVar("hunger") or 100
	ply:setAristaVar("hunger", math.min(hunger + self.hunger, 100))
end

