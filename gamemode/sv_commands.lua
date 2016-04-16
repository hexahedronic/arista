-- Load specific command types to keep this file cleaner.
arista.file.loadDir("commands/", "Command Library", "Command Libraries")

-- An important. (Very important, do not remove.)
arista.command.add("fuck", "", 0, function(p)
	p:notify("AL_FUCK")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your job title
arista.command.add("job", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "" or words == "none" or words == "default" then
		words = team.GetName(ply:Team())
	end

	ply:setAristaVar("job", words)

	ply:notify("AL_YOU_CHANGE_JOB", words)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their job name to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your clan.
arista.command.add("clan", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "quit" or words == "none" then
		words = ""
	end

	ply:setAristaVar("clan", words)

	if words == "" then
		ply:notify("AL_YOU_REMOVE_CLAN")
	else
		ply:notify("AL_YOU_CHANGE_CLAN", words)
	end
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their clan to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your clan.
arista.command.add("name", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "random" or words == "default" then
		ply:generateDefaultRPName()
	return end

	if words:match("%p") or words:match("%d") or words:len() < 7 then return end

	ply:setAristaVar("rpname", words)

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their name to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your clan.
arista.command.add("details", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if words == "" or words:lower() == "none" then
		ply:setAristaVar("details", "")

		-- Print a message to the player.
		ply:notify("AL_YOU_REMOVE_DETAILS")
	else
		ply:setAristaVar("details", words)

		-- Print a message to the player.
		ply:notify("AL_YOU_CHANGE_DETAILS", words)
	end

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their details to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to give a player some money.
arista.command.add("givemoney", "", 1, function(ply, amt)
	local victim = ply:GetEyeTraceNoCursor().Entity
	if not (IsValid(victim) and victim:IsPlayer()) then
		return false, "AL_INVALID_TARGET"
	end

	amt = tonumber(amt)
	if not amt or amt < 1 then
		return false, "AL_INVALID_AMOUNT"
	end

	amt = math.floor(amt)
	if not ply:canAfford(amt) then
		return false, "AL_YOU_NOT_ENOUGHMONEY"
	end

	ply:giveMoney(-amt)
	victim:giveMoney(amt)

	ply:emote("hands <N> a wad of money.", victim)

	ply:notify("AL_PLAYER_YOU_GAVE", victim:Name(), amt)
	victim:notify("AL_PLAYER_GAVE_YOU", ply:Name(), amt)
end, "AL_COMMAND_CAT_COMMANDS", true)

-- A command to drop money.
local moneyDist = 255^2
arista.command.add("dropmoney", "", 1, function(ply, amt)
	-- Prevent fucktards spamming the dropmoney command.
	ply._nextMoneyDrop = ply._nextMoneyDrop or 0

	if ply._nextMoneyDrop > CurTime() then
		return false, "AL_CANNOT_DROPMONEY_FAST", ply._nextMoneyDrop - CurTime()
	end

	local pos = ply:GetEyeTraceNoCursor().HitPos
	if ply:GetPos():DistToSqr(pos) > moneyDist then
		pos = ply:GetShootPos() + ply:GetAimVector() * 255
	end

	amt = tonumber(amt)
	if not amt or amt < 1 then
		return false, "AL_INVALID_AMOUNT"
	end

	amt = math.floor(amt)

	if not ply:canAfford(amt) then
		return false, "AL_YOU_NOT_ENOUGHMONEY"
	elseif amt < 50 then -- Fucking spammers again.
		return false, "AL_YOU_NOT_DROPENOUGH", 50
	end

	ply._nextMoneyDrop = CurTime() + 10
	ply:giveMoney(-amt)

	arista.item.items["money"]:make(pos, amt):CPPISetOwner(ply)
end, "AL_COMMAND_CAT_COMMANDS", true)

-- A command to demote a player.
arista.command.add("demote", "", 2, function(ply, target, ...)
	local victim = arista.player.get(target)
	if not victim then
		return false, "AL_INVALID_TARGET"
	end

	local reason = table.concat({...}, " "):sub(1, 65):Trim()
	if not reason or reason == "" or (reason:len() < 5 and not ply:IsSuperAdmin()) then
		return false, "AL_CANNOT_NOREASON"
	end

	if gamemode.Call("PlayerCanDemote", ply, victim) == false then
		return false
	end

	local tid = victim:Team()
	victim:demote()

	arista.player.notifyAll("AL_PLAYER_DEMOTED", nil, ply:Name(), victim:Name(), team.GetName(tid), reason)
end, "AL_COMMAND_CAT_COMMANDS", true)

do --isolate vars
	local function conditional(ply, pos)
		return ply:IsValid() and ply:GetPos() == pos
	end

	local function success(ply, _, class)
		if not ply:IsValid() then return end
		ply._equipping = false

		local s, f, c, d = arista.inventory.update(ply, class, 1)
		if not s then
			ply:emote(arista.config.timers["Equip Message"]["Abort"])

			if f and f ~= "" then
				ply:notify(f, c, d)
			end

			return
		end

		ply:StripWeapon(class)
		ply:SelectWeapon("hands")

		local weptype = arista.item.items[class].weaponType
		if weptype then
			ply:emote(arista.config.timers["equipmessage"]["Plugh"]:format(weptype))

			local counts = ply:getAristaVar("gunCounts")
				counts[weptype] = counts[weptype] - 1
			ply:setAristaVar("gunCounts", counts)
		end
	end

	local function failure(ply)
		if not ply:IsValid() then return end

		ply:emote(arista.config.timers["equipmessage"]["Abort"])
		ply._equipping = false
	end

	-- A command to holster your current weapon.
	arista.command.add("holster", "", 0, function(ply)
		local weapon = ply:GetActiveWeapon()

		-- Check if the weapon is a valid entity.
		if not (IsValid(weapon) and arista.item.items[weapon:GetClass()]) then
			return false, "AL_INVALID_WEAPON"
		end

		local nextHolster = ply:getAristaVar("nextHolsterWeapon")

		-- Check if they can holster another weapon yet.
		if not ply:IsAdmin() and nextHolster and nextHolster > CurTime() then
			return false, "AL_CANNOT_HOLSTER", math.ceil(nextHolster - CurTime())
		else
			ply:setAristaVar("nextHolsterWeapon", CurTime() + 2)
		end

		local class = weapon:GetClass()
		if gamemode.Call("PlayerCanHolster", ply, class) == false then
			return false
		end

		ply._equipping = ply:GetPos()
		local delay = arista.config.timers["equiptime"][arista.item.items[class].weaponType or -1] or 0
		if not (delay and delay > 0) then
			success(ply, nil, class)
		return true end

		arista.timer.conditional(ply:UniqueID() .. " holster", delay, conditional, success, failure, ply, ply:GetPos(), class)
		ply:emote(arista.config.timers["equipmessage"]["Start"])
	end, "AL_COMMAND_CAT_COMMANDS")
end

-- A command to drop your current weapon.
arista.command.add("drop", "", 0, function()
	-- todo: lang
	return false, "Use /holster instead."
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to warrant a player.
arista.command.add("warrant", "", 1, function(ply, target, class)
	local target = arista.player.get(target)
	if not target then
		return false, "AL_INVALID_TARGET"
	end

	-- Get the class of the warrant.
	local class = string.lower(class or "")

	-- Check if a second argument was specified.
	if class == "search" or class == "arrest" then
		if target:Alive() then
			if target:hasWarrant() ~= class then
				if not target:isArrested() then
					if CurTime() > target:getAristaVar("cannotBeWarranted") then
						if hook.Run("PlayerCanWarrant", ply, target, class) ~= false then
							hook.Run("PlayerWarrant", ply, target, class)

							-- Warrant the player.
							target:warrant(class)
						end
					else
						return false, "%s has only just spawned!", target:Name()
					end
				else
					return false, "%s is already arrested!", target:Name()
				end
			else
				if class == "search" then
					-- todo: lang
					return false,"%s is already warranted for a search!", target:Name()
				else
					return false, "%s is already warranted for an arrest!", target:Name()
				end
			end
		else
			return false, "%s is dead and cannot be warranted!", target:Name()
		end
	else
		return false, "Invalid warrant type. Use 'search' or 'arrest'"
	end
end, "AL_COMMAND_CAT_COMMANDS", true)

-- A command to unwarrant a player.
arista.command.add("unwarrant", "", 1, function(ply, target)
	local target = arista.player.get(target)

	-- Check to see if we got a valid target.
	if target then
		if target:hasWarrant() then
			if gamemode.Call("PlayerCanUnwarrant", ply, target) then
				gamemode.Call("PlayerUnwarrant", ply, target)

				-- Warrant the player.
				target:unWarrant()
			end
		else
			return false, "%s does not have a warrant!", target:Name()
		end
	else
		return false, "AL_INVALID_TARGET"
	end
end, "AL_COMMAND_CAT_COMMANDS", true)

do -- Reduce the upvalues poluting the area.
	local function conditional(ply, pos)
		return IsValid(ply) and ply:GetPos() == pos
	end

	local function success(ply)
		ply:knockOut()

		ply:setAristaVar("sleeping", true)
		ply:emote("slumps to the floor, asleep.")
	end

	local function failure(ply)
	end

	-- A command to sleep or wake up.
	arista.command.add("sleep", "", 0, function(ply)
		if ply:getAristaVar("sleeping") and ply:isUnconscious() then
			return ply:wakeUp()
		end

		local time = arista.config.vars.sleepDelay
		ply:setAristaVar("goToSleepTime", CurTime() + time)

		arista.timer.conditional(ply:UniqueID() .. " sleeping timer", time, conditional, success, failure, ply, ply:GetPos())
	end, "AL_COMMAND_CAT_COMMANDS")
end

arista.command.add("trip", "", 0, function(ply)
	if ply:isUnconscious() then return end

	if ply:GetVelocity():Length() < 2 then
		return false, "You must be moving to trip!"
	elseif ply:InVehicle() then
		return false, "There is nothing to trip on in here!"
	end

	ply:knockOut(5)

	ply:setAristaVar("tripped", true)
	ply:emote("trips, falling heavily to the ground.")
end, "AL_COMMAND_CAT_COMMANDS")

arista.command.add("fallover", "", 0, function(ply)
	if not (ply:isUnconscious() or ply:InVehicle()) then
		ply:knockOut(5)

		ply:setAristaVar("tripped", true)
		ply:emote("falls over.")
	end
end, "AL_COMMAND_CAT_COMMANDS")

-- Commit mutiny.
arista.command.add("mutiny", "", 1, function(ply, target)
	local target = arista.player.get(target)
	if not (target and IsValid(target) and target:IsPlayer()) then
		return false, "AL_INVALID_TARGET"
	end

	local pteam, tteam = ply:Team(), target:Team()
	if 	arista.team.getGroupByTeam	(pteam)	~=	arista.team.getGroupByTeam	(tteam)		or
			arista.team.getGang					(pteam) ~=	arista.team.getGang					(tteam)		or
			arista.team.getGang					(tteam)	==	nil																		or
			arista.team.getGroupLevel		(pteam)	>=	arista.team.getGroupLevel		(tteam)		or
			not																			arista.team.hasAccessGroup	(tteam, "D")	then
			return false, "You cannot mutiny against this person"
	end

	target._depositions = target._depositions or {}
	if target._depositions[ply:UniqueID()] then
		return false, "You have already tried to mutiny against your leader!"
	else
		target._depositions[ply:UniqueID()] = ply
	end

	for ID, ply in pairs(target._depositions) do
		if IsValid(ply) then
			local pteam = ply:Team()

			if	arista.team.getGroupByTeam	(pteam)	~=	arista.team.getGroupByTeam	(tteam)	or
					arista.team.getGang		 			(pteam) ~=	arista.team.getGang					(tteam)	or
					arista.team.getGroupLevel 	(pteam)	>=	arista.team.getGroupLevel		(tteam)	then
					target._depositions[ID] = nil
			end
		else
			target._depositions[ID] = nil
		end
	end

	local count	= table.Count(target._depositions)
	local num	= math.floor(table.Count(arista.team.getGangMembers(arista.team.getGroupByTeam(tteam), arista.team.getGang(tteam))) * arista.config.vars.mutinyPercent)
	if num < arista.config.vars.minimumMutiny then
		num = arista.config.vars.minimumMutiny
	end

	if count < num then
		ply:notify("Not enough of the gang agrees with you yet to do anything, but they acknowledge your thoughts...")
	return end

	target:notify("Your gang has overthrown you!")
	target:demote()

	arista.player.notifyAll("%s was overthrown as leader.", target:Name())
end, "AL_COMMAND_CAT_COMMANDS", true)
