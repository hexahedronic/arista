arista.entity = {}
arista._internaldata.entity_stored = arista._internaldata.entity_stored or {}
arista._internaldata.entity_backup = arista._internaldata.entity_backup or {}

-- Check if an entity is a door.
function arista.entity.isDoor(entity)
	if not entity or not IsValid(entity) then return false end

	local class = entity:GetClass()
	local model = entity:GetModel()

	-- Check if the entity is a valid door class.
	return entity._isDoor
		or class == "func_door"
		or class == "func_door_rotating"
		or class == "prop_door_rotating"
		or model
			and (model:find("gate", 1, true) or model:find("door", 1, true))
			and entity.LookupSequence
			and (entity:LookupSequence("open") or 0) > 0
			and (entity:LookupSequence("close") or 0) > 0
end

-- Make an entity ownable
function arista.entity.makeOwnable(entity, unmake)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.makeOwnable was passed an invalid entity (", tostring(entity), ").")
	return end

	if arista.entity.isOwnable(entity) or entity:IsPlayer() and not unmake then
		arista.logs.logNoPrefix(arista.logs.E.DEBUG, "arista.entity.makeOwnable was passed an already ownable entity.")
	return end

	arista.entity.clearData(entity)

	if unmake then
		gamemode.Call("EntityUnMadeOwnable", entity)

		entity:unLock()
		arista._internaldata.entity_stored[entity:EntIndex()] = nil
	return end

	if arista.entity.isDoor(entity, true) then
		entity._isDoor = true
		entity._eName = "door"
	elseif entity:IsVehicle() then
		entity._isVehicle = true
		entity._eName = "vehicle"
	end

	entity:unLock()
	arista._internaldata.entity_stored[entity:EntIndex()] = entity

	gamemode.Call("EntityMadeOwnable", entity)
end

-- Clear the ownership data of an entity
function arista.entity.clearData(entity, saveslaves)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.clearData was passed an invalid entity (", tostring(entity), ").")
	return end

	arista.entity.accessChangedPlayerMulti(entity, arista.entity.getAllAccessors(entity), false)

	if not saveslaves and arista.entity.getMaster(entity) then
		arista.entity.takeSlave(arista.entity.getMaster(entity), entity)
	end

	local ps = {}
	local pm = NULL

	if saveslaves then
		pm = entity._owner.master
		ps = entity._owner.slaves
	end

	entity._owner = {
		name   = "Nobody",
		access = {},
		owner  = NULL,
		slaves = ps,
		master = pm,
	}

	arista.entity.network(entity)
end

-- Get every player that has access to this entity
function arista.entity.getAllAccessors(entity, plyindexed)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.clearData was passed an invalid entity (", tostring(entity), ").")
	return end

	local ret = {}

	if arista.entity.isOwned(entity) then
		local a = table.Copy(entity._owner.access)
		a[#a+1] = arista.entity.getOwner(entity)

		for k, v in ipairs(a) do
			local ty = type(v)

			if ty == "Player" then
				ret[#ret + 1] = v
			elseif ty == "number" then
				--It's a team
				table.Add(ret, team.GetPlayers(v))
			elseif ty == "string" then
				--It's a gang
				local tab = v:Split(";")
				local group, gang = tonumber(tab[1]),tonumber(tab[2])

				if group and gang then
					local members = arista.team.getGangMembers(group, gang)

					if members then
						table.Add(ret, members)
					end
				end
			end
		end
	end

	local plys = {}
	for _, ply in ipairs(ret) do
		plys[ply] = ply
	end

	if plyindexed then return plys end

	ret = {}

	for _, ply in pairs(plys) do
		if IsValid(ply) then
			ret[#ret + 1] = ply
		end
	end

	return ret
end

-- Get all entities a player has access to.
function arista.entity.getEntsAccess(player)
	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.getEntsAccess was passed an invalid player (", tostring(player), ").")
	return end

	local searchfor, ret = {}, {}
	local team = player:Team()
	local gang = arista.team.getGang(team)
	local group = arista.team.getGroupByTeam(team)

	-- Player still connecting.
	local index = 0
	if group then
		index = group.index
	end

	local gid = index..";0"

	-- table micro optimisations
	searchfor[1] = gid

	if gang then
		local id = group.index..";"..gang
		searchfor[2] = id
	end

	searchfor[#searchfor+1] = team
	searchfor[#searchfor+1] = player

	for index, ent in pairs(arista._internaldata.entity_stored) do
		if IsValid(ent) then
			local found = false

			for _, search in ipairs(searchfor) do
				if ent._owner.owner == search then
					ret[#ret+1] = ent
					found = true

					break
				end
			end

			for _, access in ipairs(ent._owner.access) do
				if found then break end

				for _,search in ipairs(searchfor) do
					if access == search then
						ret[#ret+1] = ent
						found = true

						break
					end
				end
			end
		else
			arista._internaldata.entity_stored[index] = nil
		end
	end

	return ret
end

-- Tell a player their access to an entity has changed
function arista.entity.accessChangedPlayer(entity, player, bool)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.accessChangedPlayer was passed an invalid entity (", tostring(entity), ").")
	return end

	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.accessChangedPlayer was passed an invalid player (", tostring(player), ").")
	return end

	if arista.entity.hasSlaves(entity) then
		for _, slave in ipairs(arista.entity.getSlaves(entity)) do
			arista.entity.accessChangedPlayer(slave, player, bool)
		end
	end

	gamemode.Call("EntityAccessChangedPlayer", entity, player, bool)

	net.Start("arista_incomingAccess")
		net.WriteUInt(entity:EntIndex(), 16)
		net.WriteBool(bool)
	net.Send(player)
end

-- Happens when something happens to a player that requires checking accessability again.
function arista.entity.updatePlayerAccess(player)
	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.updatePlayerAccess was passed an invalid player (", tostring(player), ").")
	return end

	for _, entity in ipairs(arista.entity.getEntsAccess(player)) do
		arista.entity.accessChangedPlayer(entity, player, true)
	end
end

-- Tell lots of players their access to an entity has changed
function arista.entity.accessChangedPlayerMulti(entity, players, bool)
	for _, player in pairs(players) do
		arista.entity.accessChangedPlayer(entity, player, bool)
	end
end

-- Give a player access to an entity
function arista.entity.giveAccessPlayer(entity, player)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.giveAccessPlayer was passed an invalid entity (", tostring(entity), ").")
	return end

	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.giveAccessPlayer was passed an invalid player (", tostring(player), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	if arista.entity.isOwnable(entity) and not arista.entity.onList(entity, player) then
		table.insert(entity._owner.access, player)

		arista.entity.accessChangedPlayer(entity, player, true)
		arista.entity.updateSlaves(entity)
	end
end

--Take a player's access away
function arista.entity.takeAccessPlayer(entity, player)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.takeAccessPlayer was passed an invalid entity (", tostring(entity), ").")
	return end

	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.takeAccessPlayer was passed an invalid player (", tostring(player), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	if not arista.entity.isOwned(entity) then return end

	if arista.entity.getOwner(entity) == player then
		arista.entity.clearData(entity, true) -- if you take the owner's access, you lose all accessors
		arista.entity.updateSlaves(entity)
	else
		for key, accessor in ipairs(entity._owner.access) do
			if accessor == player then
				table.remove(entity._owner.access, key)

				if not arista.entity.hasAccess(entity, player) then
					arista.entity.accessChangedPlayer(entity, player, false)
				end

				arista.entity.updateSlaves(entity)

				break
			end
		end
	end
end

-- Give a team access to an entity
function arista.entity.giveAccessTeam(entity, teamid)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.giveAccessTeam was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	if istable(teamid) then -- We might get passed a team object
		teamid = teamid.index
	end

	if arista.entity.isOwnable(entity) and not arista.entity.onList(entity, teamid) then
		table.insert(entity._owner.access, teamid)

		arista.entity.accessChangedPlayerMulti(entity, team.GetPlayers(teamid), true)
		arista.entity.updateSlaves(entity)
	end
end

--Take a team's access away
function arista.entity.takeAccessTeam(entity, teamid)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.takeAccessTeam was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	if istable(teamid) then -- We might get passed a team object
		teamid = teamid.index
	end

	if arista.entity.isOwned(entity) then
		if arista.entity.getOwner(entity) == teamid then
			arista.entity.clearData(entity, true) -- if you take the owner's access, you lose all accessors
			arista.entity.updateSlaves(entity)
		else
			for key, accessor in ipairs(entity._owner.access) do
				if accessor == teamid then
					table.remove(entity._owner.access, key)

					local plyset = team.GetPlayers(teamid)

					for key, player in ipairs(plyset) do
						if arista.entity.hasAccess(entity, player) then
							table.remove(plyset, key)
						end
					end

					if #plyset > 0 then
						arista.entity.accessChangedPlayerMulti(entity, plyset, false)
					end

					arista.entity.updateSlaves(entity)

					break
				end
			end
		end
	end
end

-- Give a gang access to an entity
function arista.entity.giveAccessGang(entity, group, gang)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.giveAccessGang was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity
	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	else
		group = tonumber(group)
	end

	local gang = tonumber(gang)
	local gangword = group .. ";" .. gang

	if arista.entity.isOwnable(entity) and not arista.entity.onList(entity,gangword) then
		table.insert(entity._owner.access, gangword)
		arista.entity.accessChangedPlayerMulti(entity, arista.team.getGangMembers(group, gang), true)
		arista.entity.updateSlaves(entity)
	end
end

--Take a gang's access away
function arista.entity.takeAccessGang(entity, group, gang)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.takeAccessGang was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	end

	local gang = tonumber(gang)
	local gangword = group .. ";" .. gang

	if arista.entity.isOwned(entity) then
		if arista.entity.getOwner(entity) == gangword then
			arista.entity.clearData(entity, true) -- if you take the owner's access, you lose all accessors
			arista.entity.updateSlaves(entity)
		else
			for key, accessor in ipairs(entity._owner.access) do
				if accessor == gangword then
					table.remove(entity._owner.access, key)
					local plyset = arista.team.getGangMembers(group, gang)

					for key,player in ipairs(plyset) do
						if arista.entity.hasAccess(entity, player) then
							table.remove(plyset, key)
						end
					end

					if #plyset > 0 then
						arista.entity.accessChangedPlayerMulti(entity, plyset, false)
					end

					arista.entity.updateSlaves(entity)

					break
				end
			end
		end
	end
end

-- Sends data to client.
function arista.entity.network(entity)
	local plyOwner = isentity(entity._owner.owner) and entity._owner.owner ~= NULL

	entity:networkAristaVar("ownerName", entity._owner.name)
	entity:networkAristaVar("ownedByPlayer", plyOwner)
end

-- Clear the owner of an entity without resetting access. This should only ever be called if a new owner is about to be set.
function arista.entity.clearOwner(entity)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.clearOwner was passed an invalid entity (", tostring(entity), ").")
	return end

	if not arista.entity.isOwnable(entity) then
		 arista.entity.makeOwnable(entity)
	end

	entity = arista.entity.getMaster(entity) or entity

	local owner = arista.entity.getOwner(entity)
	if not owner then return end

	local ret = {}
	local Type = type(owner)
	if Type == "Player" then
		ret[#ret+1] = owner
	elseif Type == "number" then
		--It's a team
		table.Add(ret, team.GetPlayers(owner))
	elseif Type == "string" then
		--It's a gang
		local tab = owner:Split(";")
		local group, gang = tonumber(tab[1]), tonumber(tab[2])

		if group and gang then
			local members = arista.team.getGangMembers(group,gang)

			if members then
				table.Add(ret, members)
			end
		end
	end

	arista.entity.accessChangedPlayerMulti(entity, ret, false)

	entity._owner.name = "Nobody"
	entity._owner.owner = NULL

	arista.entity.network(entity)

	arista.entity.updateSlaves(entity)

	gamemode.Call("EntityOwnerSet", entity, "remove")
end

-- Set a player to be the owner of an entity
function arista.entity.setOwnerPlayer(entity, player)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setOwnerPlayer was passed an invalid entity (", tostring(entity), ").")
	return end

	if not IsValid(player) or not player:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setOwnerPlayer was passed an invalid player (", tostring(player), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	arista.entity.clearOwner(entity)
		entity._owner.name = player:Name()
		entity._owner.owner = player
	arista.entity.network(entity)

	arista.entity.updateSlaves(entity)

	arista.entity.accessChangedPlayer(entity, player, true)

	gamemode.Call("EntityOwnerSet", entity, "player", player)
end

--Set a team to be the owner of an entity
function arista.entity.setOwnerTeam(entity, teamid)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setOwnerPlayer was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity

	arista.entity.clearOwner(entity)
		entity._owner.name = team.GetName(teamid)
		entity._owner.owner = teamid
	arista.entity.network(entity)

	arista.entity.updateSlaves(entity)

	arista.entity.accessChangedPlayerMulti(entity, team.GetPlayers(teamid), true)

	gamemode.Call("EntityOwnerSet", entity, "team", teamid)
end

-- Set a gang to be the owner of an entity
function arista.entity.setOwnerGang(entity, group, gang)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setOwnerGang was passed an invalid entity (", tostring(entity), ").")
	return end

	entity = arista.entity.getMaster(entity) or entity
	arista.entity.clearOwner(entity)

	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	else
		group = tonumber(group) or 0
	end

	local gang = tonumber(gang)

	if not arista.team.gangs[group] or not arista.team.gangs[group][gang] then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setOwnerGang was passed an invalid gang (", group, ", ", tostring(gang), ").")
	return end

	local gangword = group .. ";" .. gang

	arista.entity.clearOwner(entity)
		entity._owner.name = arista.team.gangs[group][gang].name
		entity._owner.owner = gangword
	arista.entity.network(entity)

	arista.entity.updateSlaves(entity)

	arista.entity.accessChangedPlayerMulti(entity, arista.team.getGangMembers(group, gang), true)

	gamemode.Call("EntityOwnerSet", entity, "gang", {group, gang})
end

-- Set the name of an entity
function arista.entity.setName(entity, name, nomaster)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.setName was passed an invalid entity (", tostring(entity), ").")
	return end

	if not nomaster then
		entity = arista.entity.getMaster(entity) or entity
	end

	if not arista.entity.isOwnable(entity) then return end

	entity._owner.name = name
	arista.entity.network(entity)

	arista.entity.updateSlaves(entity)

	gamemode.Call("EntityNameSet", entity, name)
end

-- Get the name of an entity
function arista.entity.getName(entity)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.getName was passed an invalid entity (", tostring(entity), ").")
	return end

	if not arista.entity.isOwnable(entity) then return end

	return entity._owner.name
end

-- Check to see if an entity can be owned
function arista.entity.isOwnable(entity)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.isOwnable was passed an invalid entity (", tostring(entity), ").")
	return end

	return tobool(entity._owner)
end

-- Check to see if an entity is owned
function arista.entity.isOwned(entity)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.isOwned was passed an invalid entity (", tostring(entity), ").")
	return end

	return entity._owner and entity._owner.owner and entity._owner.owner ~= NULL
end

-- Get the owner's name of an entity
function arista.entity.getOwner(entity)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.getOwner was passed an invalid entity (", tostring(entity), ").")
	return end

	if arista.entity.isOwned(entity) then
		return entity._owner.owner
	end

	return nil
end

-- Is this entry on the list?
function arista.entity.onList(entity, entry, noown)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.onList was passed an invalid entity (", tostring(entity), ").")
	return end

	if not arista.entity.isOwned(entity) then
		return false
	end

	if arista.entity.getOwner(entity) == entry and not noown then
		return true
	end

	for _, access in ipairs(entity._owner.access) do
		if access == entry then
			return true
		end
	end

	return false
end

-- Sets object's master.
function arista.entity.setMaster(entity, master, noupdate)
	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then return end

	if not arista.entity.isOwnable(entity) then return nil end

	gamemode.Call("EntityMasterSet", entity, master)

	if not master or master == NULL then -- I have been set loose. whoo-hoo.
		arista.entity.takeSlave(arista.entity.getMaster(entity), entity)

		entity._owner.master = master

		arista.entity.clearData(entity)
	return true end

	-- Return if master not valid and ownable.
	if not (IsValid(master) and arista.entity.isOwnable(master)) then return nil end

	-- Return if the master is the slave, or if theres no change in the master.
	if master == entity or arista.entity.getMaster(entity) == master then return nil end

	if arista.entity.hasSlaves(entity) then -- Make any slaves I happen to have slaves of my new master
		for _, slave in ipairs(arista.entity.getSlaves(entity)) do
			arista.entity.setMaster(slave, master, true)
		end
	end

	arista.entity.clearData(entity)
		entity._owner.master = master
	arista.entity.giveSlave(master,entity)

	if not noupdate then -- Only need to do this once
		arista.entity.updateSlaves(master)
	end
end

-- Gets an object's master.
function arista.entity.getMaster(entity)
	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then return end

	return IsValid(entity._owner.master) and entity._owner.master or nil
end

-- Get all slaves an object owns.
function arista.entity.getSlaves(entity)
	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then return end

	local ret = {}
	for key, slave in ipairs(entity._owner.slaves) do
		if IsValid(slave) and arista.entity.isOwnable(slave) then
			ret[#ret+1] = slave
		else
			table.remove(entity._owner.slaves, key)
		end
	end

	return ret
end

function arista.entity.hasSlaves(entity)
	if not (IsValid(entity) and arista.entity.isOwnable(entity)) then return end

	return #arista.entity.getSlaves(entity) > 0
end

-- This function can potentially be quite network intensive. Try not to call it too often
function arista.entity.updateSlaves(entity)
	if not (IsValid(entity) and arista.entity.isOwnable(entity) and arista.entity.hasSlaves(entity)) then return end

	for _, slave in ipairs(arista.entity.getSlaves(entity)) do
		slave._owner.access = entity._owner.access
		slave._owner.owner  = entity._owner.owner

		arista.entity.setName(slave, arista.entity.getName(entity), true)
	end
end

function arista.entity.giveSlave(entity, slave)
	if not (IsValid(entity) and arista.entity.isOwnable(entity) and IsValid(slave) and arista.entity.isOwnable(slave)) then return end

	entity = arista.entity.getMaster(entity) or entity

	for _,v in ipairs(entity._owner.slaves) do
		if v == slave then
			return
		end
	end

	gamemode.Call("EntityGiveSlave", entity, slave)

	table.insert(entity._owner.slaves, slave)
end

function arista.entity.takeSlave(entity, slave)
	if not (IsValid(entity) and arista.entity.isOwnable(entity) and arista.entity.hasSlaves(entity) and IsValid(slave) and arista.entity.isOwnable(slave)) then return end

	local slaves = entity._owner.slaves

	for key, s in ipairs(slaves) do
		if s == slave or not IsValid(s) then
			table.remove(slaves, key)
		end
	end

	gamemode.Call("EntityTakeSlave", entity, slave)
end

-- Does the player have access to the entity?
function arista.entity.hasAccess(entity, player)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.hasAccess was passed an invalid entity (", tostring(entity), ").")

		return
	end

	if not arista.entity.isOwned(entity) then return false end

	local accessors = arista.entity.getAllAccessors(entity, true)
	return accessors[player] or false
end

do
	local function unJamDoor(ent)
		if not IsValid(ent) then return end

		ent:setAristaVar("jammed", false)

		ent:unLock(0, true)

		local close = ent._autoclose or arista.config.vars.doorAutoClose
		local class = ent:GetClass()

		if class:find("func_door", 1, true) then
			ent:SetKeyValue("wait", close)
		elseif class:find("prop_door", 1, true) then
			ent:SetKeyValue("returndelay", close)
		end

		arista.entity.closeDoor(ent, 0)
	end

	function arista.entity.openDoor(ent, delay, unlock, sound, jam)
		if not ent or not IsValid(ent) then
			arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.openDoor was passed an invalid entity (", tostring(ent), ").")

			return
		end

		if not (arista.entity.isDoor(ent) and arista.entity.isOwnable(ent)) then
			return false
		elseif delay and delay > 0 then
			timer.Simple(delay, function()
				if not IsValid(ent) then return end

				arista.entity.openDoor(ent, 0, unlock, sound, jam)
			end)

			return
		elseif ent:isJammed() or ent:isSealed() or ent._doorState == "open" then
			return false
		end

		delay = 0

		if unlock then
			ent:unLock()
			delay = 0.025
		end

		if ent:GetClass() == "prop_dynamic" then
			ent:Fire("setanimation", "open", delay)
			ent._doorState = "open"
			ent._autoclose = ent._autoclose or arista.config.vars.doorAutoClose
		else
			ent:Fire("open", "", delay)
		end

		if jam then
			ent:networkAristaVar("jammed", true)

			ent:lock(delay + 0.025, true)

			local class = ent:GetClass()
			local jamTime = arista.config.vars.doorJam

			if class:find("func_door", 1, true) then
				ent:SetKeyValue("wait", arista.config.vars.doorJam)
			elseif class:find("prop_door", 1, true) then
				ent:SetKeyValue("returndelay", arista.config.vars.doorJam)
			end

			timer.Simple(arista.config.vars.doorJam, function() unJamDoor(ent) end)
		elseif ent._autoclose or 0 > 0 then
			arista.entity.closeDoor(ent, ent._autoclose)
		end
	end

	function arista.entity.closeDoor(ent, delay, lock)
		if not ent or not IsValid(ent) then
			arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.closeDoor was passed an invalid entity (", tostring(ent), ").")

			return
		end

		if not (arista.entity.isDoor(ent) and arista.entity.isOwnable(ent)) then
			return false
		elseif delay and delay > 0 then
			timer.Simple(delay, function()
				if not IsValid(ent) then return end

				arista.entity.closeDoor(ent, 0, lock)
			end)

			return
		elseif ent:isJammed() or ent:isSealed() or ent._doorState == "closed" then
			return false
		elseif ent:GetClass() == "prop_dynamic" then
			ent:Fire("setanimation", "close", 0)
			ent._doorState = "closed"
		else
			ent:Fire("close")
		end

		if lock then
			ent:lock(0.025)
		end
	end
end

-- Get the possessive name of the entity's owner.
-- WARNING: This may look wrong with some team names. Try not to give entities to teams whose names end in 'r' with more than one player in them when you are planning to call this function.
function arista.entity.getPossessiveName(entity)
	if not arista.entity.isOwnable(entity) then return nil end

	local name = "Nobody"

	if arista.entity.isOwned(entity) then
		local owner = arista.entity.getOwner(entity)

		if type(owner) == "Player" and IsValid(owner) then
			name = owner:Name()
		elseif type(owner) == "number" then
			name = "The " .. team.GetName(owner)

			if not name:sub(-1,-1) == "r" then
				name = name .. "s"
			end
		elseif type(owner) == "string" then
			local aspl = owner:Split(";")
			local group, gang = tonumber(aspl[1]), tonumber(aspl[2])

			if group and gang then
				name = arista.team.gangs[group][gang].name
			end
		else
			arista.logs.logNoPrefix(arista.logs.E.DEBUG, "arista.entity.getPossessiveName found a really fucked up ownership (", tostring(owner), ").")

			arista.entity.clearData(entity)
		end
	end

	if name:sub(-1, -1) == "s" then
		name = name .. "'"
	else
		name = name .. "'s"
	end

	return name
end

function arista.entity.getDoorName(door)
	local addon = ""

	if arista.entity.isOwned(door) then
		addon = arista.entity.getName(door)
	end

	return addon:Trim() ~= "" and addon or "Door"
end

function arista.entity.saveAccess(player)
	arista._internaldata.entity_backup[player:UniqueID()] = {}

	for _, entity in pairs(arista._internaldata.entity_stored) do
		entity = arista.entity.getMaster(entity) or entity

		if IsValid(entity) and entity._owner.owner == player then
			arista._internaldata.entity_backup[player:UniqueID()][entity:EntIndex()] = table.Copy(entity._owner)

			arista.entity.accessChangedPlayerMulti(entity,arista.entity.getAllAccessors(entity), false)
			arista.entity.clearData(entity, true)

			if arista._internaldata.entities[entity] then
				entity:CPPISetOwner(game.GetWorld())
			end

			arista.entity.updateSlaves(entity)
		end
	end
end

function arista.entity.restoreAccess(player)
	if not arista._internaldata.entity_backup[player:UniqueID()] then return end

	for index, data in pairs(arista._internaldata.entity_backup[player:UniqueID()]) do
		entity = Entity(index)
		entity = arista.entity.getMaster(entity) or entity

		if IsValid(entity) and arista.entity.isOwnable(entity) and not arista.entity.isOwned(entity) then
			entity._owner.access = data.access
			entity._owner.owner = player

			arista.entity.setName(entity, data.name)

			arista.entity.updateSlaves(entity)

			arista.entity.accessChangedPlayerMulti(entity,arista.entity.getAllAccessors(entity),true)
		end
	end

	arista._internaldata.entity_backup[player:UniqueID()] = nil
end
