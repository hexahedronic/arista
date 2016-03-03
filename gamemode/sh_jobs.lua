AddCSLuaFile()

--[[
Example of how to do a job:

TEAM_POLICEOFFICER = arista.team.add("Police Officer", {
	color = Color(100, 155, 255, 255),
	males = "models/player/riot.mdl",
	description = "Maintains the city and arrests criminals.",
	salary = 250,
	limit = 15,
	access = "",
	blacklist = nil,
	group = {
		gang = GANG_POLICE,
		access = "",
		level = 1,--2, -- not base group, but we dont have other jobs so for now
		group = GROUP_OFFICIALS,
	},
	cantuse = {
		CATEGORY_ILLEGAL_GOODS,
		CATEGORY_ILLEGAL_WEAPONS,
		CATEGORY_EXPLOSIVES,
	},
	canmake = nil,
	guns = {"cider_baton"},
	ammo = {
		{"pistol", 60},
	},
	timelimit = nil,
	waiting = nil,
})
]]

--[[
Access flags:
b = boss - can demote members of the same level. Restricted to a gang if used on a gang member
d = demote members of lower level. Restricted to a gang if used on a gang member
g = can give/take ents to/from gang
D = underlings can vote to depose
M = All group-to-group transitions must go through this.

Old format:
(name,color,males,females,group,description,salary,limit,access,blacklist,canmake,cantuse,time,guns,ammo)
]]

GROUP_CIVILIANS	= arista.team.addGroup("Civilians", "Join the ordinary and (generally) law-abiding civilians")
GANG_CIVILIANS	= arista.team.addGang(GROUP_CIVILIANS, "The Civilians", "models/player/Group01/male_07.mdl", "Keep me out of this!")

TEAM_CITIZEN = arista.team.add("Citizen", {
	color = Color(25, 150, 25, 255),
	description = "A regular Citizen living in the city.",

	salary = 200,

	access = "",

	group = {
		gang = GANG_CIVILIANS,
		access = "M",
		level = 1,
		group = GROUP_CIVILIANS,
	},
	cantuse = {CATEGORY_ILLEGAL_GOODS, CATEGORY_ILLEGAL_WEAPONS, CATEGORY_EXPLOSIVES, CATEGORY_POLICE_WEAPONS},
})

GROUP_OFFICIALS	= arista.team.addGroup("Officials", "Join the force for 'Public Good', maintaining law and order.", "P")

GANG_OFFICIALS	= arista.team.addGang(GROUP_OFFICIALS, "The Officials", "models/player/breen.mdl", "Enough red tape to drown a continent")
GANG_POLICE			= arista.team.addGang(GROUP_OFFICIALS, "The Police", "models/player/riot.mdl", "Less talk, more action!")

TEAM_POLICEOFFICER = arista.team.add("Police Officer", {
	color = Color(100, 155, 255, 255),
	males = "models/player/riot.mdl",
	description = "Maintains the city and arrests criminals.",

	salary = 250,
	limit = 15,

	access = "",

	guns = {"cider_baton"},
	ammo = {
		pistol = 60,
	},

	group = {
		gang = GANG_POLICE,
		access = "",
		level = 1,--2, -- not base group, but we dont have other jobs so for now
		group = GROUP_OFFICIALS,
	},
	cantuse = {CATEGORY_ILLEGAL_GOODS, CATEGORY_ILLEGAL_WEAPONS, CATEGORY_EXPLOSIVES},
})

TEAM_DEFAULT = TEAM_CITIZEN
