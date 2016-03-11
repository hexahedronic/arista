-- A command to give access to a player.
arista.command.add("giveaccess", "s", 2, function(ply, target, flags)
	local victim = arista.player.get(target)

	if not victim then
		return false, "AL_INVALID_TARGET"
	end

	flags:gsub("[asm%s]", "")

	if flags == "" then
		return false
	end

	victim:giveAccess(flags)

	arista.player.notifyAll("AL_PLAYER_GIVEACCESS", ply:Name(), victim:Name(), flags, flags:len() > 1 and "s" or "")
end, "AL_COMMAND_CAT_ADMIN", true)

-- A command to take access from a player.
arista.command.add("takeaccess", "s", 2, function(ply, target, flags)
	local victim = arista.player.get(target)

	if not victim then
		return false, "AL_INVALID_TARGET"
	end

	flags:gsub("[asm%s]", "")

	if flags == "" then
		return false
	end

	victim:takeAccess(flags)

	arista.player.notifyAll("AL_PLAYER_TAKEACCESS", ply:Name(), victim:Name(), flags, flags:len() > 1 and "s" or "")
end, "AL_COMMAND_CAT_ADMIN", true)

-- A command to restart the map.
arista.command.add("restartmap", "a", 0, function(ply)
	for _, pl in ipairs(player.GetAll()) do
		pl:holsterAll()
		pl:saveData()
	end

	timer.Simple(0.1, function() game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n") end)
end, "AL_COMMAND_CAT_ADMIN")
