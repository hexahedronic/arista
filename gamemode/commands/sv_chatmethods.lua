-- A command to privately message a player.
arista.command.add("pm", "", 2, function(ply, target, ...)
	local victim = arista.player.get(target)
	if not victim then
		return false, "AL_INVALID_TARGET"
	elseif victim == ply then
		return false, "AL_CANNOT_PM_SELF"
	end

	local words = table.concat({...}, " "):Trim()
	if not words or words == "" then
		return false, "AL_INVALID_MESSAGE"
	end

	-- Print a message to both players participating in the private message.
	arista.chatbox.add(victim, ply, "pm", words)

	words = "@" .. victim:Name() .. " " .. words
	arista.chatbox.add(ply, ply, "pm", words)
end, "AL_COMMAND_CAT_MENU", true)

-- A command to yell in character.
arista.command.add("y", "", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then
		return false, "AL_INVALID_MESSAGE"
	end

	-- Print a message to other players within a radius of the player's position.
	arista.chatbox.addInRadius(ply, "yell", words, ply:GetPos(), arista.config.vars.talkRadius * 2)
end, "AL_COMMAND_CAT_MENU")

-- A command to do 'me' style text.
arista.command.add("me", "", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then
		return false, "AL_INVALID_MESSAGE"
	end

	ply:emote(words)
end, "AL_COMMAND_CAT_MENU")

-- A command to whisper in character.
arista.command.add("w", "", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then
		return false, "AL_INVALID_MESSAGE"
	end

	-- Print a message to other players within a radius of the player's position.
	arista.chatbox.addInRadius(ply, "whisper", words, ply:GetPos(), arista.config.vars.talkRadius / 2)
end, "AL_COMMAND_CAT_MENU")

-- A command to send an advert to all players.
arista.command.add("advert", "", 1, function(ply, arguments)
	local nextAdvert = ply:getAristaVar("nextAdvert") or 0

	local cost = arista.config.costs.advert
	local money = ply:getMoney()

	if nextAdvert > CurTime() then
		local timeleft = math.ceil(nextAdvert - CurTime())
		local timeType

		if timeleft > 60 then
			timeleft = string.ToMinutesSeconds(timeleft)
			timeType = "AL_MINS"
		else
			timeleft = timeleft
			timeType = "AL_SECONDS"
		end

		return false, "AL_CANNOT_ADVERT", timeleft, timeType
	elseif not ply:canAfford(cost) then
		return false, "AL_NEED_ANOTHER_MONEY", cost - money
	end

	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then
		return false, "AL_INVALID_MESSAGE"
	end

	ply:setAristaVar("nextAdvert", CurTime() + arista.config.vars.advertCoolDown)

	-- Print a message to all players.
	arista.chatbox.add(nil, ply, "advert", words)
	ply:giveMoney(-cost)
end, "AL_COMMAND_CAT_MENU")

-- A command to send a message to all players on the same team.
arista.command.add("radio", "", 1, function(ply, arguments)
	local text = table.concat(arguments, " ")

	-- Say a message as a radio broadcast.
	ply:sayRadio(text)
end, "AL_COMMAND_CAT_MENU")

arista.command.add("ooc", "", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then return false, "AL_WAT" end

	if gamemode.Call("PlayerCanSayOOC", ply, words) ~= false then
		arista.chatbox.add(nil, ply, "ooc", words)
	else
		return false
	end
end, "AL_COMMAND_CAT_MENU")

arista.command.add("looc", "", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then return false, "AL_WAT" end

	if gamemode.Call("PlayerCanSayLOOC", ply, words) ~= false then
		arista.chatbox.addInRadius(ply, "looc", words , ply:GetPos())
	else
		return false
	end
end, "AL_COMMAND_CAT_MENU")

arista.command.add("a", "a", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then return false, "AL_WAT" end

	local rp = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:IsAdmin() then
			rp[#rp+1] = ply
		end
	end

	arista.chatbox.add(rp, ply, "achat", words)
end, "AL_COMMAND_CAT_MENU")

arista.command.add("m", "m", 1, function(ply, arguments)
	local words = table.concat(arguments, " "):Trim()
	if not words or words == "" then return false, "AL_WAT" end

	local rp = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:IsAdmin() then
			-- todo: mod
			rp[#rp+1] = ply
		end
	end

	arista.chatbox.add(rp, ply, "mchat", words)
end, "AL_COMMAND_CAT_MENU")

arista.command.add("action", "", 1, function(ply, arguments)
	local text = table.concat(arguments, " "):Trim()

	-- Check if the there is enough text.
	if text == "" then
		return false, "AL_CANNOT_NOTENOUGHTEXT"
	end

	arista.chatbox.addInRadius(ply, "action", text, ply:GetPos(), arista.config.vars.talkRadius)
end, "AL_COMMAND_CAT_MENU")
