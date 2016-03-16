ITEM.name					= "Note"
ITEM.plural				= "Cash"
ITEM.size					= 0
ITEM.cost					= 1
ITEM.model				= "models/props/cs_assault/money.mdl"
ITEM.batch				= 1000
ITEM.store				= false
ITEM.description	= "A wad of money."

local function updatefunc(ply)
	if not ply:IsValid() then return end

	ply:giveMoney(ply._temporaryMoneyUpdate)
	ply._temporaryMoneyUpdate	= nil
end

function ITEM:onUpdate(ply, amount)
	if amount > 0 then
		if ply._temporaryMoneyUpdate then
			ply._temporaryMoneyUpdate	= ply._temporaryMoneyUpdate + amount
		else
			ply._temporaryMoneyUpdate	= amount

			timer.Simple(0.1, function() updatefunc(ply) end)
		end

		return true -- Never put this in a player's inventory
	end
end
