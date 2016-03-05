-- Magic 'close enough to the entity' number.
local range = 128 ^ 2

-- An important. (Very important, do not remove.)
arista.command.add("fuck", "", 0, function(p)
	p:notify("FUCK!")
end,"Commands", "", "Free gratuitous swearing")

-- A command to perform an action on a door.
arista.command.add("door", "", 1, function(ply, arguments)
	local trace = ply:GetEyeTraceNoCursor()
	local door = trace.Entity

	-- Check if the player is aiming at a door.
	if not (trace.Hit and IsValid(door) and arista.entity.isDoor(door) and ply:GetPos():DistToSqr(trace.HitPos) <= range) then
		return false, "This is not a valid door!"
	end

	local word = table.remove(arguments, 1)

	if arista.entity.isOwned(door) then
		if word == "purchase" then
			return false, "This door is already owned!"
		elseif word == "sell" then
			if arista.entity.getOwner(door) ~= ply or door._unsellable then
				return false, "You cannot sell this door."
			else
				local name = arista.entity.getDoorName(door)

				ply:takeDoor(door)

				arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") sold their door (named '", name, "').")
			end
		else
			return false, "This method is no longer supported."
		end

		return true
	end

	if word ~= "purchase" then
		return false, "You cannot do that to this door."
	elseif gamemode.Call("PlayerCanOwnDoor", ply, door) == false then
		return false, ""
	end

	-- Check if we have already got the maximum doors.
	--if not ply:CheckLimit("doors") then--(doors >= GM.Config["Maximum Doors"]) then
	--	return false
	--end
	local cost = arista.config.costs.door

	-- Check if the player can afford this door.
	if not ply:canAfford(cost) then
		local amt = cost - ply:getMoney()

		return false, "You need another $" .. amt .. " to purchase this door!"
		-- todo: language (currency)
	end

	ply:giveMoney(-cost)

	-- Get the name from the arguments.
	local concat = table.concat(arguments, " ")
	local name = concat:sub(1, 24)

	-- Stops people trying to troll with it.
	if name:find("Sale", 1, true) or name:find("Nobody", 1, true) then
		name = ""
	end

	ply:giveDoor(door, name)

	--cider.propprotection.ClearSpawner(door)

	local name = arista.entity.getDoorName(door)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") bought a door (named '", name, "').")
end, "Menu Handlers", "<purchase|sell>", "Perform an action on the door you're looking at.")

do
	local function entHandler(ply, arguments, entity)
		local action = table.remove(arguments, 1)
		local ent = entity._isDoor and "door" or entity:getName()

		if action == "name" then
			if not gamemode.Call("PlayerCanSetEntName", ply, entity) then
				return false, "You cannot do that to this!"
			end

			local concat = table.concat(arguments," ")
			local name = concat:sub(1, 24):Trim()

			if not name then name = "" end

			if name:lower():find"sale" or name:lower():find"f2" or name:lower():find"press" or name == "Nobody" then
				return false, "Choose a different name."
			end

			local oldname = arista.entity.getName(entity)
			arista.entity.setName(entity, name)

			arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their ", ent, "'s name from ", oldname, " to ", name, ".")
			return
		end

		if action ~= "give" and action ~= "take" then
			return false, "Invalid action '" .. action .. "' specified!"
		end

		local kind = table.remove(arguments, 1)
		local id = table.remove(arguments, 1)

		local target
		local name

		if kind == "player" then
			target = arista.player.get(id)
			name = target:Name()
		elseif kind == "team" then
			target = arista.team.get(id)
			name = target.name
		elseif kind == "gang" and id:find("", 1, true) then
			target = id:Split("")

			local a, b = unpack(target)
			a, b =  tonumber(a),tonumber(b)

			if a and b then name = arista.team.gangs[a][b].name end
		end

		if not (target and name) then
			PrintTable(arguments)
			print(kind, id, ply, entity)
			return false, "Invalid target!"
		end

		local word = " access to"

		if action == "give" then
			if kind == "player" then
				arista.entity.giveAccessPlayer(entity, target)
			elseif kind == "team" then
				arista.entity.giveAccessTeam(entity, target)
			elseif kind == "gang" then
				arista.entity.giveAccessGang(entity, unpack(target))
			end
		else
			if kind == "player" then
				arista.entity.takeAccessPlayer(entity, target)
			elseif kind == "team" then
				arista.entity.takeAccessTeam(entity, target)
			elseif kind == "gang" then
				arista.entity.takeAccessGang(entity, unpack(target))
			end

			word = "'s access from"
		end

		arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") has ", action, "n ", name, word, " their ", ent, ".")
	end

	-- A command to perform an action on an ent
	arista.command.add("entity", "", 2, function(ply, arguments)
		-- The access menu must be updated every action, reguardless of result, so we gotta use a handler for neatness.
		local trace = ply:GetEyeTraceNoCursor()
		local entity = trace.Entity

		-- Check if the player is aiming at a door.
		if not (trace.Hit and IsValid(entity) and ply:GetPos():DistToSqr(trace.HitPos) <= range) then
			return false, "This is not a valid entity!"
		elseif arista.entity.getOwner(entity) ~= ply then
			return false, "You do not have access to that!"
		end

		local a, b = entHandler(ply, arguments, entity)
		local detailstable = {}

		local owner = arista.entity.getOwner(entity)
		detailstable.access = table.Copy(entity._owner.access)

		if owner == ply then
			table.insert(detailstable.access, ply)

			detailstable.owned = {
				sellable = tobool(entity._isDoor and not entity._unsellable) or nil,
				name = gamemode.Call("PlayerCanSetEntName", ply, entity) and arista.entity.getName(entity) or nil,
			}
		end

		detailstable.owner = arista.entity.getPossessiveName(entity)

		if entity._isDoor then
			detailstable.owner = detailstable.owner .. " door"
		else
			detailstable.owner = detailstable.owner .. " " .. entity:getName()
		end

		net.Start("arista_accessUpdate")
			net.WriteTable(detailstable)
		net.Broadcast()

		return a, b
	end, "Menu Handlers", "<give|take> <ID> <type> or <name> <mynamehere>", "Perform an action on the entity you're looking at")
end

-- todo: all the logging here

-- A command to change your job title
arista.command.add("job", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "" or words == "none" or words == "default" then
		words = team.GetName(ply:Team())
	end

	ply:setAristaVar("job", words)

	--ply:Notify("You have changed your job title to '" .. words .. "'.")
	--GM:Log(EVENT_EVENT, "%s changed " .. ply._GenderWord .. " job text to %q.", ply:Name(), words)
end, "Commands", "[text]", "Change your job title or reset it.")

-- A command to change your clan.
arista.command.add("clan", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "quit" or words == "none" then
		words = ""
	end

	ply:setAristaVar("clan", words)

	--GM:Log(EVENT_EVENT, "%s set their clan to %q.", ply:Name(), words)

	if words == "" then
		ply:notify("You have left your clan.")
	else
		ply:notify("You have set your clan to '%s'.", words)
	end
end, "Commands", "[text|quit|none]", "Change your clan or quit your current one.")

-- A command to change your gender.
arista.command.add("gender", "", 1, function(ply, gender)
	local gender = gender:lower()
	local curGen = ply:getGender():lower()

	if gender ~= "male" and gender ~= "female" then
		return false, "Invalid gender specified."
	elseif curGen == gender then
		return false, "You are already " .. gender .. "!"
	elseif gender == "male" then
		ply:setAristaVar("gender", "Male")
	else
		ply:setAristaVar("gender", "Female")
	end

	ply:notify("You will be  next time you spawn.", gender)

	--GM:Log(EVENT_EVENT, "%s set " .. ply._NextSpawnGenderWord .. " gender to " .. gender .. ".", ply:Name())
end, "Menu Handlers", "<male|female>", "Change your gender.")

-- A command to change your clan.
arista.command.add("details", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if text == "" or text:lower() == "none" then
		ply:setAristaVar("details", "")

		-- Print a message to the player.
		ply:notify("You have removed your details.")
		--GM:Log(EVENT_EVENT, "%s changed "..ply._GenderWord.." details to %q.",ply:Name(),"nothing")
	else
		ply:setAristaVar("text", "")

		-- Print a message to the player.
		ply:notify("You have changed your details to '%s'.", text)
		--GM:Log(EVENT_EVENT, "%s changed "..ply._GenderWord.." details to %q.",ply:Name(),text)
	end
end, "Commands", "<text|none>", "Change your details or make them blank.")

arista.command.add("team", "", 1, function(ply, identifier)
	local teamdata = arista.team.get(identifier)

	if not teamdata then
		return false, "Invalid team!"
	end

	local teamid = teamdata.index
	if teamid == ply:Team() then
		return false, "You are already that team!"
	elseif team.NumPlayers(teamid) >= teamdata.limit then
		return false, "That team is full!"
	elseif gamemode.Call("PlayerCanJoinTeam", ply, teamid) == false then
		return false
	end

	ply:holsterAll()

	return ply:joinTeam(teamid)
end, "Menu Handlers", "<team>", "Change your team.", true)
