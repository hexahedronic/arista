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
	-- Access level.
	access = "b",
	-- Categories in the store that the job can use.
	jobCategories = {CATEGORY_VEHICLES, CATEGORY_CONTRABAND},
	-- Playermodels.
	female = {
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_02.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group01/female_05.mdl",
		"models/player/group01/female_06.mdl",
	},
	male = {
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_02.mdl",
		"models/player/group01/male_03.mdl",
		"models/player/group01/male_04.mdl",
		"models/player/group01/male_05.mdl",
		"models/player/group01/male_06.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/male_08.mdl",
		"models/player/group01/male_09.mdl",
	},
	-- Wait time to rejoin job.
	jobWait = 5 * 60
}

-- Stuff that's saved in the database, if you want to fuck with it, then
-- fuck with it before your first run (pdata self-corrects, SQL is likely to break).
arista.config.database = {
	-- The money that each player starts with.
	money = 2500,
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
	-- Gender.
	gender = "Male",
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
	untyingTime = 15,
	-- If we should clear decals every 60 seconds.
	clearDecals = true,
	-- What logs to print. arista.logs.E.DEBUG, arista.logs.E.LOG, arista.logs.E.WARNING, arista.logs.E.ERROR, arista.logs.E.FATAL
	warningLevel = arista.logs.E.DEBUG,
	-- Time before doors automatically close.
	doorAutoClose = 15,
	-- If a door gets jammed, how long for?
	doorJam = 10,
	-- Maximum money you can have.
	maxMoney = 10^12,
	-- Radius you can talk to people in.
	talkRadius = 300,
	-- Server's website.
	serverWebsite = "Arista Framework: http://www.hexahedronic.org/",
	-- Time between 'paydays'.
	earningInterval = 360,
}

arista.config.costs = {
	-- How much doors cost to buy (/2 for refund).
	door = 100,
}

function arista.config:getDefault(var)
	return self.defaults[var]
end

-- todo: do a darkrp style 'dont touch the gamemode' config system.
