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
	access = "",
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
	jobWait = 5 * 60,
	-- Default laws.
	laws = [[
[Permanent Laws0]
Contraband is illegal. Anyone found with it will be arrested. Any police found with it will be demoted on the spot.
Murder is illegal.
Assault is illegal.
Discrimination is illegal.
Breaking into other people's property is illegal.
Stealing cars is illegal.
Explosives are illegal.
Tying people up without their explicit consent is illegal.
[Temporary Laws1]
]],
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
	-- Used to block players from certain jobs and whatnot, don't touch it.
	blacklist = {},
	-- Used to store items, don't touch it.
	inventory = {},
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
	serverWebsite = "arista RolePlay: http://www.hexahedronic.org/",
	-- Time between 'paydays'.
	earningInterval = 360,
	-- Comamnd prefix.
	commandPrefix = "/",
	-- Commands you can allways use.
	persistantCommands = {
		"demote", "blacklist", "unblacklist", "giveaccess", "takeaccess", "giveitem", "save", "pm", "job", "clan", "gender",
		"laws", "ooc", "looc", "knockout", "knockoutall", "wakeup", "wakeupall", "arrest", "unarrest", "spawn", "awarrant",
		"tie", "untie",
	},
	-- Prop limit for builders.
	builderPropLimit = 15,
	-- If we have a team you must pass through to join another group.
	useMasterGroup = true,
	-- How many seconds between item uses.
	itemUseDelay = 3,
	-- How many seconds between uses of a SPECIFIC item.
	specficItemDelay = 6,
	-- How many seconds to wait before allowing OOC chat again.
	oocCoolDown = 2,
	-- How many seconds to wait before allowing an advert again.
	advertCoolDown = 5,
	-- What models are automatically containers. [model] = {size, name}
	containerModels = {
		["models/props_c17/furnituredresser001a.mdl"] = {20, "Wardrobe"},
	},
	-- Models that are blocked (if no prop protection addon is suplied).
	blockedModels = {
		"models/cranes/crane_frame.mdl",
	},
	-- Force blocked models even if prop protection handles it.
	forceBlockedModels = true,
	-- If arrested people can get into cars (eg for being driven to jail).
	allowArrestedCars = true,
}

arista.config.plugins = {
	-- STAMINA: How much stamina to restore per interval.
	staminaRestore = 0.3,
	-- STAMINA: How much stamina to drain per interval.
	staminaDrain = 0.6,
	-- STAMINA: How much stamina to drain for a punch.
	staminaPunch = 15,
	-- STAMINA: How much stamina to drain for a jump.
	staminaJump = 10,
}

arista.config.costs = {
	-- How much doors cost to buy (/2 for refund).
	door = 100,
	-- How much do props cost to buy (for builders).
	prop = 100,
	-- How much does an advert cost.
	advert = 250,
}

function arista.config:getDefault(var)
	return self.defaults[var]
end

-- todo: do a darkrp style 'dont touch the gamemode' config system.
