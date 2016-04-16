AddCSLuaFile()

arista.team = {}
arista.team.gangs = {}
arista.team.index = 1
arista.team.stored = {}
arista.team.groupindex = 0
arista.team.storedgroups = {}

-- Add a new team.
function arista.team.addGroup(name, desc, access)
	arista.team.groupindex = arista.team.groupindex + 1

	arista.team.storedgroups[arista.team.groupindex] = {
		index = arista.team.groupindex,
		name = name or "Incorrectly Set Up Group",
		description = desc or "N/A.",
		access = access or "",
		gangs = {},
		teams = {},
	}
	return arista.team.groupindex
end

-- Get a team from a name of index.
function arista.team.get(name)
	if name == nil then
		arista.logs.log(arista.logs.E.WARNING, "team.get with nil name?")
	return nil end

	local team

	if tonumber(name) then
		for k, v in pairs(arista.team.stored) do
			if v.index == tonumber(name) then
				team = v
				break
			end
		end
	else
		local nm = name:lower()

		for k, v in pairs(arista.team.stored) do
			local gn = v.name:lower()

			if nm == gn or gn:find(nm, 1, true) then
				team = v
				break
			end
		end
	end

	-- Return the team that we found.
	return team
end

function arista.team.getByMember(name)
	local team

	for k, v in pairs(arista.team.stored) do
		if v[name] then
			team = v
			break
		end
	end

	-- Return the team that we found.
	return team
end

function arista.team.getGroup(name)
	local group

	-- Check if we have a number (it's probably an index).
	if tonumber(name) then
		for k, v in ipairs(arista.team.storedgroups) do
			if v.index == tonumber(name) then
				group = v
				break
			end
		end
	else
		local nm = name:lower()

		for k, v in ipairs(arista.team.storedgroups) do
			local gn = v.name:lower()

			if nm == gn or gn:find(nm, 1, true) then
				group = v
				break
			end
		end
	end

	-- Return the team that we found.
	return group
end

function arista.team.getGroupByTeam(teamID)
	-- Checks if valid team by attempting to get.
	local team = arista.team.get(teamID) or {}
	local teamID = team.index

	if not teamID then return nil end

	for groupid, group in ipairs(arista.team.storedgroups) do
		if table.HasValue(group.teams, teamID) then
			return arista.team.getGroup(group.index)
		end
		-- todo: table.HasValue is very bad!
	end

	return nil
end

function arista.team.getGang(teamID)
	local group = arista.team.getGroupByTeam(teamID)

	if not group then return nil end

	for gangid, gang in ipairs(group.gangs) do
		if table.HasValue(gang, teamID) then
			return gangid
		end
		-- todo: table.HasValue is very bad!
	end

	return nil
end

function arista.team.getGroupLevel(teamID)
	local groupdata = arista.team.query(teamID, "group", nil)

	if groupdata then
		return groupdata.level
	else
		return nil
	end
end

function arista.team.hasAccessGroup(teamID, access)
	local team = arista.team.get(teamID)

	local query = arista.team.query(team, "group", {}).access
	local success = false

	-- Check to see if the team has access.
	if query then
		if string.len(access) == 1 then
			success = tobool(query:find(access, 1, true))
		else
			for i = 1, access:len() do
				local flag = access:sub(i, i)

				-- Check to see if the team does not has this flag.
				if not arista.team.hasAccessGroup(name, flag) then
					success = false

					break
				end

				-- Return true because we have the required access.
				success = true
			end
		end
	end

	return success
end

function arista.team.getGroupTeams(groupID)
	local group
	if type(groupID) == "table" and groupID.index then
		group = groupID
	else
		group = arista.team.getGroup(groupID)
	end

	if group then
		return group.teams
	end

	return nil
end

function arista.team.getGroupBase(groupID)
	local teams = arista.team.getGroupTeams(groupID)

	if not teams then return nil end

	for _, teamid in ipairs(teams) do
		if arista.team.getGroupLevel(teamid) == 1 then
			return teamid
		end
	end

	return nil
end

function arista.team.getGangTeams(groupID, gangID)
	local group
	if type(groupID) == "table" and groupID.index then
		group = groupID
	else
		group = arista.team.getGroup(groupID)
	end

	if group then
		return group.gangs[gangID]
	end

	return nil
end

function arista.team.getGangMembers(groupID, gangID)
	local group
	if type(groupID) == "table" and groupID.index then
		group = groupID
	else
		group = arista.team.getGroup(groupID)
	end

	if not group then return nil end

	local results = {}
	local gangID = gangID or 0

	if group then
		if group.gangs[gangID] then
			for _, teamid in ipairs(group.gangs[gangID]) do
				table.Add(results, team.GetPlayers(teamid))
			end
		elseif gangID == 0 then -- Makes the entity shit work
			for _,teamid in ipairs(arista.team.getGroupTeams(groupID)) do
				table.Add(results, team.GetPlayers(teamid))
			end
		end
	end

	return results
end

-- Check if the team has the required access.
function arista.team.hasAccess(name, access)
	local query = arista.team.query(name, "access")
	local success = false

	-- Check to see if the team has access.
	if query then
		if access:len() == 1 then
			success = tobool(query:find(query, access))
		else
			for i = 1, access:len() do
				local flag = access[i]

				-- Check to see if the team does not has this flag.
				if not arista.team.hasAccess(name, flag) then
					success = false
					break
				end

				-- Return true because we have all the required access.
				success = true
			end
		end
	end

	local group = arista.team.getGroupByTeam(name)

	if group then
		if access:len() == 1 then
			success = tobool(group.access:find(access, 1, true)) or success
		else
			for i = 1, access:len() do
				local flag = access[i]

				-- Check to see if the team does not has this flag.
				if not arista.team.hasAccess(name, flag) then
					success = false
					break
				end

				-- Return true because we have all the required access.
				success = true
			end
		end
	end

	return success
end

-- Query a variable from a team.
function arista.team.query(name, key, default)
	local team = arista.team.get(name)

	-- Check to see if it's a valid team.
	if team then
		return team[key] or default
	else
		return default
	end
end

function arista.team.addGang(group, name, model, desc)
	if not group then
		arista.logs.log(arista.logs.E.ERROR, "addGang passed invalid group! (", tostring(name), ")")

		return
	end

	arista.team.gangs[group] = arista.team.gangs[group] or {}

	local id = #arista.team.gangs[group] + 1

	arista.team.gangs[group][id] = {name = name, model = model, desc = desc, index = id}

	return id
end

function arista.team.add(name, data)
	-- Check if the male and female models are a table and if not make them one.
	if data.males and type(data.males) ~= "table" then data.males = {data.males} end
	if data.females and type(data.females) ~= "table" then data.females = {data.females} end

	if not data.females then data.females = data.males end

	-- Setup data we cant trust idiots with.
	data.name = name
	data.isTeam = true
	data.index = arista.team.index

	data.models = {}

	-- Make the limit maximum players if there is none set.
	data.limit = data.limit or game.MaxPlayers()
	data.access = data.access or arista.config:getDefault("access")
	data.description = data.description or "N/A."
	data.models.male = data.males or arista.config:getDefault("male")
	data.models.female = data.females or arista.config:getDefault("female")
	data.canmake = data.canmake or arista.config:getDefault("jobCategories")
	data.cantuse = data.cantuse or {}
	data.timelimit = data.timelimit or 0
	data.waiting = data.waiting or arista.config:getDefault("jobWait")

	for k, v in ipairs(arista.config.defaults.jobCategories) do
		if not table.HasValue(data.canmake, v) then
			table.insert(data.canmake, v)
		end
	end

	--Make sure there's a group
	if not data.group then
		arista.logs.log(arista.logs.E.ERROR, "You cannot create a team without a group! (", tostring(name), ")")

		return
	elseif not (data.group.gang and data.group.access and tobool(data.group.level) and data.group.group) then
		arista.logs.log(arista.logs.E.ERROR, "Group syntax wrong! (", tostring(name), ")")

		return
	elseif not arista.team.getGroup(data.group.group) then
		arista.logs.log(arista.logs.E.ERROR, "Invalid group: "..data.group.group.." (", tostring(name), ")")

		return
	end

	-- Set the team up (this is called on the server and the client).
	team.SetUp(arista.team.index, name, data.color)

	-- Tell the group we exist (do this after setting the groups up, to prevent errors)
	local group = arista.team.getGroup(data.group.group)

	-- See if they're in a gang
	if data.group.gang > 0 then
		--Ensure the gang exists
		group.gangs[data.group.gang] = group.gangs[data.group.gang] or {}

		--Add the team to the gang
		table.insert(group.gangs[data.group.gang], data.index)
	end

	--Add the team to the group
	table.insert(group.teams, data.index)

	-- Insert the data for our new team into our table.
	arista.team.stored[name] = data

	-- Increase the team index so we don't duplicate any team.
	arista.team.index = arista.team.index + 1

	-- Return the index of the team.
	return data.index
end

-- Check to see if we're running on the client.
if CLIENT then
	arista.team.changed = arista.team.changed or false

	local function teamChanged(team)
		if not arista._playerInited then
			timer.Simple(0.5, function() teamChanged(team) end)

			return
		end

		arista.lp._nextChangeTeam = arista.lp._nextChangeTeam or {}
		arista.lp._nextChangeTeam[team] = CurTime() + arista.team.query(number, "waiting", 300)

		timer.Simple(0.1, function() arista.team.changed = true end)
	end

	net.Receive("arista_teamChange", function() teamChanged(net.ReadUInt(8) or 0) end)
end
