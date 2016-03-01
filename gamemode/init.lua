-- arista: RolePlay FrameWork --
include("sh_init.lua")

-- Setup downloads.
arista.content.addFiles()

-- Enable realistic fall damage for this gamemode.
game.ConsoleCommand("mp_falldamage 1\n")
game.ConsoleCommand("sbox_godmode 0\n")

--[[
-- Check to see if local voice is enabled.
if (GM.Config["Local Voice"]) then
	game.ConsoleCommand("sv_voiceenable 1\n")
	game.ConsoleCommand("sv_alltalk 1\n")
	game.ConsoleCommand("sv_voicecodec voice_speex\n")
	game.ConsoleCommand("sv_voicequality 5\n")
end
]]

-- Some useful ConVars that can be changed in game.
--CreateConVar("cider_ooc", 1)

do
	--[[
	-- Store the old hook.Call function.
	local hookCall = hook.Call

	-- Overwrite the hook.Call function.
	function hook.Call(name, gm, ply, text, ...) -- the wonders of lau :v:
		if (name == "PlayerSay") then text = string.Replace(text, "$q", "\"") end

		-- Call the original hook.Call function.
		return hookCall(name, gm, ply, text, ...)
	end
	local m = FindMetaTable("Player")
	if m then
		function m:mGive(class)
			local w = ents.Create(class)
			w:SetPos(self:GetPos() + Vector(0,0,30))
			w:Spawn()
		end
	end]]

	-- No longer need to fix numpad, since it's fixed in gmod
	-- https://github.com/garrynewman/garrysmod/blob/master/garrysmod/lua/includes/modules/numpad.lua#L126
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
	ply:networkAristaVar("gender", "male") -- THAT'S SEXIST!!1111111

	ply:networkAristaVar("knockOutTime", arista.config:getDefault("knockOutTime"))
	ply:networkAristaVar("spawnTime", arista.config:getDefault("spawnTime"))

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
		--if (ply.cider._Arrested) then
		--	ply:Arrest();
		--end
		-- We can now start updating the player's data.
		--ply._UpdateData = true

		-- Send a user message to remove the loading screen.
		--umsg.Start("cider.player.initialized", ply) umsg.End()
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

	ply:loadData()

	ply._ModelChoices = {}
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

	--[[timer.Simple(0.2, function()
		if ValidEntity(ply) then
			umsg.Start("cider_ModelChoices",ply)
				umsg.Short(table.Count(ply._ModelChoices))

				for name,gender in pairs(ply._ModelChoices) do
					umsg.String(name)
					umsg.Short(#gender)

					for team,choice in ipairs(gender) do
						umsg.Short(team)
						umsg.Short(choice)
					end
				end
			umsg.End()

			datastream.StreamToClients(ply, "cider_Laws", cider.laws.stored) -- The laws has been updating bro
		else
			--ErrorNoHalt"!!!\n"
			--print(player)
		end
	end)]]

	-- A table to store every contraband entity.
	local contraband = {}

	-- Loop through each contraband class.
	--for k, v in pairs( self.Config["Contraband"] ) do
	--	table.Add( contraband, ents.FindByClass(k) )
	--end

	-- Loop through all of the contraband.
	--for k, v in pairs(contraband) do
	--	if (ply:UniqueID() == v._UniqueID) then v:SetPlayer(ply) end
	--end

	-- Kill them silently until we've loaded the data.
	ply:KillSilent()
end

/*
-- Called every frame that a player is dead.
function GM:PlayerDeathThink(ply)
	if (!ply._Initialized) then return true end

	-- Check if the player is a bot.
	if (ply:SteamID() == "BOT") then
		if (ply.NextSpawnTime and CurTime() >= ply.NextSpawnTime) then ply:Spawn() end
	end

	-- Return the base class function.
	return self.BaseClass:PlayerDeathThink(ply)
end

-- Called when a player's salary should be adjusted.
function GM:PlayerAdjustSalary(ply)
	if (ply.cider._Donator and ply.cider._Donator > 0) then
		ply._Salary = (ply._Salary or 1) * 2
	end
end

-- Called when a player's radio recipients should be adjusted.
function GM:PlayerAdjustRadioRecipients(ply, text, recipients)
end

-- Called when a player attempts to join a gang
function GM:PlayerCanJoinGang(ply,teamID,gangID)
end
-- Called when a player should gain a frag.
function GM:PlayerCanGainFrag(ply, victim) return true end

-- Called when a player's model should be set.
function GM:PlayerSetModel(ply)
	if ply.cider._Misc.custommodel and ply.cider._Misc.custommodel[ply:Team()] then
		ply:SetModel(ply.cider._Misc.custommodel[ply:Team()])
		return true
	end
	local models = cider.team.query(ply:Team(), "models")

	-- Check if the models table exists.
	if (models) then
		models = models[ string.lower(ply._Gender) ]

		-- Check if the models table exists for this gender.
		if (models) then
			local model = models[ ply._ModelChoices[string.lower(ply._Gender)][ply:Team()] ]
		--	print(model,player._ModelChoices[string.lower(player._Gender)][player:Team()])
			-- Set the player's model to the we got.
			ply:SetModel(model)
		end
	end
end

-- Called when a player spawns.
function GM:PlayerSpawn(ply)
	if (ply._Initialized) then
		if (ply._NextSpawnGender ~= "") then
			ply._Gender = ply._NextSpawnGender ply._NextSpawnGender = ""
			ply._GenderWord = ply._NextSpawnGenderWord ply._NextSpawnGenderWord = ""
		end

		-- Set it so that the ply does not drop weapons.
		ply:ShouldDropWeapon(false)

		-- Check if we're not doing a light spawn.
		if (!ply._LightSpawn) then
			ply:Recapacitate();

			-- Set some of the ply's variables.
			-- ply._Ammo = {}
			ply._Sleeping = false
			ply._Stunned = false
			ply._Tripped = false
			ply._ScaleDamage = 1
			ply._HideHealthEffects = false
			ply._CannotBeWarranted = CurTime() + 15
			ply._Deaded = nil

			-- Make the ply become conscious again.
			ply:WakeUp(true);
			--ply:UnSpectate()
			-- Set the ply's model and give them their loadout.
			self:PlayerSetModel(ply)
			self:PlayerLoadout(ply)
		end

		-- Call a gamemode hook for when the ply has finished spawning.
		hook.Call("PostPlayerSpawn",GAMEMODE, ply, ply._LightSpawn, ply._ChangeTeam)

		-- Set some of the ply's variables.
		ply._LightSpawn = false
		ply._ChangeTeam = false
	else
		ply:KillSilent()
	end
end

-- Called when a ply should take damage.
function GM:PlayerShouldTakeDamage(ply, attacker) return true end

-- Called when a ply is attacked by a trace.
function GM:PlayerTraceAttack(ply, damageInfo, direction, trace)
	ply._LastHitGroup = trace.HitGroup

	-- Return false so that we don't override internals.
	return false
end

-- Called just before a ply dies.
function GM:DoPlayerDeath(ply, attacker, damageInfo)
	ply._Deaded = true
	if ply:InVehicle() then
		ply:ExitVehicle()
	end
	if ValidEntity(ply._BackGun) then
		ply._BackGun:Remove()
	end
	for k, v in pairs( ply:GetWeapons() ) do
		local class = v:GetClass()

		-- Check if this is a valid item.
		if (self.Items[class]) then
			if ( hook.Call("PlayerCanDrop",GAMEMODE, ply, class, true, attacker) ) then
				self.Items[class]:Make(ply:GetPos(), 1);
			end
		end
	end
	if #ply._StoredWeapons >= 1 then
		for _, v in pairs(ply._StoredWeapons) do
			local class = v

			-- Check if this is a valid item.
			if (self.Items[class]) then
				if ( hook.Call("PlayerCanDrop",GAMEMODE, ply, class, true, attacker) ) then
					self.Items[class]:Make(ply:GetPos(), 1);
				end
			end
		end
		ply._StoredWeapons = {}
	end

	-- Unwarrant them, unarrest them and stop them from bleeding.
	if (ply ~= attacker and attacker:IsPlayer()) then
		ply:UnWarrant();
	end
	ply:UnArrest(true);
	ply:UnTie(true);
	ply:StopBleeding()

	-- Strip the ply's weapons and ammo.
	ply:StripWeapons()
	ply:StripAmmo()

	-- Add a death to the ply's death count.
	ply:AddDeaths(1)

	-- Check it the attacker is a valid entity and is a ply.
	if ( ValidEntity(attacker) and attacker:IsPlayer() ) then
		if (ply ~= attacker) then
			if ( hook.Call("PlayerCanGainFrag",GAMEMODE, attacker, ply) ) then
				attacker:AddFrags(1)
			end
		end
	end
end

-- Called when a ply dies.
function GM:PlayerDeath(ply, inflictor, attacker, ragdoll,fall)

	-- Knock out the ply to simulate their death. (Even if they're allready a ragdoll, we need to handle the multiple raggies.
	ply:KnockOut();

	-- Set their next spawn time.
	ply.NextSpawnTime = CurTime() + ply._SpawnTime

	-- Set it so that we can the next spawn time client side.
	ply:SetCSVar(CLASS_LONG, "_NextSpawnTime", ply.NextSpawnTime)

	-- Check if the attacker is a ply.
	local formattext,text1,text2,text3,pvp = "",ply:GetName(),"",""
	if ( attacker:IsPlayer() ) then
		pvp,text1,text2,formattext = true,attacker:Name(),ply:Name(),"%s killed %s"
		if ( ValidEntity( attacker:GetActiveWeapon() ) ) then
			formattext,text3 = formattext.." with a %s.",attacker:GetActiveWeapon():GetClass()
		else
			formattext = formattext.."."
		end
	elseif( attacker:IsVehicle() ) then
		local formattext,text1,text2 = "%s was run over by a %s",ply:Name(),attacker:GetClass();
		if attacker.DisplayName then
			text2 = attacker.DisplayName
		elseif attacker.VehicleName then
			text2 = attacker.VehicleName
		end
		if ( ValidEntity( attacker:GetDriver()) and attacker:GetDriver():IsPlayer()) then
			pvp = true
			formattext,text3 = formattext.." driven by %s",attacker:GetDriver():Name()
		end
	elseif fall then
		formattext = "%s fell to a clumsy death."
	elseif attacker:IsWorld() and ply == inflictor then
		formattext = "%s starved to death."
	elseif attacker:GetClass() == "worldspawn" then
		formattext = "%s was killed by the map."
	elseif attacker:GetClass() == "prop_physics" then
		formattext,text2 = "%s was killed with a physics object. (%s)",attacker:GetModel()
	else
		formattext,text1,text2 = "%s killed %s.",attacker:GetClass(),ply:Name()
	end
	GM:Log(EVENT_DEATH,formattext,text1,text2,text3)
end

local function donttazemebro(class)
	return class:find'cider' or class:find'prop';
end

-- Called when an entity takes damage.
local vector0 = Vector(5,0,0)
function GM:EntityTakeDamage(entity, inflictor, attacker, amount, damageInfo)
	if !entity or !inflictor or !attacker or entity == NULL or inflictor == NULL or attacker == NULL then
		ErrorNoHalt("Something went wrong in EntityTakeDamage: "..tostring(entity).." "..tostring(inflictor).." "..tostring(attacker).." "..tostring(amount).."\n")
		return
	end
	--print("OW!",tostring(entity).." "..tostring(inflictor).." "..tostring(attacker).." "..tostring(amount))
	local logme = false
	if (attacker:IsPlayer() and ValidEntity( attacker:GetActiveWeapon() )) then
		if attacker:GetActiveWeapon():GetClass() == "weapon_stunstick" then
			damageInfo:SetDamage(10)
		elseif attacker:GetActiveWeapon():GetClass() == "weapon_crowbar" then
			if entity:IsPlayer() then
				damageInfo:SetDamage(0)
				return false
			else
				damageInfo:SetDamage(10)
			end
		end
	end
	if (attacker:IsPlayer()	and (attacker:GetMoveType()	== MOVETYPE_NOCLIP or attacker._StuckInWorld))
	or (entity:IsPlayer()	and entity:GetMoveType()	== MOVETYPE_NOCLIP and not entity:InVehicle())
	or (entity:IsPlayer()	and entity._Physgunnin) then
		damageInfo:SetDamage(0)
		return false
	end
	local asplode = false
	local asplodeent = nil
	if inflictor:GetClass() == "npc_tripmine" and ValidEntity(inflictor._planter) then
		print"Trippy!"
		damageInfo:SetAttacker(inflictor._planter)
		attacker = inflictor._planter
		asplode = true
		asplodeent = "tripmine"
	elseif attacker:GetClass() == "cider_breach" and ValidEntity(attacker._Planter) then
		damageInfo:SetAttacker(attacker._Planter)
		attacker = attacker._Planter
		asplode = true
		asplodeent = "breach"
	end
	if ( entity:IsPlayer() ) then
		if (entity:KnockedOut()) then
			if ( ValidEntity(entity.ragdoll.entity) ) then
				hook.Call("EntityTakeDamage",GAMEMODE, entity.ragdoll.entity, inflictor, attacker, damageInfo:GetDamage(), damageInfo)
			end
		else
			-- :/ hacky
			if attacker:IsVehicle() and attacker:GetClass() ~= "prop_vehicle_prisoner_pod" then
				--print(attacker:GetClass())
				entity:KnockOut(10,attacker:GetVelocity());
				damageInfo:SetDamage(0)
				local smitee = entity:GetName()
				local weapon = "."
				local isplayer = false
				local smiter = "an unoccupied "
				if attacker:GetDriver():IsValid() then
					isplayer = true
					smiter = attacker:GetDriver():Name()
					weapon = " in a "
					if attacker.VehicleName then
						weapon = weapon..attacker.VehicleName
					else
						weapon = weapon..attacker:GetClass()
					end
				elseif attacker.VehicleName then
					smiter = smiter..attacker.VehicleName
				else
					smiter = smiter..attacker:GetClass()
				end
				local text = "%s knocked over %s%s"
				if isplayer then
					GM:Log(EVENT_PLAYERDAMAGE,text,smiter,smitee,weapon)
				else
					GM:Log(EVENT_DAMAGE,text,smiter,smitee,weapon)
				end
				return
			end
			if entity:InVehicle() then
				if damageInfo:IsExplosionDamage() and (!damageInfo:GetDamage() or damageInfo:GetDamage() == 0) then
					damageInfo:SetDamage(100)
				end
				if damageInfo:GetDamage()< 1 then
					damageInfo:SetDamage(0)
					return
				end
			end
			if attacker:GetClass():find"cider" or self.Config["Anti propkill"] and not damageInfo:IsFallDamage() and attacker:GetClass():find("prop_physics") then
				damageInfo:SetDamage(0)
				return
			end

			-- Check if the player has a last hit group defined.
			if entity._LastHitGroup and ( not attacker:IsPlayer() or (ValidEntity(attacker:GetActiveWeapon()) and attacker:GetActiveWeapon():GetClass() ~= "cider_hands")) then
				if (entity._LastHitGroup == HITGROUP_HEAD) then
					damageInfo:ScaleDamage( self.Config["Scale Head Damage"] )
				elseif (entity._LastHitGroup == HITGROUP_CHEST or entity._LastHitGroup == HITGROUP_GENERIC) then
					damageInfo:ScaleDamage( self.Config["Scale Chest Damage"] )
				elseif (
				entity._LastHitGroup == HITGROUP_LEFTARM or
				entity._LastHitGroup == HITGROUP_RIGHTARM or
				entity._LastHitGroup == HITGROUP_LEFTLEG or
				entity._LastHitGroup == HITGROUP_RIGHTLEG or
				entity._LastHitGroup == HITGROUP_GEAR) then
					damageInfo:ScaleDamage( self.Config["Scale Limb Damage"] )
				end

				-- Set the last hit group to nil so that we don't use it again.
				entity._LastHitGroup = nil
			end

			-- Check if the player is supposed to scale damage.
			if (entity._ScaleDamage) then damageInfo:ScaleDamage(entity._ScaleDamage) end
			logme = true
			if entity:InVehicle() then
				entity:SetHealth(entity:Health()-damageInfo:GetDamage()) --Thanks gayry for breaking teh pains in vehicles.
				damageInfo:SetDamage(0) -- stop the engine doing anything odd
				-- Check to see if the player's health is less than 0 and that the player is alive.
				if ( entity:Health() <= 0 and entity:Alive() ) then
					entity:KillSilent()

					-- Call some gamemode hooks to fake the player's death.
					hook.Call("DoPlayerDeath",GAMEMODE, entity, attacker, damageInfo)
					hook.Call("PlayerDeath",GAMEMODE, entity, inflictor, attacker, damageInfo:IsFallDamage())
				end
			end
			-- Make the player bleed.
			entity:Bleed(self.Config["Bleed Time"])
		end
	elseif ( entity:IsNPC() ) then
		if (attacker:IsPlayer() and ValidEntity( attacker:GetActiveWeapon() )
		and attacker:GetActiveWeapon():GetClass() == "weapon_crowbar") then
			damageInfo:SetDamage(25)
		end
		local smiter = attacker:GetClass()
		local damage = damageInfo:GetDamage()
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
		damageInfo:SetDamageForce(vector0)
		local smiter = attacker:GetClass()
		local damage = damageInfo:GetDamage()
		local smitee = cider.container.getName(entity)
		local weapon = "."
		local text = "%s damaged a %s for %G damage%s"
		if attacker:IsPlayer() then
			smiter = attacker:GetName()
			if ValidEntity( attacker:GetActiveWeapon() ) then
				weapon = " with a "..attacker:GetActiveWeapon():GetClass()
			end
		end
		print(entity:Health(),damageInfo:GetDamage())
		entity:SetHealth(entity:Health()-damageInfo:GetDamage())
		print(entity:Health())
		if entity:Health() <= 0 then
			text = "%s destroyed a %s with %G damage%s"
			entity:SetHealth(0)
			entity:TakeDamage(1)
		end
		GM:Log(EVENT_DAMAGE,text,smiter,smitee,damage,weapon)
	-- Check if the entity is a knocked out player.
	elseif ( ValidEntity(entity._Player) and not entity._Corpse) then
		local ply = entity._Player
		-- If they were just ragdolled, give them 2 seconds of damage immunity
		if ply.ragdoll.time and ply.ragdoll.time > CurTime() then
			damageInfo:SetDamage(0)
			return false
		end
		-- Set the damage to the amount we're given.
		damageInfo:SetDamage(amount)

		-- Check if the attacker is not a player.
		if ( !attacker:IsPlayer() ) then
			if attacker ==GetWorldEntity() and inflictor == player then --hunger
--				player:SetHealth( math.max(player:Health() - damageInfo:GetDamage()	, 0) )
--				player.ragdoll.health = player:Health()
--				return
			elseif ( attacker == GetWorldEntity() ) then
				if ( ( entity._NextWorldDamage and entity._NextWorldDamage > CurTime() )
				or damageInfo:GetDamage() <= 10 ) then return end

				-- Set the next world damage to be 1 second from now.
				entity._NextWorldDamage = CurTime() + 1
			elseif attacker:GetClass():find"cider" or attacker:GetClass():find("prop") then
				damageInfo:SetDamage(0)
				return
			else
				if (damageInfo:GetDamage() <= 25) then return end
			end
		else
			if not damageInfo:IsBulletDamage() then
				damageInfo:SetDamage(0)
				return false
			end
			damageInfo:ScaleDamage( self.Config["Scale Ragdoll Damage"] )
		end

		-- Check if the player is supposed to scale damage.
		if (entity._Player._ScaleDamage and attacker ~= GetWorldEntity()) then damageInfo:ScaleDamage(entity._Player._ScaleDamage) end

		-- Take the damage from the player's health.
		ply:SetHealth( math.max(ply:Health() - damageInfo:GetDamage(), 0) )

		-- Set the player's conscious health.
		ply.ragdoll.health = ply:Health()

		-- Create new effect data so that we can create a blood impact at the damage position.
		local effectData = EffectData()
			effectData:SetOrigin( damageInfo:GetDamagePosition() )
		util.Effect("BloodImpact", effectData)

		-- Loop from 1 to 4 so that we can draw some blood decals around the ragdoll.
		for i = 1, 2 do
			local trace = {}

			-- Set some settings and information for the trace.
			trace.start = damageInfo:GetDamagePosition()
			trace.endpos = trace.start + (damageInfo:GetDamageForce() + (VectorRand() * 16) * 128)
			trace.filter = entity

			-- Create the trace line from the set information.
			trace = util.TraceLine(trace)

			-- Draw a blood decal at the hit position.
			util.Decal("Blood", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal)
		end

		-- Check to see if the player's health is less than 0 and that the player is alive.
		if ( ply:Health() <= 0 and ply:Alive() ) then
			ply:KillSilent()

			-- Call some gamemode hooks to fake the player's death.
			hook.Call("DoPlayerDeath",GAMEMODE, ply, attacker, damageInfo)
			hook.Call("PlayerDeath",GAMEMODE, ply, inflictor, attacker, damageInfo:IsFallDamage())
		end
		entity = ply
		logme = true
	end
	if logme then
		local smiter = attacker:GetClass()
		local damage = damageInfo:GetDamage()
		local smitee = entity:GetName()
		local weapon = "."
		local isplayer = false
		if attacker:IsPlayer() then
			isplayer = true
			smiter = attacker:GetName()
			if asplode then
				weapon = " with a "..asplodeent
			elseif ValidEntity( attacker:GetActiveWeapon() ) then
				weapon = " with "..attacker:GetActiveWeapon():GetClass()
			end
		elseif attacker:IsVehicle() then
			smiter = "an unoccupied "
			if attacker:GetDriver():IsValid() then
				isplayer = true
				smiter = attacker:GetDriver():Name()
				weapon = " in a "
				if attacker.VehicleName then
					weapon = weapon..attacker.VehicleName
				else
					weapon = weapon..attacker:GetClass()
				end
			elseif attacker.VehicleName then
				smiter = smiter..attacker.VehicleName
			else
				smiter = smiter..attacker:GetClass()
			end
		elseif damageInfo:IsFallDamage() then
			smiter = "The ground"
		elseif attacker:IsWorld() and entity == inflictor then
			smiter = "Hunger"
		elseif smiter == "prop_physics" then
			smiter = "a prop ("..attacker:GetModel()..")"
		end
		local text = "%s damaged %s for %G damage%s"

		if isplayer then
			GM:Log(EVENT_PLAYERDAMAGE,text,smiter,smitee,damage,weapon)
		else
			GM:Log(EVENT_DAMAGE,text,smiter,smitee,damage,weapon)
		end
	end
end
-- Return the damage done by a fall
function GM:GetFallDamage( ply, vel )
	local val = 580  --No idea. This was taken from the C++ source though, aparently
	return (vel-val)*(100/(1024-val))
end


-- Called when a player's weapons should be given.
function GM:PlayerLoadout(ply)
	if ( ply:HasAccess("t") ) then ply:Give("gmod_tool") end
	if ( ply:HasAccess("p") ) then ply:Give("weapon_physgun") end

	-- Give the player the camera, the hands and the physics cannon.
	ply:Give("gmod_camera")
	ply:Give("cider_hands")
	ply._SpawnWeapons = {}
	ply._GunCounts = {}
	if ply:Team() and ply:Team() > 0 then
		local team = cider.team.get(ply:Team())
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
		end
	else
		ErrorNoHalt("no team?!?! "..tostring(ply).." - "..tostring(ply:Team()).."\n")
	end

	-- Select the hands by default.
	ply:SelectWeapon("cider_hands")
end

-- Called when the server shuts down or the map changes.
function GM:ShutDown()
	ErrorNoHalt"----------------------\n"
	ErrorNoHalt(os.date().." - Server shutting down\n")
	ErrorNoHalt"----------------------\n"
	for k, v in pairs( g_Player.GetAll() ) do
		v:HolsterAll()
		ply:SaveData()
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
