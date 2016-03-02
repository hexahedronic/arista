arista.entity = {}
arista.entity.stored = {}
arista.entity.backup = {}

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

		return
	end

	if arista.entity.isOwnable(entity) or entity:IsPlayer() then
		arista.logs.logNoPrefix(arista.logs.E.DEBUG, "arista.entity.makeOwnable was passed an already ownable entity.")

		return
	end

	arista.entity.clearData(entity)

	if arista.entity.isDoor(entity, true) then
		entity._isDoor = true
		entity._eName = "door"
	elseif entity:IsVehicle() then
		entity._isVehicle = true
		entity._eName = "vehicle"
	end

	entity:unLock()
	arista.entity.stored[entity:EntIndex()] = entity
end

-- Clear the ownership data of an entity
function arista.entity.clearData(entity, saveslaves)
	if not entity or not IsValid(entity) then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "arista.entity.clearData was passed an invalid entity (", tostring(entity), ").")

		return
	end

	--arista.entity.accessChangedPlayerMulti(entity, arista.entity.getAllAccessors(entity), false)

	--if not saveslaves and arista.entity.getMaster(entity) then
	--	arista.entity.takeSlave(arista.entity.getMaster(entity), entity)
	--end

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

	entity:networkAristaVar("ownerName", entity._owner.name)
end

/*
-- Get every player that has access to this entity
function cider.entity.getAllAccessors(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	local ret = {}
	if cider.entity.isOwned(entity) then
		local a = table.Copy(entity._Owner.access)
		table.insert(a,cider.entity.getOwner(entity))
		for k,v in ipairs(a) do
			local Type = type(v)
			if Type == "Player" then
				table.insert(ret,v)
			elseif Type == "number" then
				--It's a team
				table.Add(ret,team.GetPlayers(v))
			elseif Type == "string" then
				--It's a gang
				local tab = string.Explode(";",v)
				local group,gang = tonumber(tab[1]),tonumber(tab[2])
				local members = {}
				members = cider.team.getGangMembers(group,gang)
				if members then
					table.Add(ret,members)
				end
			end
		end
	end
	local rot = {}
	for _,ply in ipairs(ret) do
		rot[ply] = ply
	end
	ret = {}
	for _,ply in pairs(rot) do
		if ValidEntity(ply) then
			table.insert(ret,ply)
		end
	end
	return ret
end

hook.Add("PlayerChangedTeams","serverside entity library playerchangedteams",function(player)
	if not ValidEntity(player) then return end
	umsg.Start("cider_WipeAccess",player)
	umsg.End()
	timer.Simple(1,function()
		if not ValidEntity(player) then return end
		for _,entity in ipairs( cider.entity.getEntsAccess(player)) do
			cider.entity.accessChangedPlayer(entity,player,true)
		end
	end)
end)

-- Get all entities a player has access to
function cider.entity.getEntsAccess(player)
	if not (ValidEntity(player) and player:IsPlayer()) then
		error("nonvalid player passed to getEntsAccess",2)
	end
	local searchfor,ret = {},{}
	local teamID = player:Team()
	local gang = cider.team.getGang(teamID)
	local group = cider.team.getGroupByTeam(teamID)
	local id = group.index..";0"
	table.insert(searchfor,id)
	if gang then
		local id = group.index..";"..gang
		table.insert(searchfor,id)
	end
	table.insert(searchfor,teamID)
	table.insert(searchfor,player)
	for index,ent in pairs(cider.entity.stored) do
		if ValidEntity(ent) then
			local brek = false
			for _,search in ipairs(searchfor) do
				if ent._Owner.owner == search then
					table.insert(ret,ent)
					brek = true
					break
				end
			end
			for _,access in ipairs(ent._Owner.access) do
				if brek then break end
				for _,search in ipairs(searchfor) do
					if access == search then
						table.insert(ret,ent)
						brek = true
						break
					end
				end
			end
		else
			cider.entity.stored[index] = nil
		end
	end
	return ret
end

-- Tell a player their access to an entity has changed
function cider.entity.accessChangedPlayer(entity,player,bool)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if cider.entity.hasSlaves(entity) then
		for _,slave in ipairs(cider.entity.getSlaves(entity)) do
			cider.entity.accessChangedPlayer(slave,player,bool)
		end
	end
	umsg.Start("cider_IncomingAccess",player)
	umsg.Entity(entity)
	umsg.Bool(bool)
	umsg.End()
end

-- Tell lots of players their access to an entity has changed
function cider.entity.accessChangedPlayerMulti(entity,players,bool)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if cider.entity.hasSlaves(entity) then
		for _,slave in ipairs(cider.entity.getSlaves(entity)) do
			cider.entity.accessChangedPlayerMulti(slave,players,bool)
		end
	end
	if #players == 0 then return end
	local filtr = RecipientFilter()
	for _,ply in ipairs(players) do
		if ValidEntity(ply) then
			filtr:AddPlayer(ply)
		end
	end
	umsg.Start("cider_IncomingAccess",filtr)
	umsg.Entity(entity)
	umsg.Bool(bool)
	umsg.End()
end

-- Give a player access to an entity
function cider.entity.giveAccessPlayer(entity,player)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if cider.entity.isOwnable(entity) and not cider.entity.onList(entity,player) then
		table.insert(entity._Owner.access,player)
		cider.entity.accessChangedPlayer(entity,player,true)
		cider.entity.updateSlaves(entity)
	end
end

--Take a player's access away
function cider.entity.takeAccessPlayer(entity,player)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if cider.entity.isOwned(entity) then
		if cider.entity.getOwner(entity) == player then
			cider.entity.clearData(entity,true) -- if you take the owner's access, you lose all accessors
			cider.entity.updateSlaves(entity)
		else
			for key,accessor in ipairs(entity._Owner.access) do
				if accessor == player then
					table.remove(entity._Owner.access,key)
					if not cider.entity.hasAccess(entity,player) then
						cider.entity.accessChangedPlayer(entity,player,false)
					end
					cider.entity.updateSlaves(entity)
					break
				end
			end
		end
	end
end

-- Give a team access to an entity
function cider.entity.giveAccessTeam(entity,teamid)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if type(teamid) == "table" then -- We might get passed a team object
		teamid = teamid.index
	end
	if cider.entity.isOwnable(entity) and not cider.entity.onList(entity,teamid) then
		table.insert(entity._Owner.access,teamid)
		cider.entity.accessChangedPlayerMulti(entity,team.GetPlayers(teamid),true)
		cider.entity.updateSlaves(entity)
	end
end

--Take a team's access away
function cider.entity.takeAccessTeam(entity,teamid)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if type(teamid) == "table" then -- We might get passed a team object
		teamid = teamid.index
	end
	if cider.entity.isOwned(entity) then
		if cider.entity.getOwner(entity) == teamid then
			cider.entity.clearData(entity,true) -- if you take the owner's access, you lose all accessors
			cider.entity.updateSlaves(entity)
		else
			for key,accessor in ipairs(entity._Owner.access) do
				if accessor == teamid then
					table.remove(entity._Owner.access,key)
					local plyset = team.GetPlayers(teamid)
					for key,player in ipairs(plyset) do
						if cider.entity.hasAccess(entity,player) then
							table.remove(plyset,key)
						end
					end
					if #plyset > 0 then
						cider.entity.accessChangedPlayerMulti(entity,plyset,false)
					end
					cider.entity.updateSlaves(entity)
					break
				end
			end
		end
	end
end

-- Give a gang access to an entity
function cider.entity.giveAccessGang(entity,group,gang)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	else
		group = tonumber(group)
	end
	local gang = tonumber(gang)
	local gangword = group..";"..gang
	if cider.entity.isOwnable(entity) and not cider.entity.onList(entity,gangword) then
		table.insert(entity._Owner.access,gangword)
		cider.entity.accessChangedPlayerMulti(entity,cider.team.getGangMembers(group,gang),true)
		cider.entity.updateSlaves(entity)
	end
end

--Take a gang's access away
function cider.entity.takeAccessGang(entity,group,gang)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	end
	local gang = tonumber(gang)
	local gangword = group..";"..gang
	if cider.entity.isOwned(entity) then
		if cider.entity.getOwner(entity) == gangword then
			cider.entity.clearData(entity,true) -- if you take the owner's access, you lose all accessors
			cider.entity.updateSlaves(entity)
		else
			for key,accessor in ipairs(entity._Owner.access) do
				if accessor == gangword then
					table.remove(entity._Owner.access,key)
					local plyset = cider.team.getGangMembers(group,gang)
					for key,player in ipairs(plyset) do
						if cider.entity.hasAccess(entity,player) then
							table.remove(plyset,key)
						end
					end
					if #plyset > 0 then
						cider.entity.accessChangedPlayerMulti(entity,plyset,false)
					end
					cider.entity.updateSlaves(entity)
					break
				end
			end
		end
	end
end

-- Clear the owner of an entity without resetting access. This should only ever be called if a new owner is about to be set.
function cider.entity.clearOwner(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if not cider.entity.isOwnable(entity) then
		 cider.entity.makeOwnable(entity)
	end
	entity = cider.entity.getMaster(entity) or entity
	local owner = cider.entity.getOwner(entity)
	if owner then
		local ret = {}
		local Type = type(owner)
		if Type == "Player" then
			table.insert(ret,owner)
		elseif Type == "number" then
			--It's a team
			table.Add(ret,team.GetPlayers(owner))
		elseif Type == "string" then
			--It's a gang
			local tab = string.Explode(";",owner)
			local group,gang = tonumber(tab[1]),tonumber(tab[2])
			local members = {}
			members = cider.team.getGangMembers(group,gang)
			if members then
				table.Add(ret,members)
			end
		end
		cider.entity.accessChangedPlayerMulti(entity,ret,false)
		entity._Owner.name = "Nobody"
		entity._Owner.owner = NULL
		entity:SetNWString("cider_ownerName",entity._Owner.name)
		cider.entity.updateSlaves(entity)
	end
end

-- Set a player to be the owner of an entity
function cider.entity.setOwnerPlayer(entity,player)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	cider.entity.clearOwner(entity)
	entity._Owner.name = player:Name()
	entity._Owner.owner = player
	entity:SetNWString("cider_ownerName",entity._Owner.name)
	cider.entity.updateSlaves(entity)
	cider.entity.accessChangedPlayer(entity,player,true)
end

--Set a team to be the owner of an entity
function cider.entity.setOwnerTeam(entity,teamid)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	cider.entity.clearOwner(entity)
	entity._Owner.name = team.GetName(teamid)
	entity._Owner.owner = teamid
	entity:SetNWString("cider_ownerName",entity._Owner.name)
	cider.entity.updateSlaves(entity)
	cider.entity.accessChangedPlayerMulti(entity,team.GetPlayers(teamid),true)
end

-- Set a gang to be the owner of an entity
function cider.entity.setOwnerGang(entity,group,gang)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	entity = cider.entity.getMaster(entity) or entity
	cider.entity.clearOwner(entity)
	if type(group) == "table" then -- We might get passed a group object
		group = group.index
	else
		group = tonumber(group) or 0
	end
	local gang = tonumber(gang)
	if not cider.team.gangs[group] or not cider.team.gangs[group][gang] then
		error("Invalid group or gang sent. :/",2)
		return false
	end
	local gangword = group..";"..gang
	entity._Owner.name = cider.team.gangs[group][gang][1]
	entity._Owner.owner = gangword
	entity:SetNWString("cider_ownerName",entity._Owner.name)
		cider.entity.updateSlaves(entity)
	cider.entity.accessChangedPlayerMulti(entity,cider.team.getGangMembers(group,gang),true)
end

-- Set the name of an entity
function cider.entity.setName(entity,name,ffsshutup)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if not ffsshutup then
		entity = cider.entity.getMaster(entity) or entity
	end
	if cider.entity.isOwnable(entity) then
		entity._Owner.name = name
		entity:SetNWString("cider_ownerName",entity._Owner.name)
		cider.entity.updateSlaves(entity)
	end
end
-- Get hte name of an entity
function cider.entity.getName(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if cider.entity.isOwnable(entity) then
		return entity._Owner.name
	end
end

-- Check to see if an entity can be owned
function cider.entity.isOwnable(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	return tobool(entity._Owner)
end

-- Check to see if an entity is owned
function cider.entity.isOwned(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	return entity._Owner and entity._Owner.name ~= "Nobody"
end

-- Get the owner's name of an entity
function cider.entity.getOwner(entity)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if cider.entity.isOwned(entity) then
		return entity._Owner.owner
	end
	return nil
end

-- Is this entry on the list?
function cider.entity.onList(entity,entry,noown)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if not cider.entity.isOwned(entity) then
		return false
	end
	if cider.entity.getOwner(entity) == entry and not noown then
		return true
	end
	for _,access in ipairs(entity._Owner.access) do
		if access == entry then
			return true
		end
	end
	return false
end


-- Does the player have access to the entity?
function cider.entity.hasAccess(entity,player)
	if not ValidEntity(entity) then
		error("Tried to use a NULL entity!",2)
	end
	if not cider.entity.isOwned(entity) then
	--	MsgN"UnOwned!"
		return false
	end
	local team = player:Team()
	local group,gang = cider.team.getGroupByTeam(team).index,cider.team.getGang(team) or 0
	local tag = tostring(group)..";"..tostring(gang)
	local tag2 = tostring(group)..";"..0
	--MsgN(team,"\t",group,"\t",gang,"\t",tag)
	--MsgN(cider.entity.getOwner(entity))
	--PrintTable(group)
	--PrintTable(gang)
	if cider.entity.getOwner(entity) == player or cider.entity.getOwner(entity) == tag or cider.entity.getOwner(entity) == tag2 or cider.entity.getOwner(entity) == team then
		return true
	end
	for _,ting in ipairs(entity._Owner.access) do
		if ting == team or ting == tag or ting == player then
			return true
		end
	end
	return false
end

local function unbreach(ent)
	if (not IsValid(ent)) then return end
	ent._Jammed = nil;
	ent:UnLock(0,true);
	local close = ent._Autoclose or GM.Config["Door Autoclose Time"];
	local class = ent:GetClass();
	if (class:find"func_door") then
		ent:SetKeyValue("wait",close);
	elseif (class:find"prop_door") then
		ent:SetKeyValue("returndelay",close);
	end
	cider.entity.closeDoor(ent,0);
end
function cider.entity.openDoor(ent, delay, unlock, sound, jam)
	if (not IsValid(ent)) then
		error("Tried to use a NULL entity!",2);
	elseif (not (cider.entity.isDoor(ent) and cider.entity.isOwnable(ent))) then
		return false;
	elseif (delay and delay > 0) then
		return timer.Simple(delay,cider.entity.openDoor,ent,0,unlock,sound,jam);
	elseif (ent._Jammed or ent._Sealed or ent._DoorState == "open") then
		return false;
	end
	delay = 0;
	if (unlock) then
		ent:UnLock();
		delay = 0.025;
	end
	if (ent:GetClass() == "prop_dynamic") then
		ent:Fire("setanimation", "open", delay);
		ent._DoorState = "open";
		ent._Autoclose = ent._Autoclose or GM.Config["Door Autoclose Time"];
	else
		ent:Fire("open","",delay);
	end
	if (jam) then
		ent._Jammed = true;
		ent:Lock(delay + 0.025,true);
		local class = ent:GetClass();
		if (class:find"func_door") then
			ent:SetKeyValue("wait",GM.Config["Jam Time"]);
		elseif (class:find"prop_door") then
			ent:SetKeyValue("returndelay",GM.Config["Jam Time"]);
		end
		timer.Simple(GM.Config["Jam Time"], unbreach, ent);
	elseif (ent._Autoclose or 0 > 0) then
		cider.entity.closeDoor(ent,ent._Autoclose);
	end
end

function cider.entity.closeDoor(ent, delay, lock)
	if (not IsValid(ent)) then
		error("Tried to use a NULL entity!",2);
	elseif (not (cider.entity.isDoor(ent) and cider.entity.isOwnable(ent))) then
		return false;
	elseif (delay and delay > 0) then
		return timer.Simple(delay,cider.entity.closeDoor,ent,0,lock);
	elseif (ent._Jammed or ent._Sealed or ent._DoorState == "closed") then
		return false;
	elseif (ent:GetClass() == "prop_dynamic") then
		ent:Fire("setanimation","close",0);
		ent._DoorState = "closed";
	else
		ent:Fire("close","",0);
	end
	if (lock) then
		ent:Lock(0.025);
	end
end

--Get the possessive name of the entity's owner.
--WARNING: This may look wrong with some team names. Try not to give entities to teams whose names end in 'r' with more than one player in them when you are planning to call this function.
function cider.entity.getPossessiveName(entity)
	if not cider.entity.isOwnable(entity) then return nil end
	local name = "Nobody"
	if cider.entity.isOwned(entity) then
		local owner = cider.entity.getOwner(entity)
		if type(owner) == "Player" and ValidEntity(owner) then
			name = owner:Name()
		elseif type(owner) == "number" then
			name = "the "..team.GetName(owner)
			if not name:sub(-1,-1) == "r" then
				name = name.."s"
			end
		elseif type(owner) == "string" then
			local aspl = string.Explode(";",owner)
			local group,gang = tonumber(aspl[1]),tonumber(aspl[2])
			name = cider.team.gangs[group][gang][1]
		else
			--Something has gone very wrong, so let's start again! :>
			cider.entity.clearData(entity)
		end
	end
	if name:sub(-1,-1) == "s" then
		name = name.."'"
	else
		name = name.."'s"
	end
	return name
end

function cider.entity.getDoorName(door)
	local doorname = door:GetNWString("Name")
	local addon = ""
	if cider.entity.isOwned(door) then
		addon = cider.entity.getName(door)
	end
	if doorname and doorname ~= "" then
		if addon ~= "" then
			addon = doorname.." - "..addon
		else
			addon = doorname
		end
	end
	return addon
end

function cider.entity.setMaster(entity,master,nvm)
	if not cider.entity.isOwnable(entity) then return nil end
	if master == NULL then -- I have been set loose. whoo-hoo.
		cider.entity.takeSlave(cider.entity.getMaster(entity),entity)
		entity._Owner.master = master
		cider.entity.clearData(entity)
		return true
	end
	if not (ValidEntity(master) and cider.entity.isOwnable(master)) then return nil end
	if master == entity or cider.entity.getMaster(entity) == master then return nil end
	if cider.entity.hasSlaves(entity) then -- Make any slaves I happen to have slaves of my new master
		for _,slave in ipairs(cider.entity.getSlaves(entity)) do
			cider.entity.setMaster(slave,master,true)
		end
	end
	cider.entity.clearData(entity)
	entity._Owner.master = master
	cider.entity.giveSlave(master,entity)
	if not nvm then -- Only need to do this once
		cider.entity.updateSlaves(master) --
	end
end

function cider.entity.getMaster(entity)
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity)) then return end
	return ValidEntity(entity._Owner.master) and entity._Owner.master or nil
end
--entity = cider.entity.getMaster(entity) or entity
function cider.entity.getSlaves(entity)
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity)) then return end
	local ret = {}
	for key,slave in ipairs(entity._Owner.slaves) do
		if ValidEntity(slave) and cider.entity.isOwnable(slave) then
			table.insert(ret,slave)
		else
			table.remove(entity._Owner.slaves,key)
		end
	end
	return ret
end
function cider.entity.hasSlaves(entity)
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity)) then return end
	return #cider.entity.getSlaves(entity) > 0
end
-- This function can potentially be quite network intensive. Try not to call it too often
function cider.entity.updateSlaves(entity)
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity) and cider.entity.hasSlaves(entity)) then return end
	for _,slave in ipairs(cider.entity.getSlaves(entity)) do
		slave._Owner.access = entity._Owner.access
		slave._Owner.owner  = entity._Owner.owner
		cider.entity.setName(slave,entity._Owner.name,true)
	end
end
function cider.entity.giveSlave(entity,slave)
	if not (ValidEntity(entity) and ValidEntity(slave) and cider.entity.isOwnable(entity) and cider.entity.isOwnable(slave)) then return end
	entity = cider.entity.getMaster(entity) or entity
	for _,v in ipairs(entity._Owner.slaves) do
		if v == slave then
			return
		end
	end
	table.insert(entity._Owner.slaves,slave)
end
function cider.entity.takeSlave(entity,slave)
	if not (ValidEntity(entity) and ValidEntity(slave) and cider.entity.isOwnable(entity)
	   and  cider.entity.isOwnable(slave) and cider.entity.hasSlaves(entity))
	then return end
	local slaves = entity._Owner.slaves
	for key,islave in ipairs(slaves) do
		if islave == slave or not ValidEntity(islave) then
			table.remove(slaves,key)
		end
	end
end

function cider.entity.saveAccess(player)
	cider.entity.backup[player:UniqueID()] = {}
	for _,entity in pairs(cider.entity.stored) do
		entity = cider.entity.getMaster(entity) or entity
		if ValidEntity(entity) and entity._Owner.owner == player then
			cider.entity.backup[player:UniqueID()][entity:EntIndex()] = table.Copy(entity._Owner)
			cider.entity.accessChangedPlayerMulti(entity,cider.entity.getAllAccessors(entity),false)
			cider.entity.clearData(entity,true)
			if GAMEMODE.entities[entity] then
				cider.propprotection.GiveToWorld(entity)
				cider.propprotection.ClearSpawner(entity)
			end
			cider.entity.updateSlaves(entity)
		end
	end
end
function cider.entity.restoreAccess(player)
	if not cider.entity.backup[player:UniqueID()] then return end
	for index,data in pairs(cider.entity.backup[player:UniqueID()]) do
		entity = Entity(index)
		entity = cider.entity.getMaster(entity) or entity
		if ValidEntity(entity) and cider.entity.isOwnable(entity) and not cider.entity.isOwned(entity) then
			entity._Owner.access = data.access
			entity._Owner.owner = player
			cider.entity.setName(entity,data.name)
			cider.entity.updateSlaves(entity)
			cider.entity.accessChangedPlayerMulti(entity,cider.entity.getAllAccessors(entity),true)
		end
	end
	cider.entity.backup[player:UniqueID()] = nil
end

timer.Create("cider_entityClear",GM.Config["Earning Interval"],0,function()
	for index,ent in pairs(cider.entity.stored) do
		if not ValidEntity(ent) then
			cider.entity.stored[index] = nil
		end
	end
end)
*/
