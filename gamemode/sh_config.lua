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
	-- Time arrested for.
	arrestTime = 300,
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
	-- If you want to stop props killing people.
	preventPropKill = true,
	-- Amount of time (by default) people should bleed for.
	bleedTime = 3,
	-- Respective hitgroup region damage multipliers.
	headDmgScale = 3,
	stomachDmgScale = 1.25,
	normalDmgScale = 1,
	legDmgScale = 0.75,
	ragdollDmgScale = 1,
	-- Respective speeds for normal movement or when incapacictated,
	incapacitatedRunSpeed = 120,
	incapacitatedWalkSpeed = 100,
	runSpeed = 220,
	walkSpeed = 180,
	jumpPower = 200,
	-- Warrant expire times.
	searchWarrantTime = 220,
	arrestWarrantTime = 360,
	-- Time taken to perform an action.
	untyingTime = 50,
}

function arista.config:getDefault(var)
	return self.defaults[var]
end

-- todo: do a darkrp style 'dont touch the gamemode' config system.

