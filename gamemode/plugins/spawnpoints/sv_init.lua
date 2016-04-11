arista.file.makeDir("spawnpoints")

PLUGIN.spawnpoints = {}

function PLUGIN:LoadData()
	local path = "spawnpoints/" .. game.GetMap() .. ".txt"

	if not arista.file.existsData(path) then
		return
	end

	-- Load the data and attempt to decode it
	local data = arista.file.readData(path)
	local status, results = pcall(arista.utils.deSerialize, data)

	if status == false then -- Yes I know 'not status' is the same thing but this looks nicer in the circumstances.
		error("["..os.date().."] Spawnpoints Plugin: Error decoding '" .. path .. "': " .. results)
	elseif not results or table.Count(results) == 0 then -- If we end up with an empty table, why bother doing more?
		return
	end

	for name, spawns in pairs(results) do
		local info = arista.team.get(name)

		if info then
			self.spawnpoints[info.index] = spawns
		end
	end
end

function PLUGIN:SaveData()
	local status, result = pcall(arista.utils.serialize, self.spawnpoints)

	if status == false then
		error("["..os.date().."] Spawnpoints Plugin: Error encoding prisonpoints : " .. results)
	end

	local path = "spawnpoints/" .. game.GetMap() .. ".txt"

	if not result or result == "" then
		if arista.file.existsData(path) then
			arista.file.deleteData(path)
		end

		return
	end

	arista.file.writeData(path, result)
end

local spawnpoint = {
	pos = Vector(0, 0, 0),
	IsValid = function() return true end,
	GetPos = function(self) return self.pos end,
}
spawnpoint.__index = spawnpoint

setmetatable(spawnpoint, {
	__call = function(t, p)
		local o = {}
		setmetatable(o, spawnpoint)

		if p then o.pos = p end

		return o
	end
})

function PLUGIN:PostPlayerSpawn(ply, light)
	local data = self.spawnpoints[ply:Team()]

	if data and table.Count(data) > 0 then
		local spawn
		for k, v in RandomPairs(data) do
			local fakespawn = spawnpoint(v.pos)
			local res = hook.Run("IsSpawnpointSuitable", ply, fakespawn, false)

			if res then spawn = v break end
		end

		if not spawn then return end

		ply:SetPos(spawn.pos)
		ply:SetEyeAngles(spawn.ang)
	end
end

-- A command to add a player spawn point.
arista.command.add("spawnpoint", "a", 2, function(ply, action, name)
	local self = GAMEMODE:GetPlugin"spawnpoints"

	local target = arista.team.get(name)
	if not target then
		return false, "AL_INVALID_TEAM"
	end

	local points = self.spawnpoints
	local action = action:lower()

	local index = target.index
	local name = target.name

	if action == "add" then
		points[index] = points[index] or {}
		table.insert(points[index], {pos = ply:GetPos(), ang = ply:GetAngles()})

		ply:notify("AL_SPAWNPOINTS_TEAM_ADD", name)
	elseif action == "remove" then
		if not points[index] then
			return false, "AL_SPAWNPOINTS_TEAM_NONE", name
		end

		local pos = ply:GetEyeTraceNoCursor().HitPos
		local count = 0

		for k, data in pairs(points[index]) do
			if (pos - data.pos):LengthSqr() <= 65536 then
				points[index][k] = nil
				count = count + 1
			end
		end

		local left = table.Count(points[index])
		if count > 0 then
			ply:notify("AL_SPAWNPOINTS_REMOVED", count, name, left)
		else
			ply:notify("AL_SPAWNPOINTS_NONE", name)
		end

		if left == 0 then
			points[index] = nil
		end
	else
		return false, "AL_SPAWNPOINTS_INVALID"
	end

	self:SaveData()
end, "AL_COMMAND_CAT_ADMIN", true)
