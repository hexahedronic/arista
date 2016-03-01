AddCSLuaFile()

arista.config = {}

-- Default stuff.
arista.config.defaults = {
	-- The job that each player starts with.
	job = "Citizen",
	-- Time knocked out for.
	knockOutTime = 60,
	-- Time until respawn.
	spawnTime = 30,
}

-- Stuff that's saved in the database, if you want to fuck with it, then
-- fuck with it before your first run (pdata self-corrects, SQL is likely to break).
arista.config.database = {
	-- The money that each player starts with.
	money = 0,
	-- The clan that each player belongs to by default.
	clan = "",
	-- The default inventory size.
	inventorySize = 40,
	-- The detailed information each player begins with.
	details = "",
	-- This is so if they rejoin they are still in jail.
	arrested = false,
	-- Donator time.
	donator = 0,
}

arista.config.vars = {
	-- Use localised voice chat.
	localVoice = false,
	-- Amount to multiply donators salary by.
	donatorMult = 2,
}

function arista.config:getDefault(var)
	return self.defaults[var]
end

-- todo: do a darkrp style 'dont touch the gamemode' config system.

