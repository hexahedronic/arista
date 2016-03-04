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
		local amt = cost - ply:getAristaVar("money")

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
		elseif kind == "gang" and id:find(";", 1, true) then
			target = id:Split(";")

			local a, b = unpack(target)
			a, b =  tonumber(a),tonumber(b)

			if a and b then name = arista.team.gangs[a][b].name end
		end

		if not (target and name) then
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

		detailstable.owner = cider.entity.getPossessiveName(entity)

		if entity._isDoor then
			detailstable.owner = detailstable.owner .. " door"
		else
			detailstable.owner = detailstable.owner .. " " .. entity:getName()
		end

		net.Broadcast(ply, "arista_accessUpdate", detailstable)

		return a, b
	end, "Menu Handlers", "<give|take> <ID> <type> or <name> <mynamehere>", "Perform an action on the entity you're looking at")
end
