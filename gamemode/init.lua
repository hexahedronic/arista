-- arista: RolePlay FrameWork --
include("sh_init.lua")

-- Setup downloads.
arista.content.addFiles()

-- Enable realistic fall damage for this gamemode.
game.ConsoleCommand("mp_falldamage 1\n")
game.ConsoleCommand("sbox_godmode 0\n")


-- Check to see if local voice is enabled.
if arista.config.vars.localVoice then
	game.ConsoleCommand("sv_voiceenable 1\n")
	game.ConsoleCommand("sv_alltalk 1\n")
	game.ConsoleCommand("sv_voicecodec voice_speex\n")
	game.ConsoleCommand("sv_voicequality 5\n")
end

-- Some useful ConVars that can be changed in game.
--CreateConVar("cider_ooc", 1)

-- Net Messages
do
	util.AddNetworkString("arista_sendMapEntities")
	util.AddNetworkString("arista_playerInitialized")
	util.AddNetworkString("arista_modelChoices")
	util.AddNetworkString("arista_laws")
end

-- Called when the server initializes.
function GM:Initialize()
	ErrorNoHalt("----------------------\n")
	ErrorNoHalt(os.date() .. " - Server starting up\n")
	ErrorNoHalt("----------------------\n")

	--local host = self.Config["MySQL Host"]
	--local username = self.Config["MySQL Username"]
	--local password = self.Config["MySQL Password"]
	--local database = self.Config["MySQL Database"]

	-- Initialize a connection to the MySQL database.
	--tmysql.initialize(self.Config["MySQL Host"], self.Config["MySQL Username"], self.Config["MySQL Password"], self.Config["MySQL Database"], 3306, 5, 5)
	arista.database.initialize() -- todo, implement

	-- Call the base class function.
	return self.BaseClass:Initialize()
end

-- Called when all of the map entities have been initialized.
function GM:InitPostEntity()
	for i, entity in pairs(ents.GetAll()) do
		--if cider.entity.isDoor(entity) then
			--cider.entity.makeOwnable(entity)
		--end
		arista._internaldata.entities[entity] = entity
	end

	-- todo: Send entities to client to eliminate weird visual issues with physguning things.

	arista.utils.nextFrame(gamemode.Call, "LoadData") -- Tell plugins to load their datas a frame after this.
	arista._internaldata.initSuccess = true

	-- Call the base class function.
	return self.BaseClass:InitPostEntity()
end

-- Called when a player attempts to arrest another player.
function GM:PlayerCanArrest(ply, target)
	if target:getAristaVar("warranted") == "arrest" then
		-- todo: warrant enums? arista.government.E.WARRANT_ARREST ?
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, ply, " arrested ", target, ".")

		return true
	end

	arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.ARREST, ply, " tried (and failed) to arrest ", target, ".")
	ply:notify("%s does not have an arrest warrant!", target:Name())
	-- todo: come back here when language system ready.
	-- Return false because the target does not have a warrant.

	return false
end

-- Called when a player attempts to unarrest a player.
function GM:PlayerCanUnarrest(ply, target)
	return true
end

-- Called when a player attempts to spawn an NPC.
function GM:PlayerSpawnNPC(ply, model)
	local res = gamemode.Call("PlayerCanDoSomething", ply, nil, true)

	if res ~= false and arista.utils.isAdmin(ply, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned an npc (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn an npc (", model, ").")

		return false
	end
end

function GM:PropSpawned(model, ent)
	--local data = self.Config["Spawnable Containers"][model:lower()]
	--if not data then return false end
	--cider.container.make(ent,data[1],data[2])
	-- todo: Readd automatic containers
end

function GM:PlayerSpawnedProp(ply, model, ent)
	local res = gamemode.Call("PropSpawned", model, ent)

	if res then
		--cider.entity.makeOwnable(ent)
		--cider.entity.setOwnerPlayer(ent,ply)
	end

	return self.BaseClass:PlayerSpawnedProp(ply, model, ent)
end

-- Called when a player attempts to spawn a prop.
function GM:PlayerSpawnProp(ply, model)
	--if ( not ply:HasAccess("eE",true) ) then return false end
	-- todo: readd hasaccess to this

	local res = gamemode.Call("PlayerCanDoSomething", ply, nil, true)

	-- Check if the player can spawn this prop.
	if res == false then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ").")

		return false
	elseif arista.utils.isAdmin(ply, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a prop (", model, ").")

		return true
	end

	-- Escape the bad characters from the model.
	model = model:gsub("%.%.", "")
	model = model:gsub("\\",  "/")
	model = model:gsub("//",  "/")

	-- Loop through our banned props to see if this one is banned.
	if false then--for k, v in pairs(self.Config["Banned Props"]) do
		if v:lower() == model:lower() then
			arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a (banned) prop (", model, ").")
			ply:notify("You cannot spawn banned props!")
			-- todo: more language stuff

			-- Return false because we cannot spawn it.
			return false
		end
	end

	-- Check if model is some junk that shouldn't spawn.
	if not arista.utils.validModel(model) then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a (invalid) prop (", model, ").")
		ply:notify("That's not a valid model!")
		-- todo: more language stuff

		return false
	elseif false then--ply:GetCount("props") > self.Config["Prop Limit"] then -- getcount likes to die, maybe replace?
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (over limit).")
		ply:notify("You hit the prop limit!")
		-- todo: more language stuff

		return false
	end

	local radius

	local ent = ents.Create("prop_physics")
		ent:SetModel(model)

	if ent:GetModel() == "models/error.mdl" then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (error?).")
		ply:notify("That's an error, god save us all.")
		-- todo: more language stuff

		return false
	end

		radius = ent:BoundingRadius()
	ent:Remove()

	-- gc me please.
	ent = nil

	-- todo: fix this lump of 'hasaccess' and radius stuff
	--[[if (radius > 100 and !ply:HasAccess("e")) --Only donators go above 100
	or (radius > 200 and !ply:HasAccess("m")) --Only mods go above 200
	or (radius > 300) then --Only admins go above 300.
		ply:Notify("That prop is too big!",1)
		return false
	end

	if ply:HasAccess("E") then
		ply._NextSpawnProp = CurTime() + 15
		if ( ply:CanAfford(self.Config["Builder Prop Cost"]) ) then
			if ply:GetCount("props") <= self.Config["Builder Prop Limit"] then
				ply:GiveMoney(-self.Config["Builder Prop Cost"])
			else
				ply:Notify("You hit the prop limit!",1)
				return false
			end
		else
			local amount = self.Config["Builder Prop Cost"] - ply.cider._Money

			-- Print a message to the player telling them how much they need.
			ply:Notify("You need another $"..amount.."!", 1)
			return false
		end
	end]]

	-- Check if they can spawn this prop yet.
	local nextSpawn = ply:getAristaVar("nextSpawnProp")

	if nextSpawn and nextSpawn > CurTime() then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (too fast).")
		ply:notify("You cannot spawn another prop for %d second(s)!", math.ceil(nextSpawn - CurTime()))

		-- Return false because we cannot spawn it.
		return false
	else
		-- todo: adjustable prop spawn delay?
		ply:setAristaVar("nextSpawnProp", CurTime() + 1)
	end

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a prop (", model, ").")

	-- Call the base class function.
	return self.BaseClass:PlayerSpawnProp(ply, model)
end

-- Called when a player attempts to spawn a ragdoll.
function GM:PlayerSpawnRagdoll(ply, model)
	if arista.utils.isAdmin(ply, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ragdoll (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ragdoll (", model, ").")

		return false
	end
end

-- Called when a player attempts to spawn an effect.
function GM:PlayerSpawnEffect(ply, model)
	if arista.utils.isAdmin(ply, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a effect (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a effect (", model, ").")

		return false
	end
end

function GM:PlayerCanDoSomething(ply, ignorealive, spawning)
	if not (ply:Alive() or ignorealive) or ply:interactionDisallowed() then
			ply:notify("You cannot do that in this state!")
			-- todo: language

			-- Return false because we cannot do it
			return false
	else
		return true
	end
end

-- Called when a player attempts to spawn a vehicle.
function GM:PlayerSpawnVehicle(ply, model, name, vtable)
	local res = gamemode.Call("PlayerCanDoSomething", ply, nil, true)

	if res == false then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ", name, " (", model, ").")

		return false
	elseif arista.utils.isAdmin(ply, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ", name, "(", model, ").")

		return true
	end

	-- Check if the model is a chair.
	-- todo: check for vehicles module / store module
	if not arista.utils.isModelChair(model) then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ", name, " (", model, ") (Non-chair).")
		ply:notify("You must buy your car from the store!")
		-- todo: language

		return false
	end

	-- todo: hasaccess here
	--if ( !ply:HasAccess("e") ) then return false end

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ", name, "(", model, ").")

	-- Call the base class function.
	return self.BaseClass:PlayerSpawnVehicle(ply, model)
end

-- A function to check whether we're running on a listen server.
local isListen
function GM:IsListenServer()
	if isListen ~= nil then
		return isListen
	end

	for k, v in pairs(player.GetAll()) do
		if v:IsListenServerHost() then
			isListen = true

			return true
		end
	end

	-- Check if we're running on single player.
	if game.SinglePlayer() then
		isListen = true

		return true
	end

	isListen = false

	-- Return false because there is no listen server host and it isn't single player.
	return false
end

-- Called when a player connects.
function GM:PlayerConnect(name, ip)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, name, " has connected. (", ip, ")")
end

-- Called when a ply has authed.
function GM:PlayerAuthed(ply, steamid)
	local name = ply:Name()

	if not name:find("[A-Za-z1-9][A-Za-z1-9][A-Za-z1-9][A-Za-z1-9]") then
		ply:Kick("A minimum of 4 alphanumeric characters is required in your name to play here.")
	elseif name:find(";") then
		ply:Kick("Please take the semi-colon out of your name.")
	elseif name:find('"') then
		ply:Kick('Please take the " out of your name.')
	end
	-- todo: language?? maybe, i mean, it's not like they can choose their kick msg xd

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, name, "(", steamid, ") has been authed by steam.")
end

-- Called when the player has initialized.
function GM:PlayerInitialized(ply)
	local donator = ply:getAristaVar("donator")

	if donator and donator > 0 then
		local expire = math.max(donator - os.time(), 0)

		-- Check if the expire time is greater than 0.
		if expire > 0 then
			local days = math.floor(((expire / 60) / 60) / 24)
			local hours = string.format("%02.f", math.floor(expire / 3600))
			local minutes = string.format("%02.f", math.floor(expire / 60 - (hours * 60)))
			local seconds = string.format("%02.f", math.floor(expire - hours * 3600 - minutes * 60))

			-- Give them their access.
			--ply:giveAccess("tpew")
			-- todo: access.

			-- Check if we still have at least 1 day.
			if days > 0 then
				ply:notify("Your Donator status expires in %d day(s).", days)
			else
				ply:Notify("Your Donator status expires in %d hour(s) %d minute(s) and %d second(s).", hours, minutes, seconds)
			end
			-- todo: language

			-- Set some Donator only player variables.
			ply:setAristaVar("knockOutTime", arista.config:getDefault("knockOutTime") / 2)
			ply:setAristaVar("spawnTime", arista.config:getDefault("spawnTime") / 2)
		else
			ply:setAristaVar("donator", 0)

			-- Take away their access and save their data.
			--ply:takeAccess("tpew")
			ply:saveData()

			-- Notify the player about how their Donator status has expired.
			ply:notify("Your Donator status has expired!")
			-- todo: language.
		end
	end

	-- Make the player a Citizen to begin with.
	ply:joinTeam(TEAM_DEFAULT)

	-- Stop this happening again.
	ply._inited = true

	-- Restore access to any entity the player owned that is currently unowned
	--cider.entity.restoreAccess(ply)
	-- todo: restore access for rejoins

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") finished connecting.")
end

-- Called when a player's data is loaded.
function GM:PlayerDataLoaded(ply, success)
	-- todo: just looking at this code makes me die a little inside.
	--[[ply._Salary					= 0;
	ply._JobTimeLimit			= 0;
	ply._JobTimeExpire			= 0;
	ply._LockpickChance			= 0;
	ply._CannotBeWarranted		= 0;
	ply._ScaleDamage			= 1;
	ply._Details				= "";
	ply._NextSpawnGender		= "";
	ply._NextSpawnGenderWord	= "";
	ply._Ammo					= {};
	ply.ragdoll					= {};
	ply._NextUse				= {};
	ply._NextChangeTeam			= {};
	ply._GunCounts				= {};
	ply._StoredWeapons			= {};
	ply._FreshWeapons			= {};
	ply. CSVars					= {}; -- I am aware that this is without a _, but I don't think it looks right with one.
	ply._Tying					= nil;
	ply._Initialized			= true;
	ply._UpdateData				= false;
	ply._Sleeping				= false;
	ply._Stunned				= false;
	ply._Tripped				= false;
	ply._Warranted				= false;
	ply._LightSpawn				= false;
	ply._ChangeTeam				= false;
	ply._beTied					= false;
	ply._HideHealthEffects		= false;
	ply._GenderWord				= "his";
	ply._Gender					= "Male";
	ply._NextOOC				= CurTime();
	ply._NextAdvert				= CurTime();
	ply._NextDeploy				= CurTime();
	-- Some player variables based on configuration.
	ply._SpawnTime				= self.Config["Spawn Time"];
	ply._ArrestTime				= self.Config["Arrest Time"];
	ply._Job					= self.Config["Default Job"];
	ply._KnockOutTime			= self.Config["Knock Out Time"];
	ply._IdleKick				= CurTime() + self.Config["Autokick time"];]]

	ply:networkAristaVar("job", arista.config:getDefault("job"))
	ply:networkAristaVar("salary", 0)
	ply:networkAristaVar("gender", "Male") -- THAT'S SEXIST!!1111111

	ply:networkAristaVar("knockOutTime", arista.config:getDefault("knockOutTime"))
	ply:networkAristaVar("spawnTime", arista.config:getDefault("spawnTime"))

	ply:networkAristaVar("nextSpawnTime", CurTime())
	ply:networkAristaVar("knockOutPeriod", 0)
	ply:networkAristaVar("unconcious", false)
	ply:networkAristaVar("ragdoll", NULL)

	ply:setAristaVar("nextChangeTeam", {})
	ply:setAristaVar("nextUse", {})
	ply:setAristaVar("gunCounts", {})
	ply:setAristaVar("storedWeapons", {})
	ply:setAristaVar("freshWeapons", {})

	-- Incase we have changed default database info.
	if success then
		local changed = false

		for k, v in pairs(arista.config.database) do
			if ply:getAristaVar(k) == nil then
				arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' initalized as '", v, "' (was missing).")

				ply:networkAristaVar(k, v)
				ply:databaseAristaVar(k)

				changed = true
			end
		end

		-- Save fixed data.
		if changed then ply:saveData() end
	end

	-- Call a hook for the gamemode.
	if not ply._inited then gamemode.Call("PlayerInitialized", ply) end

	-- Respawn them now that they have initialized and then freeze them.
	ply:Spawn()

	arista.utils.nextFrame(function()
		if not ply:IsValid() then return end

		-- Check if the player is arrested.
		if ply:getAristaVar("arrested") then
			ply:arrest()
		end

		-- We can now start updating the player's data.
		ply._updateData = true

		-- Send a net message to remove the loading screen.
		net.Start("arista_playerInitialized")
		net.Send(ply)
	end)
end

-- Mainly for the purpose of wiping data, since we fix missing vars when data loaded.
function GM:PlayerAddedToDatabase(ply)
	-- Player is new, add them to database.
	for k, v in pairs(arista.config.database) do
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' initalized as '", v, "'.")

		ply:networkAristaVar(k, v)
		ply:databaseAristaVar(k)
	end

	ply:saveData()
end

-- Called when a player initially spawns.
function GM:PlayerInitialSpawn(ply)
	if not IsValid(ply) then return end

	-- Load database data.
	ply:loadData()

	ply._modelChoices = {}
	--[[for _,team in pairs(cider.team.stored) do
		for gender,models in pairs(team.models) do
			ply._ModelChoices[gender] = ply._ModelChoices[gender] or {}
			if #models ~= 1 then
				ply._ModelChoices[gender][team.index]
					= math.random(1,#models)
			else
				ply._ModelChoices[gender][team.index] = 1
			end
		end
	end]]

	arista.utils.nextFrame(function()
		if not ply:IsValid() then return end

		net.Start("arista_modelChoices")
			net.WriteUInt(table.Count(ply._modelChoices), 8)

			for name, gender in pairs(ply._modelChoices) do
				net.WriteString(name)
				net.WriteUInt(#gender, 8)

				for team,choice in pairs(gender) do
					net.WriteUInt(team, 8)
					net.WriteUInt(choice, 8)
				end
			end
		net.Send(ply)

		net.Start("arista_laws")
			net.WriteString("the laws") -- todo: laws go here
		net.Send(ply)
	end)

	-- Kill them silently until we've loaded the data.
	ply:KillSilent()
end

-- Called every frame that a player is dead.
function GM:PlayerDeathThink(ply)
	if not ply._inited then return true end

	-- Check if the player is a bot.
	if ply:IsBot() then
		if ply.NextSpawnTime and CurTime() >= ply.NextSpawnTime then
			ply:Spawn()
		end
	end

	-- Return the base class function.
	return self.BaseClass:PlayerDeathThink(ply)
end

-- Called when a player's salary should be adjusted.
function GM:PlayerAdjustSalary(ply)
	if ply:isDonator() then
		local current = ply:getAristaVar("salary") or 1

		ply:setAristaVar("salary", current * arista.config.vars.donatorMult)
	end
end

-- Called when a player's radio recipients should be adjusted.
function GM:PlayerAdjustRadioRecipients(ply, text, recipients)
end

-- Called when a player attempts to join a gang
function GM:PlayerCanJoinGang(ply, teamid, gangid)
end
-- Called when a player should gain a frag.
function GM:PlayerCanGainFrag(ply, victim)
	return true
end

do
	local fallbackModels = {
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_02.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group01/female_05.mdl",
		"models/player/group01/female_06.mdl",
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_02.mdl",
		"models/player/group01/male_03.mdl",
		"models/player/group01/male_04.mdl",
		"models/player/group01/male_05.mdl",
		"models/player/group01/male_06.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/male_08.mdl",
		"models/player/group01/male_09.mdl",
	}

	local function fallback(ply)
		arista.logs.logNoPrefix(arista.logs.E.WARNING, ply:Name(), "(", ply:SteamID(), ") failed to locate a valid playermodel, so was randomly selected from fallbacks.")

		ply:SetModel(table.Random(fallbackModels))
	end

	-- Called when a player's model should be set.
	function GM:PlayerSetModel(ply)
		local customModel = ply:getAristaVar("customModel")
		local team = ply:Team()

		if customModel then
			if istable(customModel) and customModel[ply:Team()] then
				ply:SetModel(customModel[ply:Team()])
			else
				ply:SetModel(customModel)
			end

			return true
		end

		local models = false--cider.team.query(ply:Team(), "models")
		-- todo: getting models

		-- Check if the models table exists.
		if models then
			local gen = ply:getAristaVar("gender"):lower()
			models = models[gen]

			-- Check if the models table exists for this gender.
			if models then
				local genModels = ply._modelChoices[gen] or {}
				if not genModels[team] then return end

				local model = models[genModels[team]]

				-- Set the player's model to the we got.
				ply:SetModel(model)
			else
				-- Mayonaise is not a gender?
				fallback(ply)
			end
		else
			fallback(ply)
		end
	end
end

function GM:PlayerReSpawn(ply)
	--[[ply._Ammo = {}
	ply._Sleeping = false
	ply._Stunned = false
	ply._Tripped = false
	ply._ScaleDamage = 1
	ply._HideHealthEffects = false
	ply._CannotBeWarranted = CurTime() + 15
	ply._Deaded = nil]]
end

-- Called when a player spawns.
function GM:PlayerSpawn(ply)
	if ply._inited then
		local nextGender = ply:getAristaVar("nextGender") or ""

		if nextGender ~= "" then
			ply:setAristaVar("nextGender", "")
			ply:setAristaVar("gender", nextGender)
		end

		-- Set it so that the ply does not drop weapons.
		ply:ShouldDropWeapon(false)

		-- Check if we're not doing a light spawn.
		if not ply:getAristaVar("lightSpawn") then
			ply:recapacitate()

			-- Set some of the ply's variables.
			gamemode.Call("PlayerReSpawn", ply)

			-- Make the ply become conscious again.
			ply:wakeUp(true)

			-- Set the ply's model and give them their loadout.
			self:PlayerSetModel(ply)
			self:PlayerLoadout(ply)
		end

		-- Call a gamemode hook for when the ply has finished spawning.
		gamemode.Call("PostPlayerSpawn", ply, ply:getAristaVar("lightSpawn"), ply:getAristaVar("changeTeam"))

		-- Set some of the ply's variables.
		ply:setAristaVar("lightSpawn", false)
		ply:setAristaVar("changeTeam", false)
	else
		ply:KillSilent()
	end
end

-- Called when player is done being handled by us.
function GM:PostPlayerSpawn(ply)
end

-- Called when a ply should take damage.
function GM:PlayerShouldTakeDamage(ply, attacker)
	return true
end

-- Called when a ply is attacked by a trace.
function GM:PlayerTraceAttack(ply, damageInfo, direction, trace)
	ply:setAristaVar("lastHitGroup", trace.HitGroup)

	-- Return false so that we don't override internals.
	return false
end

-- Called just before a ply dies.
function GM:DoPlayerDeath(ply, attacker, damageInfo)
	ply:setAristaVar("dead", true)

	-- Fixes issues.
	if ply:InVehicle() then
		ply:ExitVehicle()
	end

	local backGun = ply:getAristaVar("backGun")
	if IsValid(backGun) then
		backGun:Remove()
	end

	for k, v in pairs(ply:GetWeapons()) do
		local class = v:GetClass()

		-- Check if this is a valid item.
		--[[if (self.Items[class]) then
			if ( hook.Call("PlayerCanDrop",GAMEMODE, ply, class, true, attacker) ) then
				self.Items[class]:Make(ply:GetPos(), 1);
			end
		end]]
	end

	local storedWeapons = ply:getAristaVar("storedWeapons")
	if storedWeapons and #storedWeapons > 0 then
		for _, v in pairs(storedWeapons) do
			local class = v

			-- Check if this is a valid item.
			--[[if (self.Items[class]) then
				if ( hook.Call("PlayerCanDrop",GAMEMODE, ply, class, true, attacker) ) then
					self.Items[class]:Make(ply:GetPos(), 1);
				end
			end]]
		end

		ply:setAristaVar("storedWeapons", {})
	end

	-- Unwarrant them, unarrest them and stop them from bleeding.
	if ply ~= attacker and attacker:IsPlayer() then
		ply:unWarrant()
	end

	ply:unArrest(true)
	ply:unTie(true)
	ply:stopBleeding()

	-- Strip the ply's weapons and ammo.
	ply:StripWeapons()
	ply:StripAmmo()

	-- Add a death to the ply's death count.
	ply:AddDeaths(1)

	-- Check it the attacker is a valid entity and is a ply.
	if IsValid(attacker) and attacker:IsPlayer() and ply ~= attacker then
			local res = gamemode.Call("PlayerCanGainFrag", attacker, ply)

			if res then
				attacker:AddFrags(1)
			end
	end
end

-- Called when a ply dies.
function GM:PlayerDeath(ply, inflictor, attacker, fall)
	-- Knock out the ply to simulate their death. (Even if they're allready a ragdoll, we need to handle the multiple raggies.)
	ply:knockOut()

	-- Set their next spawn time.
	local spawnTime = ply:getAristaVar("spawnTime") or arista.config:getDefault("spawnTime")
	ply:setAristaVar("nextSpawnTime", CurTime() + spawnTime)

	local class = attacker:GetClass()

	-- Check if the attacker is a ply.
	if attacker:IsPlayer() then
		local wep = attacker:GetActiveWeapon()

		if IsValid(wep) then
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was killed by ", attacker:Name(), "(", attacker:SteamID(), ") using ", wep, ".")
		else
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was killed by ", attacker:Name(), "(", attacker:SteamID(), ").")
		end
	elseif attacker:IsVehicle() then
		local name = attacker:GetClass()

		if attacker.DisplayName then
			name = attacker.DisplayName
		elseif attacker.VehicleName then
			name = attacker.VehicleName
		elseif attacker.PrintName then
			name = attacker.PrintName
		end

		if attacker:validDriver() then
			local driver = attacker:GetDriver()

			arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was ran over by ", driver:Name(), "(", driver:SteamID(), ") in a ", name,  ".")
		end

		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was ran over by a ", name,  ".")
	elseif fall then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") fell to their death.")
	elseif attacker:IsWorld() and ply == inflictor then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") starved to death.")
	elseif attacker:GetClass() == "worldspawn" then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was killed by the map.")
	elseif attacker:GetClass():find("prop_physics", 1, true) then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was killed by a prop (", attacker:GetModel(), ").")
	else
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.KILL, ply:Name(), "(", ply:SteamID(), ") was killed by ", attacker, ".")
	end
end

-- Called when an entity takes damage.
local vector0 = Vector(5, 0, 0)
function GM:EntityTakeDamage(entity, damageinfo)
	local attacker = damageinfo:GetAttacker()
	local inflictor = damageinfo:GetInflictor()

	if not entity or not attacker or not inflictor or not entity == NULL or not attacker == NULL or not inflictor == NULL then
		arista.logs.logNoPrefix(arista.logs.E.ERROR, "Invalid entity in EntityTakeDamage! ", entity, attacker, inflictor)

		return
	end

	local class = attacker:GetClass()

	if attacker:IsPlayer() then
		local wep = attacker:GetActiveWeapon()

		if IsValid(wep) then
			local class = wep:GetClass()

			if class == "weapon_stunstick" or class == "weapon_crowbar" then
				damageinfo:SetDamage(10)
			end
		end

		if attacker:GetMoveType() == MOVETYPE_NOCLIP or attacker:isStuck() or (entity:IsPlayer() and entity:GetMoveType() == MOVETYPE_NOCLIP and not entity:InVehicle()) then
			damageinfo:SetDamage(0)

			return false
		end
	end

	if entity:IsPlayer() then
		local ragdoll = entity:getRagdoll()

		if entity:isUnconscious() and IsValid(ragdoll) then
			gamemode.Call("EntityTakeDamage", ragdoll, damageinfo)
		else
			if attacker:IsVehicle() and attacker:GetVelocity():Length() > 300 then
				entity:knockOut(10, attacker:GetVelocity())

				damageinfo:SetDamage(0)

				local name = attacker:GetClass()

				if attacker.DisplayName then
					name = attacker.DisplayName
				elseif attacker.VehicleName then
					name = attacker.VehicleName
				elseif attacker.PrintName then
					name = attacker.PrintName
				end

				local car = "."
				local driver = "An unoccupied "

				if attacker:validDriver() then
					local driv = attacker:GetDriver()
					driver = driv:Name() .. "(" .. driv:SteamID() .. ")"
					car = " in a "

					car = car .. name
				else
					driver = driver .. name
				end

				arista.logs.event(arista.logs.E.LOG, arista.logs.E.DAMAGE, driver, " knocked over ", entity:Name(), "(", entity:SteamID(), ")", car)
				return
			end

			if entity:InVehicle() then
				if damageinfo:IsExplosionDamage() and (not damageinfo:GetDamage() or damageinfo:GetDamage() == 0) then
					damageinfo:SetDamage(99)
				end

				if damageinfo:GetDamage() < 1 then
					damageinfo:SetDamage(0)

					return
				end
			end

			if class:find("prop_", 1, true) and arista.config.vars.preventPropKill and not damageinfo:IsFallDamage() then
				damageinfo:SetDamage(0)

				return
			end

			local lasthit = entity:getAristaVar("lastHitGroup")

			-- Check if the player has a last hit group defined.
			if lasthit and (not attacker:IsPlayer() or (IsValid(attacker:GetActiveWeapon()) and not attacker:GetActiveWeapon():GetClass():find("hands", 1, true))) then
				if lasthit == HITGROUP_HEAD then
					damageinfo:ScaleDamage(arista.config.vars.headDmgScale)
				elseif lasthit == HITGROUP_CHEST or lasthit == HITGROUP_GENERIC then
					damageinfo:ScaleDamage(arista.config.vars.normalDmgScale)
				elseif lasthit == HITGROUP_STOMACH or lasthit == HITGROUP_RIGHTARM or lasthit == HITGROUP_LEFTARM then
					damageinfo:ScaleDamage(arista.config.vars.stomachDmgScale)
				else
					damageinfo:ScaleDamage(arista.config.vars.legDmgScale)
				end

				-- Set the last hit group to nil so that we don't use it again.
				entity:setAristaVar("lastHitGroup", nil)
			end

			-- Check if the player is supposed to scale damage.
			if entity:getAristaVar("scaleDamage") then damageinfo:ScaleDamage(entity:getAristaVar("scaleDamage")) end

			if entity:InVehicle() then
				entity:SetHealth(entity:Health() - damageinfo:GetDamage()) --Thanks gayry for breaking teh pains in vehicles.
				damageinfo:SetDamage(0)

				-- Check to see if the player's health is less than 0 and that the player is alive.
				if entity:Health() <= 0 and entity:Alive() then
					entity:KillSilent()

					-- Call some gamemode hooks to fake the player's death.
					gamemode.Call("DoPlayerDeath", entity, attacker, damageinfo)
					gamemode.Call("PlayerDeath", entity, inflictor, attacker, damageinfo:IsFallDamage())
				end
			end

			-- Make the player bleed.
			entity:bleed(arista.config.vars.bleedTime)
		end
	--[[elseif ( entity:IsNPC() ) then
		if (attacker:IsPlayer() and ValidEntity( attacker:GetActiveWeapon() )
		and attacker:GetActiveWeapon():GetClass() == "weapon_crowbar") then
			damageinfo:SetDamage(25)
		end
		local smiter = attacker:GetClass()
		local damage = damageinfo:GetDamage()
		local smitee = entity:GetClass()
		local weapon = "."
		local text = "%s damaged a %s for %G damage%s"
		if attacker:IsPlayer() then
			smiter = attacker:GetName()
			if ValidEntity( attacker:GetActiveWeapon() ) then
				weapon = " with a "..attacker:GetActiveWeapon():GetClass()
			end
		end
		GM:Log(EVENT_DAMAGE,text,smiter,smitee,damage,weapon)
	elseif cider.container.isContainer(entity) and entity:Health() > 0 then
		-- Fookin Boogs.		v
		damageinfo:SetDamageForce(vector0)
		local smiter = attacker:GetClass()
		local damage = damageinfo:GetDamage()
		local smitee = cider.container.getName(entity)
		local weapon = "."
		local text = "%s damaged a %s for %G damage%s"
		if attacker:IsPlayer() then
			smiter = attacker:GetName()
			if ValidEntity( attacker:GetActiveWeapon() ) then
				weapon = " with a "..attacker:GetActiveWeapon():GetClass()
			end
		end
		print(entity:Health(),damageinfo:GetDamage())
		entity:SetHealth(entity:Health()-damageinfo:GetDamage())
		print(entity:Health())
		if entity:Health() <= 0 then
			text = "%s destroyed a %s with %G damage%s"
			entity:SetHealth(0)
			entity:TakeDamage(1)
		end
		GM:Log(EVENT_DAMAGE,text,smiter,smitee,damage,weapon)]]
		-- todo: readd these damage checks

	-- Check if the entity is a knocked out player.
	elseif entity:isPlayerRagdoll() and not entity:isCorpse() then
		local ply = entity:getRagdollPlayer()

		-- If they were just ragdolled, give them 2 seconds of damage immunity
		if entity._time and entity._time > CurTime() then
			damageinfo:SetDamage(0)

			return false
		end

		-- Set the damage to the amount we're given.
		--damageinfo:SetDamage(amount)

		-- Check if the attacker is not a player.
		if not attacker:IsPlayer() then
			if attacker:IsWorld() then
				if (entity._nextWorldDamage and entity._nextWorldDamage > CurTime()) or damageinfo:GetDamage() <= 10 then return end

				-- Set the next world damage to be 1 second from now.
				entity._nextWorldDamage = CurTime() + 1
			elseif class:find("prop") then
				damageinfo:SetDamage(0)

				return
			else
				if damageinfo:GetDamage() <= 25 then
					return
				end
			end
		else
			if not damageinfo:IsBulletDamage() then
				damageinfo:SetDamage(0)

				return false
			end

			damageinfo:ScaleDamage(arista.config.vars.ragdollDmgScale)
		end

		-- Check if the player is supposed to scale damage.
		if ply:getAristaVar("scaleDamage") and not attacker:IsWorld() then damageinfo:ScaleDamage(ply:getAristaVar("scaleDamage")) end

		-- Take the damage from the player's health.
		ply:SetHealth(math.max(ply:Health() - damageinfo:GetDamage(), 0))

		-- Set the player's conscious health.
		entity.health = ply:Health()

		-- Create new effect data so that we can create a blood impact at the damage position.
		local effectData = EffectData()
			effectData:SetOrigin(damageinfo:GetDamagePosition())
		util.Effect("BloodImpact", effectData)

		-- Loop from 1 to 2 so that we can draw some blood decals around the ragdoll.
		for i = 1, 2 do
			local trace = {}

			-- Set some settings and information for the trace.
			trace.start = damageinfo:GetDamagePosition()
			trace.endpos = trace.start + (damageinfo:GetDamageForce() + (VectorRand() * 16) * 128)
			trace.filter = entity

			-- Create the trace line from the set information.
			trace = util.TraceLine(trace)

			-- Draw a blood decal at the hit position.
			util.Decal("Blood", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal)
		end

		-- Check to see if the player's health is less than 0 and that the player is alive.
		if ply:Health() <= 0 and ply:Alive() then
			ply:KillSilent()

			-- Call some gamemode hooks to fake the player's death.
			gamemode.Call("DoPlayerDeath", ply, attacker, damageinfo)
			gamemode.Call("PlayerDeath", ply, inflictor, attacker, damageinfo:IsFallDamage())
		end

		entity = ply
	end

	local finalDmg = math.Round(damageinfo:GetDamage())

	if entity:IsPlayer() then
		local inf = inflictor ~= attacker and " (using " .. tostring(inflictor) .. ")." or "."
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.DAMAGE, entity:Name(), "(", entity:SteamID(), ")", " was damaged for ", finalDmg, " by ", attacker, inf)
	else
		local inf = inflictor ~= attacker and " (using " .. tostring(inflictor) .. ")." or "."
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.DAMAGE, entity, " was damaged for ", finalDmg, " by ", attacker, inf)
	end
end

-- Return the damage done by a fall
function GM:GetFallDamage(ply, vel)
	local val = 580  --No idea. This was taken from the C++ source though, aparently
	return (vel - val) * (100 / (1024 - val))
end

-- Called when a player's weapons should be given.
function GM:PlayerLoadout(ply)
	--[[if ply:hasAccess("t") then]] ply:Give("gmod_tool") --end
	--[[if ply:hasAccess("p") then]] ply:Give("weapon_physgun") --end
	-- todo: hasaccess

	-- Give the player the camera, the hands and the physics cannon.
	ply:Give("gmod_camera")
	--ply:Give("cider_hands")

	ply:setAristaVar("spawnWeapons", {})
	ply:setAristaVar("gunCounts", {})

	if ply:Team() and ply:Team() > 0 then
		--[[local team = cider.team.get(ply:Team())
		if team.guns then
			for _,gun in ipairs(team.guns) do
				local give = true
				local item = self.Items[gun]
				if item then
					if item.Category then
						if ply:Blacklisted("cat",item.Category) > 0 then
							give = false
						end
					end
					if give then
						ply._SpawnWeapons[gun] = true
					end
				end
				if give then
					ply:Give(gun)
				end
			end
		end
		if team.ammo then
			for _,ammo in ipairs(team.ammo) do
				ply:GiveAmmo(ammo[2],ammo[1])
			end
		end]]
		-- todo: jobs system
	end

	-- Select the hands by default.
	--ply:SelectWeapon("cider_hands")
	-- todo: hands
end

-- Called when the server shuts down or the map changes.
function GM:ShutDown()
	ErrorNoHalt("----------------------\n")
	ErrorNoHalt(os.date().." - Server shutting down\n")
	ErrorNoHalt("----------------------\n")

	for k, v in pairs(player.GetAll() ) do
		v:holsterAll()
		ply:saveData()
	end
end

function GM:PlayerSwitchFlashlight(ply, on)
	-- Do not let the player use their flashlight while arrested, unconsious or tied.
	return not (ply:isArrested() or ply:isUnconscious() or ply:isTied())
end

-- Called when the player presses their use key (normally e) on a usable entity.
-- What specifies that an entity is usable is so far unknown, for instance some physics props are usable and others are not.
-- This hook is called once per tick while the player holds the use key down on some entities. Keep this in mind if you are going to notify them of something.
function GM:PlayerUse(ply, ent)
	if (ply:KnockedOut()) then
		-- If you're unconsious, you can't use things.
		return false
	elseif (ply:Arrested() or ply:Tied() or ply._Stunned) then
		-- Prevent spam
		if (not ply._NextNotify or CurTime() > ply._NextNotify) then
			ply:Notify("You cannot use that while in this state!", 1);
			ply._NextNotify = CurTime() + 1;
		end
		-- If you're arrested, tied, or stunned you can't use things. (no hands!)
		return false;
	elseif (cider.entity.isDoor(ent) and not gamemode.Call("PlayerCanUseDoor", ply, ent)) then
		-- If the hook says you can't open the door then don't let you. (Prevents doors that should be locked from glitching open)
		return false;
	end
	-- Let sandbox/base deal with everything else~
	return self.BaseClass:PlayerUse(ply, ent);
end

function GM:PlayerCanJoinTeam(ply, teamid)
	local teamdata-- = cider.team.get(teamid);
	-- todo: cider team here
	if not teamdata then
		return false -- If it's not a valid team (by our standards) then don't join it.
	end

	teamid = teamdata.index

	local nextChange = ply:getAristaVar("nextChangeTeam") or {}

	-- Run a series of checks
	if (nextChange[teamid] or 0) > CurTime() then
		--ply:Notify("You must wait " .. string.ToMinutesSeconds(ply._NextChangeTeam[teamid] - CurTime()) .. " before you can become a " .. teamdata.name .. "!", 1)
		-- todo: language

		return false
	elseif ply:isWarranted() then
		ply:notify("You cannot change teams while warranted!")

		return false
	elseif ply:isArrested() then
		ply:notify("You cannot change teams while arrested!")

		return false
	elseif ply:isTied() then
		ply:notify("You cannot change teams while tied up!")

		return false
	elseif gamemode.Call("PlayerCanDoSomething", ply, true) == false then
		return false
	end

	-- Ask the shared hook which handles the complex gang related things.
	return self:PlayerCanJoinTeamShared(ply, teamid)
end

function GM:PlayerDisconnected(ply)
	GM:Log(EVENT_PUBLICEVENT, "%s (%s) disconnected.", ply:Name(), ply:SteamID())
	--cider.entity.saveAccess(ply)
	--  Access incase of rejoin

	-- Holseter all weapons.
	ply:holsterAll()

	-- Get rid of any inconvenient ragdolls
	ply:wakeUp(true)

	-- Save data.
	ply:saveData()

	-- Call the base class function.
	return self.BaseClass:PlayerDisconnected(ply)
end

/*
-- Called when a player says something.
-- TODO: Move to command library
function GM:PlayerSay(ply, text, public)
	if string.find(text,"@@@@") then
		RunConsoleCommand("kickid", ply:UserID(), "Spam")
	end
	--print(ply, text,text:sub(-7), public)
	-- This is a terrible solution. OH WELL LOL
	if (text:sub(-7) == '" "0.00') then
		text = text:sub(1,-8);
		--print(text);
	end
	-- Fix Valve's errors. DODO: srsly?
	text = text:gsub(" ' ", "'"):gsub(" : ", ":");

	-- The OOC commands have shortcuts.
	if (text:sub(1,2) == "//") then
		text = text:sub(3):Trim();
		if (text == "") then
			return "";
		end
		text = self.Config['Command Prefix'] .. "ooc " .. text;
	elseif (text:sub(1,3) == ".//") then
		text = text:sub(4):Trim();
		if (text == "") then
			return "";
		end
		text = self.Config['Command Prefix'] .. "looc " .. text;
	end
	if ( string.sub(text, 1, 1) == self.Config["Command Prefix"] ) then
		--TODO: Rewrite with gmatch chunks
		text = text:sub(2)
		local args = string.Explode(" ", text)
		local j,tab,quote = 1,{},false
		for i = 1,#args do
			local text = args[i]
			if quote then
				tab[j] = tab[j] .. " "
			else
				if text:sub(1,1) == '"' then
					quote = true
					text = text:sub(2)
				end
				tab[j] = ""
			end
			if text:sub(-1) == '"' then
				quote = false
				text = text:sub(1,-2)
			end
			tab[j] = tab[j] .. text
			if not quote then
				j = j + 1
			end
		end
		cider.command.consoleCommand(ply,_,tab)
	else
		if ( gamemode.Call("PlayerCanSayIC", ply, text) ) then
			if (ply:Arrested()) then
				cider.chatBox.addInRadius(ply, "arrested", text, ply:GetPos(), self.Config["Talk Radius"])
			elseif ply:Tied() then
				cider.chatBox.addInRadius(ply, "tied", text, ply:GetPos(), self.Config["Talk Radius"])
			else
				cider.chatBox.addInRadius(ply, "ic", text, ply:GetPos(), self.Config["Talk Radius"])
			end
			GM:Log(EVENT_TALKING,"%s: %s",ply:Name(),text)
		end
	end
	-- Return an empty string so the text doesn't show.
	return ""
end

-- Called when a player attempts suicide.
function GM:CanPlayerSuicide(ply)
	return false;
end

local function utwin(ply, ent)
	if (IsValid(ply)) then
		ply:Emote("somehow manages to cut through the rope and puts " .. ply._GenderWord .. " knife away, job done.");
		ply._Untying = false;
	end if (IsValid(ent)) then
		ent:Emote("shakes the remains of the rope from " .. ent._GenderWord .. " wrists and rubs them");
		ent:UnTie();
		ent._beUnTied = false;
	end
	gamemode.Call("PlayerUnTied", ply, ent);
end

local function utfail(ply, ent)
	if (IsValid(ent) and ent:Alive()) then
		ent:Emote("manages to dislodge " .. ply:Name() .. "'s attempts.");
		ent._beUnTied = false;
	end if (IsValid(ply) and ply:Alive()) then
		ply:Emote("swears and gives up.");
		ply._UnTying = false;
	end
end

local function uttest(ply, ent, ppos, epos)
	return IsValid(ply) and ply:Alive() and ply:GetPos() == ppos and IsValid(ent) and ent:Alive() and ent:GetPos() == epos;
end

-- Called when a player presses a key.
function GM:KeyPress(ply, key)
	ply._IdleKick = CurTime() + self.Config["Autokick time"]
	if (key == IN_JUMP) then
		if( ply._StuckInWorld) then
			ply:HolsterAll()
			-- Spawn them lightly now that we holstered their weapons.
			local health = ply:Health()
			ply:LightSpawn();
			ply:SetHealth(health) -- Stop people abusing map glitches
		elseif( ply:KnockedOut() and (ply._KnockoutPeriod or 0) <= CurTime() and ply:Alive()) then
			ply:WakeUp();
		end
	elseif (key == IN_USE) then
		-- Grab what's infront of us.
		local ent = ply:GetEyeTraceNoCursor().Entity
		if (not IsValid(ent)) then
			return;
		elseif (IsValid(ent._Player)) then
			ent = ent._Player;
		end
		if (ent:IsPlayer()
		and ply:KeyDown(IN_SPEED)
		and gamemode.Call("PlayerCanUntie", ply, ent)
		and ent:GetPos():Distance(ply:GetPos()) < 200) then
			ply:Emote("starts ineffectually sawing at " .. ent:Name() .. "'s bonds with a butter knife");
			timer.Conditional(ply:UniqueID() .. " untying timer", self.Config['UnTying Timeout'], uttest, utwin, utfail, ply, ent, ply:GetPos(), ent:GetPos());
			ply._UnTying = true;
			ent._beUnTied = true;
		--[[~ Open mah doors ~]]--
		elseif cider.entity.isDoor(ent) and ent:GetClass() ~= "prop_door_rotating" and gamemode.Call("PlayerCanUseDoor", ply, ent) then
			cider.entity.openDoor(ent,0);
		--[[~ Crank dem Containers Boi ~]]--
		elseif cider.container.isContainer(ent) and gamemode.Call("PlayerCanUseContainer", ply, ent) then
			--[[
				tab = {
					contents = {
						cider_usp45 = 2,
						chinese_takeout = 4,
						money = 20000, -- Money is now an item for containers, so put the player's money in the inventory window. (It's not in there by default)
						boxed_pocket = 5
					},
					meta = {
						io = 3, -- READ_ONLY = 0, TAKE_ONLY = 1, PUT_ONLY = 2, TAKE_PUT = 3
						filter = {money,weapon_crowbar}, -- Only these can be put in here, if nil then ignore, but empty means nothing.
						size = 40, -- Max space for the container
						entindex = 64, -- You'll probably want it for something
					}
				}
			--]]
			local contents, io, filter = cider.container.getContents(ent, ply, true);
			local tab = {
				contents = contents,
				meta = {
					io = io,
					filter = filter, -- Only these can be put in here, if nil then ignore, but empty means nothing.
					size = cider.container.getLimit(ent), -- Max space for the container
					entindex = ent:EntIndex(), -- You'll probably want it for something
					name = cider.container.getName(ent) or "Container"
				}
			}
			datastream.StreamToClients( ply, "cider_Container", tab );
		end
	end
end

function GM:SetPlayerSpeed(ply)
	if (ply:GetNWBool("Incapacitated") or not ply:Recapacitate()) then
		ply:Incapacitate();
	end
end

-- Called when a player presses F1.
function GM:ShowHelp(ply) umsg.Start("cider_Menu", ply) umsg.End() end

-- Called when a player presses F2.
function GM:ShowTeam(ply)
	local door = ply:GetEyeTraceNoCursor().Entity
	-- Check if the player is aiming at a door.
	if not(ValidEntity(door)
	   and cider.entity.isOwnable(door)
	   and ply:GetPos():Distance( ply:GetEyeTraceNoCursor().HitPos ) <= 128
	 ) then
			return
	end
	if hook.Call("PlayerCanOwnDoor",GAMEMODE,ply,door) then
		umsg.Start("cider_BuyDoor",ply)
		umsg.End()
		return
	end
	if not hook.Call("PlayerCanViewEnt",GAMEMODE,ply,door) then
		ply:Notify("You do not have access to that!",1)
		return
	end
	local detailstable = {}
	local owner = cider.entity.getOwner(door)
	detailstable.access = table.Copy(door._Owner.access)
	table.insert(detailstable.access,owner)
	if owner == ply then
		detailstable.owned = {
			sellable = tobool(door._isDoor and not door._Unsellable) or nil,
			name = hook.Call("PlayerCanSetEntName",GAMEMODE,ply,door) and cider.entity.getName(door) or nil,
		}
	end
	detailstable.owner = cider.entity.getPossessiveName(door)
	if door._isDoor then
		detailstable.owner = detailstable.owner.." door"
	else
		detailstable.owner = detailstable.owner.." "..door:GetNWString("cider_Name","entity")
	end
	datastream.StreamToClients(ply,"cider_Access",detailstable)
end

function GM:ShowSpare1(ply)
-- ):
end

-- Called when a ply attempts to spawn a SWEP.
function GM:PlayerSpawnSWEP(ply, class, weapon)
	if ply:IsSuperAdmin() then
		GM:Log(EVENT_SUPEREVENT,"%s spawned a %s",ply:Name(),class)
		return true
	else
		return false
	end
end

-- Called when a player is given a SWEP.
function GM:PlayerGiveSWEP(ply, class, weapon)
	if ply:IsSuperAdmin() then
		GM:Log(EVENT_SUPEREVENT,"%s gave themselves a %s",ply:Name(),class)
		return true
	else
		return false
	end
end

-- Called when attempts to spawn a SENT.
function GM:PlayerSpawnSENT(ply, class)
	if ply:IsSuperAdmin() then
		GM:Log(EVENT_SUPEREVENT,"%s spawned a %s",ply:Name(),class)
		return true
	else
		return false
	end
end



local timenow = CurTime()
timer.Create("Timer Checker.t",1,0,function()
	timenow = CurTime()
end)
hook.Add("Think","Timer Checker.h",function()
	if timenow < CurTime() - 3 then
		GM:Log(EVENT_ERROR,"Timers have stopped running!")
		player.NotifyAll("Timers have stopped running! Oh shi-",1)
		hook.Remove("Think","Timer Checker.h")
	end
end)

-- Create a timer to automatically clean up decals.
timer.Create("Cleanup Decals", 60, 0, function()
	if ( GM.Config["Cleanup Decals"] ) then
		for k, v in pairs( player.GetAll() ) do v:ConCommand("r_cleardecals\n") end
	end
end)


-- Create a timer to give players money for their contraband.
timer.Create("Earning", GM.Config["Earning Interval"], 0, function()
	local contratypes = {}
	for key in pairs(GM.Config["Contraband"]) do
		contratypes[key] = true
	end
	local cplayers = {}
	local dplayers = {}


	for _, ent in ipairs(ents.GetAll()) do
		if contratypes[ent:GetClass()] then
			local ply = ent:GetPlayer();
			-- Check if the ply is a valid entity,
			if ( ValidEntity(ply) ) then
				cplayers[ply] = cplayers[ply] or {refill = 0, money = 0}

				-- Decrease the energy of the contraband.
				ent.dt.energy = math.Clamp(ent.dt.energy - 1, 0, 5)

				-- Check the energy of the contraband.
				if (ent.dt.energy == 0) then
					cplayers[ply].refill = cplayers[ply].refill + 1
				else
					cplayers[ply].money = cplayers[ply].money + GM.Config["Contraband"][ ent:GetClass() ].money
				end
			end
		elseif cider.entity.isDoor(ent) and cider.entity.isOwned(ent) then
			local o = cider.entity.getOwner(ent)
			if type(o) == "Player" and ValidEntity(o) then
				dplayers[o] = dplayers[o] or { 0, {} }
				-- Increase the amount of tax this player must pay.
				dplayers[o][1] = dplayers[o][1] + GM.Config["Door Tax Amount"]
				-- Insert the door into the player's door table.
				table.insert(dplayers[o][2], ent)
			end
		end
	end
	-- Loop through our players list.
	for k, v in pairs(cplayers) do
		if ( IsValid(k) and k:IsPlayer() and hook.Call("PlayerCanEarnContraband",GAMEMODE, k) ) then
			if (v.refill > 0) then
				k:Notify(v.refill.." of your contraband need refilling!", 1)
			end
			if (v.money > 0) then
				k:Notify("You earned $"..v.money.." from contraband.", 0)

				-- Give the player their money.
				k:GiveMoney(v.money)
			end
		end
	end
	for _,ply in ipairs(player.GetAll()) do
		if (ply:Alive() and !ply.cider._Arrested) then
			ply:GiveMoney(ply._Salary)

			-- Print a message to the player letting them know they received their salary.
			ply:Notify("You received $"..ply._Salary.." salary.", 0)
		end
	end
	if ( GM.Config["Door Tax"] ) then
		-- Loop through our players list.
		for k, v in pairs(dplayers) do
			if ( k:CanAfford(v[1] ) ) then
				k:Notify("You have been taxed $"..v[1].." for your doors.", 0)
			else
				k:Notify("You can't pay your taxes. Your doors were removed.", 1)

				-- Loop through the doors.
				for k2, v2 in pairs( v[2] ) do
					if v2._Removeable then
						v2:Remove()
					else
						k:TakeDoor(v2, true)
					end
				end
			end

			-- Take the money from the player.
			k:GiveMoney(-v[1] )
		end
	end
	player.SaveAll()
end)
concommand.Add( "wire_keyboard_press", function(p,c,a) return end )

local servertags = GetConVarString("sv_tags")
if servertags == nil then
	servertags = ""
end
for _,tag in ipairs(GM.Config["sv_tags"]) do
	if not string.find(servertags, tag, 1, true) then
		servertags = servertags..","..tag
	end
end
RunConsoleCommand("sv_tags", servertags )
*/
