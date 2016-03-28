arista.file.makeDir("prisonpoints")

PLUGIN.prisonpoints = {}

function PLUGIN:LoadData()
	local path = "prisonpoints/" .. game.GetMap() .. ".txt"

	if not arista.file.existsData(path) then
		return
	end

	local data = arista.file.readData(path)
	local status, results = pcall(arista.utils.deSerialize, data)

	if status == false then
		error("["..os.date().."] prisonpoints Plugin: Error decoding '" .. path .. "': " .. results)
	elseif not results then
		return
	end

	self.prisonpoints = results
end

function PLUGIN:SaveData()
	local status, result = pcall(arista.utils.serialize, self.prisonpoints)

	if status == false then
		error("["..os.date().."] prisonpoints Plugin: Error encoding prisonpoints : " .. results)
	end

	local path = "prisonpoints/" .. game.GetMap() .. ".txt"

	if not result or result == "" then
		if arista.file.existsData(path) then
			arista.file.deleteData(path)
		end

		return
	end

	arista.file.writeData(path, result)
end

function PLUGIN:PlayerArrested(ply)
	if table.Count(self.prisonpoints) < 1 then
		arista.player.notifyAll("AL_PRISONPOINTS_NOSET")
		return
	end

	local data = table.Random(self.prisonpoints)
	ply:SetPos(data.pos)
	ply:SetAngles(data.ang)
end

-- A command to add a player prison point.
arista.command.add("prisonpoint", "a", 1, function(ply, action)
	local plugin = GAMEMODE:GetPlugin"prisonpoints"
	if not plugin then return end

	local points = plugin.prisonpoints

	local action = action:lower()
	if action == "add" then
		local pos = ply:GetPos()
		table.insert(points, {pos = pos, ang = ply:GetAngles()})

		ply:notify("AL_PRISONPOINTS_ADD")
	elseif action == "remove" then
		if not table.Count(points) then
			return false, "AL_PRISONPOINTS_NONE"
		end

		local pos = ply:GetEyeTraceNoCursor().HitPos
		local count = 0

		for k, data in ipairs(points) do
			if (pos - data.pos):LengthSqr() <= 65536 then
				points[k] = nil
				count = count + 1
			end
		end

		if count > 0 then
			ply:notify("AL_PRISONPOINTS_REMOVE", count, table.Count(points))
		else
			return false, "AL_PRISONPOINTS_NONELOOK"
		end
	else
		return false, "AL_INVALID_ACTION"
	end

	plugin:SaveData()
end, "AL_COMMAND_CAT_ADMIN", true)
