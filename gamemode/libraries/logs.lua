AddCSLuaFile()

arista.logs = {}

arista.logs.E = {
	DEBUG = "Debug",
	LOG = "Log",
	WARNING = "Warning",
	ERROR = "Error",
	FATAL = "Fatal",

	ARREST = "Arrest",
	DAMAGE = "Damage",
	KILL = "Kill",
	JOB = "Job",
	SPAWN = "Spawn",
	USE = "Use",
	NETEVENT = "Net Event",
	JOB = "Job",
	COMMAND = "Command",
	ITEM = "Item",
}

arista.logs.colors = {
	arista =  Color(255, 215, 0, 255),
	grey = Color(200, 200, 200, 255),
	white = Color(255, 255, 255, 255),
}

local levelValues = {
	[arista.logs.E.DEBUG] = 1,
	[arista.logs.E.LOG] = 2,
	[arista.logs.E.WARNING] = 3,
	[arista.logs.E.ERROR] = 4,
	[arista.logs.E.FATAL] = 5,
}

local function canPrint(level)
	return (levelValues[level] or 2) >= (levelValues[arista.config.vars.warningLevel] or 2)
end

function arista.logs.log(level, ...)
	if not canPrint(level) then return end
	MsgC(arista.logs.colors.arista, "[ arista ] ", arista.logs.colors.grey, level .. ": ", arista.logs.colors.white, ...)
	MsgN("")
end

function arista.logs.logNoPrefix(level, ...)
	if not canPrint(level) then return end
	MsgC(arista.logs.colors.grey, level .. ": ", arista.logs.colors.white, ...)
	MsgN("")
end

function arista.logs.event(level, type, ...)
	if not canPrint(level) then return end
	MsgC(arista.logs.colors.grey, level .. " | " .. type .. ": ", arista.logs.colors.white, ...)
	MsgN("")
end
