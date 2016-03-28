arista.file.makeDir("doors")

PLUGIN.Doors = {}

function PLUGIN:LoadDoors()
	local path = "doors/" .. game.GetMap() .. ".txt"

	if not arista.file.existsData(path) then
		return
	end

	-- Load the data and attempt to decode it
	local data = arista.file.readData(path)
	local status, results = pcall(arista.utils.deSerialize, data)

	if status == false then -- Yes I know 'not status' is the same thing but this looks nicer in the circumstances.
		error("["..os.date().."] Doors Plugin: Error decoding '" .. path .. "': " .. results)
	elseif not results or table.Count(results) == 0 then -- If we end up with an empty table, why bother doing more?
		return
	end

	local validents = {}
	for _, ent in ipairs(ents.GetAll()) do
		if ent:IsValid() and arista.entity.isOwnable(ent) and arista.entity.isDoor(ent) then
			validents[#validents + 1] = ent

			ent._startPos = ent:GetPos()
		end
	end

	local numents = #validents
	if numents < 1 then -- You never know.
		error("["..os.date().."] Doors Plugin: a " .. #results .. " long file exists for " .. game.GetMap() .. " but it has no suitable entities!")
	end

	local radiusSquared = 4 -- Our SQUARED search radius. A 1r sphere should do the job fine.
	for i = 1, #results do-- Loop through our results
		local data = results[i]

		for i = 1, numents do -- Loop through our suitable ents
			local entity = validents[i]

			if (data.position - entity:GetPos()):LengthSqr() <= radiusSquared then -- Check if the current ent is within a unit of our target
				-- Now we check if the data has various things set on it, and apply them if so
				if data.master then -- Does this door have a master entity?
					for i = 1, numents do -- Loop through our suitable ents (again!)
						local master = validents[i]

						if (data.Master - entity:GetPos()):LengthSqr() <= radiusSquared then -- Check if the current ent is within a unit of our target
							arista.entity.setMaster(entity, master) -- If it is, set it as the entity's master.

							break -- We can either have the last appropriate entity as the master, or the first. Let's choose the first for speed.
						end
					end
				end

				if data.sealed then -- Is this door sealed?
					entity:networkAristaVar("sealed", true)
				end

				if data.preOwned then -- Is this door pre-owned by a team or gang?
					if data.preOwned == "team" then -- If it's a team that owns it
						arista.entity.setOwnerTeam(entity, data.owner)
					else -- Otherwise a gang must own it.
						arista.entity.setOwnerGang(entity, data.owner[1], data.owner[2])
					end
				end

				if data.name then -- Does this door have a custom name?
					entity:networkAristaVar("name", data.name)
				end

				if data.unownable then -- Is this door unownable?
					if not data.preOwned then -- If the door doesn't already have an owner
						arista.entity.setOwnerTeam(entity, TEAM_NONE) -- Give it to the dummy team we set up earlier, so no one else can have it.
					end

					arista.entity.setName(entity, data.unownable) -- Give it it's custom name.
					entity._unownable = true -- Let the server know.
				end

				self.Doors[entity] = data -- Save all this for future usage/saveage
			end
		end
	end
end


-- Called when all good plugins should load their datas. (Normally a frame after InitPostEntity)
function PLUGIN:LoadData()
	timer.Simple(FrameTime() * 5, function() self:LoadDoors() end) -- Load the doors in what (if we're lucky) will be 5 frames time.
end

-- Called when a player attempts to jam a door (ie with a breach)
function PLUGIN:PlayerCanJamDoor(ply, door)
	if door._unownable then
		return false
	end
end

--Called when a player attempts to own a door.
function PLUGIN:PlayerCanOwnDoor(player, door)
	if door._unownable then
		return false
	end
end

-- Gets the data for the door, either creating it if it doesn't exist or returning a blank table.
function PLUGIN:GetDoorData(door, create)
	local ret
	if self.Doors[door] then
		ret = self.Doors[door]
	elseif create then
		ret = {
			position = door._startPos or door:GetPos()
		}
		self.Doors[door] = ret
	else
		ret = {}
	end

	return ret
end


function PLUGIN:SaveData()
	local tocode = {}
	local count = 0

	for ent, data in pairs(self.Doors) do -- Loop through our stored door data
		if IsValid(ent) and table.Count(data) > 0 then -- Make sure this door exists and has data
			count = count + 1

			tocode[count] = data
		else
			self.Doors[ent] = nil
		end
	end

	if count < 1 then
		return
	end

	local status, result = pcall(arista.utils.serialize, tocode)

	if status == false then
		error("["..os.date().."] Doors Plugin: Error encoding doors : " .. tostring(results))
	end

	local path = "doors/" .. game.GetMap() .. ".txt"

	if not result or result == "" then
		if arista.file.existsData(path) then
			arista.file.deleteData(path)
		end

		return
	end

	arista.file.writeData(path, result)
end

function PLUGIN:EntityNameSet(door, name)
	if not (IsValid(door) and arista.entity.isOwnable(door) and door._isDoor) then
		return
	elseif not name or name == "" then
		self:GetDoorData(door).name = nil
	else
		self:GetDoorData(door, true).name = name
	end

	self:SaveData()
end

function PLUGIN:EntityMasterSet(door,master)
	if not (IsValid(door) and arista.entity.isOwnable(door) and door._isDoor) then
		return
	elseif IsValid(master) then
		self:GetDoorData(door,true).master = master:GetPos()
	else
		self:GetDoorData(door).master = nil
	end

	self:SaveData()
end

function PLUGIN:EntitySealed(door, unsealed)
	if not (IsValid(door) and arista.entity.isOwnable(door) and door._isDoor) then
		return
	elseif unsealed then
		self:GetDoorData(door).sealed = nil
	else
		self:GetDoorData(door, true).sealed = true
	end

	self:SaveData()
end

function PLUGIN:EntityOwnerSet(door, kind, target)
	if not (IsValid(door) and arista.entity.isOwnable(door) and door._isDoor) then
		return
	end

	if kind == "player" then return end

	local data = self:GetDoorData(door, true)

	if data.preOwned == kind and data.owner == target then
		return
	elseif kind == "remove" then
		data.preOwned = nil
		data.onwer = nil
	else
		data.preOwned = kind
		data.owner = target
	end

	if data.unownable then
		arista.entity.setName(door, data.unownable)
	end

	self:SaveData()
end

arista.command.add("unownable", "s", 0, function(ply, action, ...)
	local plugin = GAMEMODE:GetPlugin"doors"
	if not plugin then return end

	local door = ply:GetEyeTraceNoCursor().Entity
	if not (IsValid(door) and arista.entity.isOwnable(door) and door._isDoor) then
		return false, "AL_INVALID_DOOR"
	end

	door = arista.entity.getMaster(door) or door

	if action == "remove" then
		if not door._unownable then
			return false, "AL_INVALID_UNOWNABLE"
		end

		door._unownable = nil

		arista.entity.clearData(door, true)

		local data = plugin:GetDoorData(door)
		if data.preOwned then
			if data.preOwned == "team" then
				arista.entity.setOwnerTeam(door, data.owner)
			else
				arista.entity.setOwnerGang(door, data.owner[1], data.owner[2])
			end
		else
			arista.entity.updateSlaves(door)
		end

		local name = arista.entity.getDoorName(door)
		ply:notify("AL_X_NOLONGER_UNOWNABLE", name)
	else
		local name = (action or "") .. " " .. table.concat({...}, " ")
		name = name:Trim()

		local data = plugin:GetDoorData(door, true)
		data.unownable = name
		door._unownable = true

		if not data.preOwned then
			arista.entity.clearData(door, true)
			arista.entity.setOwnerTeam(door, TEAM_NONE)
		elseif data.owner ~= arista.entity.getOwner(door) then
			if data.preOwned == "team" then
				arista.entity.setOwnerTeam(door, data.owner)
			else
				arista.entity.setOwnerGang(door, data.owner[1], data.owner[2])
			end
		end

		arista.entity.setName(door,name)

		name = arista.entity.getDoorName(door)
		ply:notify("AL_X_NOW_UNOWNABLE", name)
	end

	plugin:SaveData()
end, "AL_COMMAND_CAT_SADMIN", true)
