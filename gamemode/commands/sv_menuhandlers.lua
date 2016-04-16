-- Magic 'close enough to the entity' number.
local range = 128 ^ 2

arista.command.add("team", "", 1, function(ply, identifier)
	local teamdata = arista.team.get(identifier)

	if not teamdata then
		return false, "AL_INVALID_TEAM"
	end

	local teamid = teamdata.index
	if teamid == ply:Team() then
		return false, "AL_CANNOT_JOIN_SAME"
	elseif team.NumPlayers(teamid) >= teamdata.limit then
		return false, "AL_CANNOT_JOIN_FULL"
	elseif gamemode.Call("PlayerCanJoinTeam", ply, teamid) == false then
		return false
	end

	ply:holsterAll()

	return ply:joinTeam(teamid)
end, "AL_COMMAND_CAT_MENU", true)

-- A command to perform inventory action on an item.
arista.command.add("inventory", "", 2, function(ply, id, action, amount)
	local id = id:lower()
	local action = action:lower()

	local item = arista.item.items[id]

	if not item then
		return false, "AL_INVALID_ITEM"
	end

	local holding = ply:getAristaVar("inventory")[id]
	if not holding or holding < 1 then
		return false, "AL_DONT_OWN_ITEM", item.plural
	elseif (action == "destroy") then
		item:destroy(ply)
	-- START CAR ACTIONS (TODO: find some other way of doing this?)
	elseif (action == "pickup") then
		item:pickup(ply)
	elseif (action == "sell") then
		item:sell(ply)
	-- END CAR ACTIONS
	elseif action == "drop" then
		if amount == "all" then
			amount = holding
		else
			amount = tonumber(amount) or 1
		end

		if amount > holding then
			return false, "AL_DONT_HAVE_AMOUNT", item.plural
		elseif amount < 1 then
			return false, "AL_INVALID_AMOUNT"
		end

		local pos = ply:GetEyeTraceNoCursor().HitPos
		if ply:GetPos():DistToSqr(pos) > range then
			pos = ply:GetShootPos() + ply:GetAimVector() * 128
		end

		return item:drop(ply, pos, amount)
	elseif action == "use" then
		local time = CurTime()

		local nextUse = ply:getAristaVar("nextUse") or {}
		local nextItem = ply:getAristaVar("nextUseItem") or 0
		local nextUseID = nextUse[id] or 0

		if not ply:IsAdmin() then -- Admins bypass the item timer
			if nextItem > time then
				return false, "AL_CANNOT_USE_ITEM", math.ceil(nextItem - time)
			elseif nextUseID > time then
				return false, "AL_CANNOT_USE_ITEM_SPECIFIC", item.name, math.ceil(nextUseID - time)
			end
		end

		if ply:InVehicle() and item.noVehicles then
			return false, "AL_CANNOT_USE_ITEM_VEHICLE"
		elseif gamemode.Call("PlayerCanUseItem", ply, id) == false then
			return false
		end

		if item.weapon then
			ply:setAristaVar("nextHolsterWeapon", CurTime() + 5)
		end

		ply:setAristaVar("nextUseItem", time + arista.config.vars.itemUseDelay)

		nextUse[id] = time + arista.config.vars.specficItemDelay
		ply:setAristaVar("nextUse", nextUse)

		return item:use(ply)
	else
		return false, "AL_INVALID_ACTION"
	end
end, "AL_COMMAND_CAT_MENU", true)

arista.command.add("manufacture", "", 1, function(ply, item)
	local item = gamemode.Call("GetItem", item)

	-- Check if the item exists.
	if item then
		if item.category then
			if not table.HasValue(arista.team.query(ply:Team(), "canmake", {}), item.category) then
				return false, "AL_X_CANNOT_MANUFACTURE_X", arista.team.query(ply:Team(), "name", "Your team's member"), GAMEMODE:GetCategory(item.category).name .. "!"
			end
		end

		local nextManufacture = ply:getAristaVar("nextManufactureItem")

		-- Check if they can manufacture this item yet.
		if not ply:IsAdmin() and nextManufacture and nextManufacture > CurTime() then
			return false, "AL_CANNOT_MANUFACTURE", math.ceil(nextManufacture - CurTime())
		else
			ply:setAristaVar("nextManufactureItem", CurTime() + 3)
		end

		local cost = item.cost * item.batch

		if ply:canAfford(cost) then
			local manufac, res
			if item.canManufacture then
				manufac, res = item:canManufacture(ply)
			end

			if manufac == false then return false, res end

			-- Take the cost the from player.
			ply:giveMoney(-cost)

			-- Get a trace line from the player's eye position.
			local trace = ply:GetEyeTraceNoCursor();
			local entity = item:make(trace.HitPos + Vector(0,0,16), item.batch)

			if item.onManufacture then item:onManufacture(ply, entity, amount) end
			entity:CPPISetOwner(ply)

			local text = ""

			-- Check if the item comes as a batch.
			if item.batch > 1 then
				text = item.batch .. " " .. item.plural
			else
				text = "a " .. item.name
			end

			ply:notify("AL_YOU_MANUFACTURED", text)

			arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") manufactured ", text, ".")
		else
			local amount = cost - ply:getMoney()

			-- Print a message to the player telling them how much they need.
			return false, "AL_NEED_ANOTHER_MONEY", amount
		end
	else
		return false, "AL_INVALID_ITEM"
	end
end, "AL_COMMAND_CAT_MENU", true)

-- A command to change your gender.
arista.command.add("gender", "", 1, function(ply, gender)
	local gender = gender:lower()
	local curGen = ply:getGender():lower()

	if gender ~= "male" and gender ~= "female" then
		return false, "AL_INVALID_GENDER"
	elseif curGen == gender then
		return false, "AL_CANNOT_GENDER_SAME", curGen
	elseif gender == "male" then
		ply:setAristaVar("gender", "Male")
	else
		ply:setAristaVar("gender", "Female")
	end

	ply:generateDefaultRPName()

	ply:notify("AL_YOU_CHANGE_GENDER", gender)

	--GM:Log(EVENT_EVENT, "%s set " .. ply._NextSpawnGenderWord .. " gender to " .. gender .. ".", ply:Name())
end, "AL_COMMAND_CAT_MENU", true)

-- A command to perform an action on a door.
arista.command.add("door", "", 1, function(ply, arguments)
	local trace = ply:GetEyeTraceNoCursor()
	local door = trace.Entity

	-- Check if the player is aiming at a door.
	if not (trace.Hit and IsValid(door) and arista.entity.isDoor(door) and ply:GetPos():DistToSqr(trace.HitPos) <= range) then
		return false, "AL_INVALID_DOOR"
	end

	local word = table.remove(arguments, 1)

	if arista.entity.isOwned(door) then
		if word == "purchase" then
			return false, "AL_CANNOT_DOOR_OWNED"
		elseif word == "sell" then
			if arista.entity.getOwner(door) ~= ply or door._unsellable then
				return false, "AL_CANNOT_DOOR_UNSELLABLE"
			else
				local name = arista.entity.getDoorName(door)

				ply:takeDoor(door)

				arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") sold their door (named '", name, "').")
			end
		else
			return false, "AL_METHOD_UNSUPPORTED"
		end

		return true
	end

	if word ~= "purchase" then
		return false, "AL_METHOD_UNSUPPORTED"
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

		return false, "AL_NEED_ANOTHER_MONEY", amt
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

	door:CPPISetOwner(game.GetWorld())

	local name = arista.entity.getDoorName(door)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") bought a door (named '", name, "').")
end, "AL_COMMAND_CAT_MENU")

do
	local function entHandler(ply, arguments, entity)
		local action = table.remove(arguments, 1)
		local ent = entity._isDoor and "door" or entity:getTitle()

		if action == "name" then
			if gamemode.Call("PlayerCanSetEntName", ply, entity) == false then
				return false, "AL_CANNOT_GENERIC"
			end

			local concat = table.concat(arguments," ")
			local name = concat:sub(1, 24):Trim()

			if not name then name = "" end

			if name:lower():find"sale" or name:lower():find"f2" or name:lower():find"press" or name == "Nobody" then
				return false, "AL_INVALID_NAME"
			end

			local oldname = arista.entity.getName(entity)
			arista.entity.setName(entity, name)

			arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their ", ent, "'s name from ", oldname, " to ", name, ".")
			return
		end

		if action ~= "give" and action ~= "take" then
			return false, "AL_INVALID_ACTION"
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
			target = id:Split(";")

			local a, b = unpack(target)
			a, b =  tonumber(a),tonumber(b)

			if a and b then name = arista.team.gangs[a][b].name end
		end

		if not (target and name) then
			return false, "AL_INVALID_TARGET"
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
			return false, "AL_INVALID_ENTITY"
		elseif arista.entity.getOwner(entity) ~= ply then
			return false, "AL_CANNOT_NOACCESS"
		end

		local a, b = entHandler(ply, arguments, entity)
		local detailstable = {}

		local owner = arista.entity.getOwner(entity)
		detailstable.access = table.Copy(entity._owner.access)

		if owner == ply then
			table.insert(detailstable.access, ply)

			detailstable.owned = {
				sellable = tobool(entity._isDoor and not entity._unsellable) or nil,
				name = gamemode.Call("PlayerCanSetEntName", ply, entity) ~= false and arista.entity.getName(entity) or nil,
			}
		end

		detailstable.owner = arista.entity.getPossessiveName(entity)

		if entity._isDoor then
			detailstable.owner = detailstable.owner .. " door"
		else
			detailstable.owner = detailstable.owner .. " " .. entity:getTitle()
		end

		net.Start("arista_accessUpdate")
			net.WriteTable(detailstable)
		net.Send(ply)

		return a, b
	end, "AL_COMMAND_CAT_MENU")
end

do
	local function containerHandler(ply, item, action, number)
		local container = ply:GetEyeTraceNoCursor().Entity
		if not (IsValid(container) and arista.container.isContainer(container) and ply:GetPos():DistToSqr(ply:GetEyeTraceNoCursor().HitPos) <= range) then
			return false, "AL_INVALID_CONTAINER"
		elseif gamemode.Call("PlayerCanUseContainer", ply, container) == false then
			return false, "AL_CANNOT_CONTAINER_USE"
		end

		local item = item:lower()
		local action = action:lower()

		if action ~= "put" and action ~= "take" then
			return false, "AL_CANNOT_GENERIC"
		end

		local pInventory = ply:getAristaVar("inventory")
		local cInventory, io, filter = arista.container.getContents(container, ply, true)

		local pAmount = item == "money" and ply:getMoney() or pInventory[item]
		local cAmount = cInventory[item]

		local number = number or 1
		if number == "all" then
			number = action == "put" and pAmount or cAmount
		end

		number = math.floor(tonumber(number) or 1)

		if number < 1 then
			return false, "AL_INVALID_AMOUNT"
		elseif not arista.item.items[item]  then
			return false, "AL_INVALID_ITEM"
		end

		if action == "put" then
			local amount = item == "money" and ply:getMoney() or pAmount

			number = math.abs(tonumber(number) or amount or 0)

			if not (amount and amount > 0 and amount >= number) then
				return false, "AL_DONT_HAVE_ITEMS"
			end
		else
			local amount = cInventory[item]

			number = math.abs(tonumber(number) or amount or 0)

			if not (amount and math.abs(amount) > 0 and math.abs(amount) >= number) then
				return false, "AL_CANNOT_CONTAINER_NOITEMS"
			elseif amount < 0 then
				return false, "AL_CANNOT_CONTAINER_TAKE"
			end
		end

		if filter and action == "put" and not filter[item] then
			return false, "AL_CANNOT_CONTAINER_PUT"
		end

		do
			local action = action == "put" and CONTAINER_CAN_PUT or CONTAINER_CAN_TAKE

			if bit.band(action, io) ~= action then
				return false, "AL_CANNOT_GENERIC"
			end
		end

		if number == 0 then return false, "AL_INVALID_AMOUNT" end
		if action == "take" then number = -number end

		return arista.container.update(container, item, number, nil, ply)
	end

	arista.command.add("container", "", 2, function(ply, ...)
		-- I use a handler because returning a value is so much neater than a pyramid of ifs.
		local res, msg = containerHandler(ply, ...)

		if res then
			local entity = ply:GetEyeTraceNoCursor().Entity
			local contents, io, filter = arista.container.getContents(entity, ply, true)

			local tab = {
				contents = contents,
				meta = {
					io = io,
					filter = filter, -- Only these can be put in here, if nil then ignore, but empty means nothing.
					size = arista.container.getLimit(entity), -- Max space for the container
					entindex = entity:EntIndex(), -- You'll probably want it for something
					name = arista.container.getName(entity) or "Container"
				}
			}

			net.Start("arista_containerUpdate")
				net.WriteTable(tab)
			net.Send(ply)
		else
			net.Start("arista_closeContainerMenu")
			net.Send(ply)
		end

		return res, msg
	end, "AL_COMMAND_CAT_MENU", true)
end
