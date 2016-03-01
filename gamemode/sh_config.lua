AddCSLuaFile()

arista.config = {}

arista.config.defaults = {
	-- The job that each player starts with.
	job = "Citizen",
}

arista.config.database = {
	-- The money that each player starts with.
	money = 0,
	-- The clan that each player belongs to by default.
	clan = "",
	-- The default inventory size.
	inventorySize = 40,
	-- The detailed information each player begins with.
	details = "",
}

function arista.config:getDefault(var)
	return self.defaults[var]
end

-- todo: do a darkrp style 'dont touch the gamemode' config system.

