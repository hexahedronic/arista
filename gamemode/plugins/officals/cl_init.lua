include("sh_init.lua")

local arrestwarrant = Color(255, 50, 50, 255)
local spawnimmunity = Color(150, 255, 75, 255)

local function drawinfo(x, y, width, height)
	return x - width - 8, y
end

arista.lang:Add("AL_OFFICALS_LOCKDOWN", {
	EN = "A lockdown is in progress. Please return to your home.",
})

arista.lang:Add("AL_OFFICALS_IMMUNITY", {
	EN = "You have spawn immunity for %s second(s).",
})

arista.lang:Add("AL_OFFICALS_ARREST_NOACCESS", {
	EN = "You do not have access to arrest this player!",
})

arista.lang:Add("AL_OFFICALS_STUN_NOACCESS", {
	EN = "You do not have access to stun this player!",
})

arista.lang:Add("AL_OFFICALS_KNOCKOUT_NOACCESS", {
	EN = "You do not have access to knock out this player!",
})

arista.lang:Add("AL_OFFICALS_WAKEUP_NOACCESS", {
	EN = "You do not have access to wake up this player!",
})

arista.lang:Add("AL_OFFICALS_UNARREST_NOACCESS", {
	EN = "You do not have access to unarrest this player!",
})

arista.lang:Add("AL_OFFICALS_CANNOT_REQUEST", {
	EN = "There is no one to hear your request!",
})

arista.lang:Add("AL_COMMAND_TAX", {
	EN = "Set the tax rate for the city.",
})

arista.lang:Add("AL_COMMAND_TAX_HELP", {
	EN = "<percent>",
})

arista.lang:Add("AL_COMMAND_BROADCAST", {
	EN = "Send a global message to everyone.",
})

arista.lang:Add("AL_COMMAND_BROADCAST_HELP", {
	EN = "<message>",
})

-- Called when the top text should be drawn.
function PLUGIN:DrawTopText(text)
	if GetGlobalBool("lockdown") then
		text.y = GAMEMODE:DrawInformation(arista.lang:Get"AL_OFFICALS_LOCKDOWN", "ChatFont", text.x, text.y, arrestwarrant, 255, true, drawinfo)
	end

	local team = arista.team.get(arista.lp:Team())
	if not team then return end

	-- Check if the player is the Mayor.
	if not team.mayor then
		return
	end

	local spawntime = math.floor((arista.lp:getAristaInt("spawnImmunityTime") or 0) - CurTime())
	if spawntime > 0 then
		text.y = GAMEMODE:DrawInformation(arista.lang:Get("AL_OFFICALS_IMMUNITY", spawntime), "ChatFont", text.x, text.y, spawnimmunity, 255, true, drawinfo);
	end
end