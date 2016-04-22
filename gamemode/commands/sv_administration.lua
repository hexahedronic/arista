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

	timer.Simple(1, function() game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n") end)
end, "AL_COMMAND_CAT_ADMIN")

-- All commands excluding note (i intend to change this a fair bit) and abuse commands
-- abuse commands will be returning but I need to focus more on this stuff atm
local function getnamething(kind, thing)
	if kind == "team" then
		-- Team blacklist
		local team = arista.team.get(thing)

		if not team	then return false, "AL_INVALID_TEAM"
		elseif not team.blacklist	then return false, "AL_X_ISNT_BLACKLISTABLE", team.name
		end

		return team.name, team.index
	elseif kind == "item" then
	-- Item blacklist
		local  item = GAMEMODE:GetItem(thing)
		if not item then return false, "AL_INVALID_ITEM" end

		return item.name, item.uniqueID
	elseif kind == "cat" then
	-- Category blacklist
		local  cat = GAMEMODE:GetCategory(thing)
		if not cat then return false, "AL_INVALID_CATEGORY" end

		return cat.name, cat.index
	elseif kind == "cmd" then
	-- Command blacklist
		local cmd = arista.command.stored[thing]
		if not cmd then return false, "AL_INVALID_COMMAND" end

		return thing, thing
	else
		return false, "AL_INVALID_BLACKLIST", thing
	end
end

local function getBlacklistTime(time)
	if time >= 1440 then
		return math.ceil(time / 1440), "AL_DAYS"
	elseif time >= 60 then
		return math.ceil(time / 60), "AL_HOURS"
	else
		return time, "AL_MINS"
	end
end

-- A command to blacklist a player from a team.
--/blacklist chronic team police 0 "asshat"
-- team/item/cat/cmd
--<name> <type> <thing> <time> <reason>
--TODO: Make a vgui to handle this shit.
arista.command.add("blacklist", "m", 5, function(ply, target, kind, thing, time, ...)
	local victim = arista.player.get(target)
	if not victim then
		return false, "AL_INVALID_TARGET", target
	end

	local kind, thing, time = string.lower(kind), string.lower(thing), tonumber(time)

	if not time then return false end

	if time < 1 then
		return false, "AL_CANNOT_BLACKLIST_SHORT"
	elseif (time > 10080 and not ply:IsSuperAdmin()) or (time > 1440 and not ply:IsAdmin()) then
		return false, "AL_CANNOT_BLACKLIST_LONG"
	end

	local reason = table.concat({...}, " "):sub(1, 65):Trim()
	if not reason or reason == "" or (reason:len() < 5 and not ply:IsSuperAdmin()) then
		return false, "AL_CANNOT_NOREASON"
	end

	-- Get the name of what we're doing and the thing itself.
	local name, thing, form = getnamething(kind, thing)
	if not name then
		return false, thing, form
	end

	if victim:isBlacklisted(kind, thing) ~= 0 then
		return false, "AL_X_IS_ALREADY_BLACKLISTED", victim:Name()
	end

	if gamemode.Call("PlayerCanBlacklist", ply, victim, kind, thing, time, reason) == false then
		return false
	end

	gamemode.Call("PlayerBlacklisted", victim, kind, thing, time, reason, ply)

	victim:blacklist(kind, thing, time, reason, ply:Name())

	local timeSuffix
	time, timeSuffix = getBlacklistTime(time)
	arista.player.notifyAll("AL_X_BLACKLIST_X_FROM_X_FOR_X_BECAUSE_X", ply:Name(), victim:Name(), name, time, timeSuffix, reason)
end, "AL_COMMAND_CAT_MOD", true) -- AL_COMMAND_CAT_MOD

arista.command.add("unblacklist", "m", 3, function(ply, target, kind, thing)
	local victim = arista.player.get(target)
	if not victim then
		return false, "AL_INVALID_TARGET", target
	end

	local kind, thing = string.lower(kind), string.lower(thing)

	-- Get the name of what we're doing and the thing itself.
	local name, thing, form = getnamething(kind, thing)
	if not name then
		return false, thing, form
	end

	if victim:isBlacklisted(kind, thing) == 0 then
		return false, "AL_PLAYER_NOTBLACKLISTED", victim:Name()
	end

	if gamemode.Call("PlayerCanUnBlacklist", ply, victim, kind, thing) == false then
		return false
	end

	gamemode.Call("PlayerUnBlacklisted", victim, kind, thing, ply)

	victim:unBlacklist(kind, thing)

	arista.player.notifyAll("AL_X_UNBLACKLIST_X_FROM_X", ply:Name(), victim:Name(), name)
end, "AL_COMMAND_CAT_MOD", true) -- AL_COMMAND_CAT_MOD

arista.command.add("blacklistlist", "m", 1, function(ply, target)
	local victim = arista.player.get(target)
	if not victim then
		return false, "AL_INVALID_TARGET", target
	end

	local blacklist = victim:getAristaVar("blacklist") or {}
	if table.Count(blacklist) == 0 then
		return false, "AL_X_NOT_BLACKLISTED_ANYTHING", victim:Name()
	end

	local printtable, words = {}
	local namelen, adminlen, timelen = 0, 0, 0
	local time, name, admin, reason

	for kind, btab in pairs(blacklist) do
		if table.Count(btab) ~= 0 then
			words = {}

			for thing in pairs(btab) do
				time, reason, admin = victim:isBlacklisted(kind, thing)

				if tonumber(time) and time ~= 0 then
					name = getnamething(kind, thing)
					time = getBlacklistTime(time)

					if name:len() > namelen then namelen = name:len() end
					if admin:len() > adminlen then adminlen = admin:len() end
					if time > timelen then timelen = time  end

					words[#words + 1] = {name, time, admin, reason}
				end
			end

			if #words ~= 0 then
				printtable[#printtable + 1] = {kind, words}
			end
		end
	end

	if #printtable == 0 then
		return false, "AL_X_NOT_BLACKLISTED_ANYTHING", victim:Name()
	end

	local a, b, c = ply.PrintMessage, ply, HUD_PRINTCONSOLE

	-- A work of art in ASCII formatting. A shame it is soon to be swept away
	a(b,c, "----------------------------[ Blacklist Details ]-----------------------------")

	local w = "%-" .. namelen + 2 .. "s| %-" .. timelen + 2 .. "s| %-" .. adminlen + 2 .. "s| %s"
	a(b, c, w:format("Thing", "Time", "Admin", "Reason"))

	for _, t in ipairs(printtable) do
		a(b, c, "-----------------------------------[ " .. string.format("%-4s", t[1]) .. " ]------------------------------------")

		for _, t in ipairs(t[2]) do
			a(b, c, w:format(t[1], t[2], t[3], t[4]))
		end
	end

	ply:notify("AL_BLACKLISTDETAILS")
end, "AL_COMMAND_CAT_MOD", true) -- AL_COMMAND_CAT_MOD

-- A command to give Donator status to a player.
arista.command.add("donator", "s", 1, function(ply, target, days)
	local victim = arista.player.get(target)

	-- Check if we got a valid target.
	if not victim then
		return false, "AL_INVALID_TARGET", target
	end

	-- Calculate the days that the player will be given Donator status for.
	local days = math.ceil(tonumber(days) or 30)

	victim:setAristaVar("donator", os.time() + (86400 * days))

	-- Give them their access and save their data.
	victim:setupDonator(true)
	victim:saveData()

	-- Give them the tool and the physics gun.
	if victim:hasAccess("t") then victim:Give("gmod_tool") end
	if victim:hasAccess("p") then victim:Give("weapon_physgun") end

	-- Print a message to all players about this player getting Donator status.
	arista.player.notifyAll("AL_X_GIVE_X_DONATOR_X_DAYS", ply:Name(), victim:Name(), days)
end, "AL_COMMAND_CAT_SADMIN", true) -- AL_COMMAND_CAT_SADMIN

arista.command.add("globalaction", "m", 1, function(ply,arguments)
	local text = table.concat(arguments, " ")

	-- Check if the there is enough text.
	if text == "" then
		return false, "AL_CANNOT_NOTENOUGHTEXT"
	end

	arista.chatbox.add(nil, ply, "gaction", text)
end, "AL_COMMAND_CAT_MOD")

-- Set an ent's master
arista.command.add("setmaster", "s", 1, function(ply, masterID)
	local entity = ply:GetEyeTraceNoCursor().Entity
	local master = Entity(masterID)

	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then
		return false, "AL_INVALID_ENTITY"
	elseif not ((IsValid(master) and arista.entity.isOwnable(master)) or masterID == 0) then
		return false, "AL_INVALID_ENTITY"
	end

	if masterID == 0 then
		master = NULL
	end

	arista.entity.setMaster(entity, master)
end, "AL_COMMAND_CAT_SADMIN", true)

-- Seal a door
arista.command.add("seal", "s", 0, function(ply, unseal)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then
		return false, "AL_INVALID_ENTITY"
	end

	entity:seal(unseal ~= nil)
end, "AL_COMMAND_CAT_SADMIN", true)

arista.command.add("setname", "s", 1, function(ply, arguments)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (IsValid(entity) and arista.entity.isOwnable(entity) and entity._isDoor) then
		return false, "AL_INVALID_DOOR"
	end

	local words = table.concat(arguments," "):Trim():sub(1, 25)
	if not words or words == "" then
		words = ""
	end

	arista.entity.setName(entity, words)
end, "AL_COMMAND_CAT_SADMIN")

arista.command.add("setowner", "s", 1, function(ply, kind, id, gangid)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (IsValid(entity) and arista.entity.isOwnable(entity) and entity._isDoor) then
		return false, "AL_INVALID_DOOR"
	end

	entity = arista.entity.getMaster(entity) or entity

	local target
	local name
	if kind == "player" then
		target = arista.player.get(id)
		if not target then return false, "AL_INVALID_TARGET" end

		arista.entity.setOwnerPlayer(entity, target)
		name = target:Name()
	elseif kind == "team" then
		target = arista.team.get(id)
		if not target then return false, "AL_INVALID_TEAM" end

		name = target.name
		target = target.index
		arista.entity.setOwnerTeam(entity, target)
	elseif kind == "gang" and gangid then
		id = tonumber(id)
		gangid = tonumber(gangid)
		if not (arista.team.gangs[id] and arista.team.gangs[id][gangid]) then
			return false, "AL_INVALID_GANG"
		end

		arista.entity.setOwnerGang(entity, id, gangid)
		name = arista.team.gangs[id][gangid].name
		target = {id, gangid}
	elseif kind == "remove" then
		arista.entity.clearData(entity, true)
		target = ""
	end

	if not target then
		return false, "AL_INVALID_TARGET"
	end

	arista.entity.updateSlaves(entity)
end, "AL_COMMAND_CAT_SADMIN", true)

arista.command.add("save", "s", 0, function(ply)
	arista.player.saveAll()
end, "AL_COMMAND_CAT_SADMIN")

arista.command.add("firespread", "s", 0, function(ply, b)
	b = tobool(b)
	arista.config.vars.fireSpread = b
	ply:notify("AL_COMMAND_FIRESPREAD_" .. (b and "ENABLE" or "DISABLE"))
end, "AL_COMMAND_CAT_SADMIN", true)
