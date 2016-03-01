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
}

arista.logs.colors = {
	arista =  Color(255, 215, 0, 255),
	grey = Color(200, 200, 200, 255),
	white = Color(255, 255, 255, 255),
}

function arista.logs.log(level, ...)
	MsgC(arista.logs.colors.arista, "[ arista ] ", arista.logs.colors.grey, level .. ": ", arista.logs.colors.white, ...)
	MsgN()
end

function arista.logs.logNoPrefix(level, ...)
	MsgC(arista.logs.colors.grey, level .. ": ", arista.logs.colors.white, ...)
	MsgN()
end

function arista.logs.event(level, type, ...)
	MsgC(arista.logs.colors.grey, level .. " | " .. type .. ": ", arista.logs.colors.white, ...)
	MsgN()
end
