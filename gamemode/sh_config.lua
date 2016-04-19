AddCSLuaFile()

arista.config = {}

-- Default stuff.
arista.config.defaults = {
	-- The job that each player starts with.
	job = "Citizen",
	-- Time knocked out for.
	knockOutTime = 30,
	-- Time until respawn.
	spawnTime = 20,
	-- Time arrested for.
	arrestTime = 300,
	-- Access level.
	access = "tpe",
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
	-- Default rpnames.
	rpnames = {
		first = {
			male = {
				"John",
				"Henry",
				"Michael",
				"Paul",
				"Andrew",
				"Dean",
			},
			female = {
				"Ann",
				"Stacey",
				"Sue",
				"Ava",
				"Wendy",
				"Mary",
				"Sarah",
				"Felicity",
			},
		},
		surnames = {
			"Smith",
			"Doe",
			"Cors",
			"Clark",
			"Johnson",
			"Goodeve",
		},
	}
}

-- Enums, change only if something real weird happens.
TYPE_LARGE = "large"
TYPE_SMALL = "small"

arista.config.timers = {
	["deploytime"] = {
		[TYPE_LARGE] = 2,
		[TYPE_SMALL] = 1
	},
	["redeploytime"] = {
		[TYPE_LARGE] = 30,
		[TYPE_SMALL] = 20
	},
	["reholstertime"] = {
		[TYPE_LARGE] = 10,
		[TYPE_SMALL] = 5
	},
	["deploymessage"] = { -- 1 gun type, 2 gender
		[TYPE_LARGE] = "pulls a %s off <P> back",
		[TYPE_SMALL] = "pulls a %s out of <P> pocket"
	},
	["equiptime"] = {
		[TYPE_LARGE] = 5,
		[TYPE_SMALL] = 2
	},
	["equipmessage"] = {
		["Start"] = "starts rummaging through <P> backpack",
		["Final"] = "pulls out a %s gun and puts <P> backpack back on",
		["Abort"] = "gives up and pulls <P> backpack back on",
		["Plugh"] = "slides the %s gun back into <P> backpack and puts it back on"
	},
	["holstermessage"] = {	 -- 1 gun type, 2 gender
		[TYPE_LARGE] = "puts the %s back on <P> back",
		[TYPE_SMALL] = "puts the %s back in <P> pocket"
	}
}

arista.config.vars = {
	-- Weapon types carried on the back.
	backWeapons =
	{
		[TYPE_LARGE] = true
	},
	-- Maximum amount of each weapon type.
	maxWeapons = {
		[TYPE_LARGE] = 1,
		[TYPE_SMALL] = 2,
	},
	-- How long it takes to fall asleep.
	sleepDelay = 5,
	-- How many players are needed as a minimum for a mutiny.
	minimumMutiny = 5,
	-- How much of the gang must agree for a mutiny.
	mutinyPercent = 0.75,
	-- Access for donators.
	donatorAccess = "tpew",
	-- Use localised voice chat.
	localVoice = true,
	-- Amount to multiply donators salary by.
	donatorMult = 2,
	-- If you want to stop props killing people.
	preventPropKill = true,
	-- Amount of time (by default) people should bleed for.
	bleedTime = 3,
	-- Respective hitgroup region damage multipliers.
	headDmgScale = 2.5,
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
	-- Time taken to tie up a player.
	tyingTime = 5,
	-- Time taken to untie a player.
	untyingTime = 8,
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
	serverWebsite = "arista rp framework",
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
	useMasterGroup = false,
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
		["models/props/de_train/lockers_long.mdl"] 									= {100,"A lot of lockers"},
		["models/props_c17/furnituredrawer001a.mdl"] 								= {30,"Chest of Drawers"},
		["models/props/de_inferno/furnituredrawer001a.mdl"] 				= {30,"Chest of Drawers"},
		["models/props_lab/partsbin01.mdl"] 												= {10,"Chest of Drawers"},
		["models/props_c17/furnituredrawer003a.mdl"] 								= {20,"Chest of Drawers"},
		["models/props_lab/filecabinet02.mdl"] 											= {20,"Filing Cabinet"},
		["models/props_wasteland/controlroom_filecabinet001a.mdl"]	= {20,"Filing Cabinet"},
		["models/props_wasteland/controlroom_filecabinet002a.mdl"]	= {30,"Filing Cabinet"},
		["models/props/cs_office/file_cabinet1.mdl"] 								= {20,"Filing Cabinet"},
		["models/props/cs_office/file_cabinet1_group.mdl"] 					= {50,"Filing Cabinet"},
		["models/props/cs_office/file_cabinet2.mdl"]	 							= {20,"Filing Cabinet"},
		["models/props/cs_office/file_cabinet3.mdl"] 								= {15,"Filing Cabinet"},
		["models/props/de_nuke/file_cabinet1_group.mdl"] 						= {50,"Filing Cabinet"},
		["models/props_wasteland/controlroom_storagecloset001a.mdl"]= {60,"Storage Closet"},
		["models/props_wasteland/controlroom_storagecloset001b.mdl"]= {60,"Storage Closet"},
		["models/props_interiors/furniture_vanity01a.mdl"] 					= {5,"Dressing Table"},
		["models/props/cs_militia/footlocker01_closed.mdl"] 				= {40,"Foot Locker"},
		["models/props/de_prodigy/ammo_can_02.mdl"] 								= {20,"Foot Locker"},
		["models/props_c17/briefcase001a.mdl"] 											= {20,"Briefcase"},
		["models/props_junk/trashdumpster01a.mdl"] 									= {40,"Dumpster"},
		["models/props_c17/furnituredresser001a.mdl"] 							= {40,"Wardrobe"},
		["models/props_c17/suitcase001a.mdl"] 											= {20,"Suitcase"},
		["models/props_c17/suitcase_passenger_physics.mdl"] 				= {10,"Suitcase"},
		["models/props/de_train/lockers001a.mdl"] 									= {40,"Lockers"},
		["models/props_c17/lockers001a.mdl"]												= {40,"Lockers"},
		["models/props_interiors/furniture_cabinetdrawer01a.mdl"]		= {20,"Cabinet"},
		["models/props_interiors/furniture_cabinetdrawer02a.mdl"]		= {20,"Dresser"},
		["models/props_c17/furniturefridge001a.mdl"] 								= {30,"Fridge"},
		["models/props_wasteland/kitchen_fridge001a.mdl"] 					= {60,"Fridge"},
		["models/props/cs_militia/refrigerator01.mdl"] 							= {50,"Fridge"},
		["models/props_foliage/tree_stump01.mdl"] 									= {40,"Stump"},
		["models/props_c17/furnituredrawer002a.mdl"] 								= {10,"Table"},
		["models/props_junk/trashbin01a.mdl"] 											= {10,"Bin"},
		["models/props_wasteland/kitchen_stove001a.mdl"]						= {5, "Oven"},
		["models/props_wasteland/kitchen_stove002a.mdl"]						= {5, "Oven"},
		["models/props_c17/furniturewashingmachine001a.mdl"]				= {5, "Washing Machine"},
	},
	-- Any default items not to load.
	disabledItems = {
		["misc/test"] = true,
	},
	-- Any default plugins not to load.
	disabledPlugins = {
		["test"] = true,
	},
	-- Models that are blocked (if no prop protection addon is suplied).
	blockedModels = {
		"models/cranes/crane_frame.mdl",
	},
	-- Force blocked models even if prop protection handles it.
	forceBlockedModels = true,
	-- If arrested people can get into cars (eg for being driven to jail).
	allowArrestedCars = true,
	-- Should fire spread?
	fireSpread = true,
	-- The maximum amount of fires that can exist at once.
	maxFires = 50,
	-- Any props that when burnt 'add fuel to the fire'.
	fireProps = {
		["models/props_c17/oildrum001_explosive.mdl"] = 5,
		["models/props_junk/propanecanister001a.mdl"] = 3,
		["models/props_junk/propane_tank001a.mdl"] = 4,
		["models/props_junk/gascan001a.mdl"] = 7,
	},
	-- Sounds played when using the radio.
	combineJibberish = {
		"npc/metropolice/vo/get11-44inboundcleaningup.wav",
		"npc/metropolice/vo/dispreportssuspectincursion.wav",
		"npc/metropolice/vo/clearno647no10-107.wav",
		"npc/metropolice/vo/possible10-103alerttagunits.wav",
		"npc/metropolice/vo/malcompliant10107my1020.wav",
		"npc/metropolice/vo/Ivegot408hereatlocation.wav",
		"npc/metropolice/vo/Ihave10-30my10-20responding.wav",
	},
}

arista.config.plugins = {
	-- STAMINA: How much stamina to restore per interval.
	staminaRestore = 0.5,
	-- STAMINA: How much stamina to drain per interval.
	staminaDrain = 0.3,
	-- STAMINA: How much stamina to drain for a punch.
	staminaPunch = 5,
	-- STAMINA: How much stamina to drain for a jump.
	staminaJump = 5,

	-- HUNGERMOD: How much hunger to drain per second.
	hungerDrain = 0.05,
	-- HUNGERMOD: How low must the hunger be before the player starves.
	hungerStarve = 1,
	-- HUNGERMOD: How low must the hunger be before the 'hungry' debuff.
	hungerHungry = 5,
	-- HUNGERMODE: How much damage to take per interval when starving.
	hungerDamage = 2,

	-- OFFICALS: How long should the mayor/president have god mode for?
	officalsMayorGod = 60,
	-- OFFICALS: The maximum value tax can be set to.
	officalsMaxTax = 20,
	-- OFFICALS: Default amount of tax.
	officalsDefaultTax = 0,
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
