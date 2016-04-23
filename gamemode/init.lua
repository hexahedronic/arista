-- arista: RolePlay FrameWork --
include("sh_init.lua")

-- Setup downloads.
arista.content.addFiles()

-- Load admin commands.
include("sv_commands.lua")

-- Enable realistic fall damage for this gamemode.
game.ConsoleCommand("mp_falldamage 1\n")
game.ConsoleCommand("sbox_godmode 0\n")

-- Check to see if local voice is enabled.
if arista.config.vars.localVoice then
	game.ConsoleCommand("sv_voiceenable 1\n")
	game.ConsoleCommand("sv_alltalk 1\n")
	--game.ConsoleCommand("sv_voicecodec voice_speex\n")
	--game.ConsoleCommand("sv_voicequality 5\n")
end

-- Net Messages, seems like a lot since they also replace umsgs (umsg is deprecated)
do
	util.AddNetworkString("arista_sendMapEntities")

	util.AddNetworkString("arista_playerInitialized")

	util.AddNetworkString("arista_modelChoices")

	util.AddNetworkString("arista_laws")
	util.AddNetworkString("arista_lawsUpdate")

	util.AddNetworkString("arista_notify")

	util.AddNetworkString("arista_wipeAccess")
	util.AddNetworkString("arista_incomingAccess")
	util.AddNetworkString("arista_access")
	util.AddNetworkString("arista_accessUpdate")

	util.AddNetworkString("arista_menu")

	util.AddNetworkString("arista_buyDoor")

	util.AddNetworkString("arista_moneyAlert")

	util.AddNetworkString("arista_teamChange")

	util.AddNetworkString("arista_inventoryItem")

	util.AddNetworkString("arista_container")
	util.AddNetworkString("arista_containerUpdate")
	util.AddNetworkString("arista_closeContainerMenu")

	util.AddNetworkString("arista_chatboxMessage")
	util.AddNetworkString("arista_chatboxPlayerMessage")

	util.AddNetworkString("arista_helpReplace")
end

-- Flags that represent functions.
arista.flagFunctions = {
	s = function(ply) return ply:IsSuperAdmin() end,
	a = function(ply) return ply:IsAdmin() end,
	m = function(ply) return --[[ply:IsModerator()]] ply:IsAdmin() end,
}
-- todo: mod

--[[
Available access flags:
s = superAdmin	- Is a SuperAdmin
a = admin				- Is an admin
m = moderator		- Is a moderator

e = entity			- Can spawn props, for free
E = builder			- Can spawn props for a price

w = wire				- Can use wiremod
p = physics			- Spawns with physicsgun.
t = tool				- Spawns with toolgun.

b = boss				- Can demote members of the same level. Restricted to a gang if used on a gang member
d = demote			- Members of lower level. Restricted to a gang if used on a gang member
g = give				- Can give/take ents to/from gang

D = depose			- Underlings can vote to depose
M = main				- All group-to-group transitions must go through this
]]

-- Called when the server initializes.
function GM:Initialize()
	ErrorNoHalt("----------------------\n")
	ErrorNoHalt(os.date() .. " - Server starting up\n")
	ErrorNoHalt("----------------------\n")

	-- Initialize a connection to the MySQL database.
	arista.database.initialize()

	-- Call the base class function.
	return self.BaseClass:Initialize()
end

-- Called when all of the map entities have been initialized.
function GM:InitPostEntity()
	for i, entity in ipairs(ents.GetAll()) do
		if arista.entity.isDoor(entity) then
			arista.entity.makeOwnable(entity)
		end

		arista._internaldata.entities[entity] = entity
	end

	arista.utils.nextFrame(gamemode.Call, "LoadData") -- Tell plugins to load their datas a frame after this.
	arista._internaldata.initSuccess = true

	-- Call the base class function.
	return self.BaseClass:InitPostEntity()
end

-- Called to check if a player can use voice.
local radius = arista.config.vars.talkRadius ^ 2

function GM:PlayerCanHearPlayersVoice(listener, player)
	if not arista.config.vars.localVoice then return true end

	if not (player:IsValid() and listener:IsValid()) then return end

	local distToSqr = player:GetPos():DistToSqr(listener:GetPos())

	-- Can hear if alive, close to us, and conscious.
	if player:Alive() and distToSqr <= radius and not player:isUnconscious() then
		return true
	end

	-- Cant hear.
	return false
end

-- Called when a player attempts to arrest another player.
function GM:PlayerCanArrest(ply, target)
	if target:hasWarrant() == "arrest" then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.ARREST, ply, " arrested ", target, ".")

		return true
	end

	arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.ARREST, ply, " tried (and failed) to arrest ", target, ".")
	ply:notify("AL_PLAYER_NO_WARRANT", target:Name())
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

	if res ~= false and ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned an npc (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn an npc (", model, ").")

		return false
	end
end

function GM:PropSpawned(model, ent)
	local data = arista.config.vars.containerModels[model:lower()]
	if not data then return false end

	arista.container.make(ent, data[1], data[2])
end

function GM:PlayerSpawnedProp(ply, model, ent)
	local res = gamemode.Call("PropSpawned", model, ent)

	if res then
		arista.entity.makeOwnable(ent)
		arista.entity.setOwnerPlayer(ent, ply)
	end

	return self.BaseClass:PlayerSpawnedProp(ply, model, ent)
end

-- Called when a player attempts to spawn a prop.
function GM:PlayerSpawnProp(ply, model)
	if not ply:hasAccess("meE", true) then return false end

	local res = gamemode.Call("PlayerCanDoSomething", ply, nil, true)

	-- Check if the player can spawn this prop.
	if res == false then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ").")

		return false
	elseif ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a prop (", model, ").")

		return true
	end

	-- Escape the bad characters from the model.
	model = model:gsub("%.%.", "")
	model = model:gsub("\\",  "/")
	model = model:gsub("//",  "/")

	-- Loop through our banned props to see if this one is banned.
	if CPPI:GetName() == "arista CPPI Fallback" or arista.config.vars.forceBlockedModels then
		for k, v in ipairs(arista.config.vars.blockedModels) do
			if v:lower() == model:lower() then
				arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a (banned) prop (", model, ").")
				ply:notify("AL_YOU_PROP_BANNED")

				-- Return false because we cannot spawn it.
				return false
			end
		end
	end

	-- Check if model is some junk that shouldn't spawn.
	if not arista.utils.validModel(model) then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a (invalid) prop (", model, ").")
		ply:notify("AL_INVALID_MODEL")

		return false
	elseif false then--ply:GetCount("props") > self.Config["Prop Limit"] then -- getcount likes to die, maybe replace?
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (over limit).")
		ply:notify("AL_YOU_PROP_LIMIT")

		return false
	end

	local radius

	local ent = ents.Create("prop_physics")
		ent:SetModel(model)

	if ent:GetModel() == "models/error.mdl" then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (error?).")

		return false
	end

		radius = ent:BoundingRadius()
	ent:Remove()

	-- gc me please.
	ent = nil

	if (radius > 100 and not ply:hasAccess("e")) --Only donators go above 100
	or (radius > 200 and not ply:hasAccess("m")) --Only mods go above 200
	or (radius > 300 and not ply:hasAccess("a")) then --Only admins go above 300.
		ply:notify("AL_YOU_PROP_TOOBIG")

		return false
	end

	-- Check if they can spawn this prop yet.
	local nextSpawn = ply:getAristaVar("nextSpawnProp")
	local propCosts = arista.config.costs.prop

	if nextSpawn and nextSpawn > CurTime() then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a prop (", model, ") (too fast).")
		ply:notify("AL_YOU_PROP_TOOFAST", math.ceil(nextSpawn - CurTime()))

		-- Return false because we cannot spawn it.
		return false
	elseif ply:hasAccess("E") and not ply:hasAccess("e") and propCosts > 0 then
		if ply:canAfford(propCosts) then
			if ply:GetCount("props") <= arista.config.vars.builderPropLimit then
				ply:giveMoney(-propCosts)
			else
				ply:LimitHit("props")

				return false
			end
		else
			local amount = propCosts - ply:GetMoney()

			-- Print a message to the player telling them how much they need.
			ply:notify("AL_NEED_ANOTHER_MONEY", amount)

			return false
		end

		ply:setAristaVar("nextSpawnProp", CurTime() + 15)
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
	if ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ragdoll (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ragdoll (", model, ").")

		return false
	end
end

-- Called when a player attempts to spawn an effect.
function GM:PlayerSpawnEffect(ply, model)
	if ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a effect (", model, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a effect (", model, ").")

		return false
	end
end

function GM:PlayerCanDoSomething(ply, ignorealive, spawning)
	if not (ply:Alive() or ignorealive) or ply:interactionDisallowed() then
			ply:notify("AL_CANNOT_INVALID")

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
	elseif ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ", name, "(", model, ").")

		return true
	end

	-- Check if the model is a chair.
	-- todo: check for vehicles module / store module
	if not arista.utils.isModelChair(model) then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ", name, " (", model, ") (Non-chair).")
		ply:notify("AL_CANNOT_SPAWN_CAR")

		return false
	end

	if not ply:hasAccess("e") then return false end

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

	for k, v in ipairs(player.GetAll()) do
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

	if name == "^" then
		ply:Kick("Nice try, but this doesn't use ulx. Change name.")
	elseif not name:find("[A-Za-z1-9][A-Za-z1-9][A-Za-z1-9][A-Za-z1-9]") then
		ply:Kick("A minimum of 4 alphanumeric characters is required in your name to play here.")
	elseif name:find(";") then
		ply:Kick("Please take the semi-colon out of your name.")
	elseif name:find('"') then
		ply:Kick('Please take the " out of your name.')
	elseif name:StartWith("#") then
		ply:Kick("Remove the hash infront of your name.")
	end

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
			ply:setupDonator(true)

			-- Check if we still have at least 1 day.
			if days > 0 then
				ply:notify("AL_YOU_DONATOR_EXPIRE_DAYS", days)
			else
				ply:notify("AL_YOU_DONATOR_EXPIRE_HOURS", hours, minutes, seconds)
			end
		else
			arista.player.expireDonator(ply)
		end
	end

	-- Make the player a Citizen to begin with.
	ply:joinTeam(TEAM_DEFAULT)

	-- Stop this happening again.
	ply._inited = true

	-- Restore access to any entity the player owned that is currently unowned
	arista.entity.restoreAccess(ply)

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") finished connecting.")
end

function GM:NW3PlayerActuallySpawned(ply)
	timer.Simple(1, function()
		for k, v in ipairs(player.GetAll()) do v:forceNetworkUpdate() end
	end)
end

-- Called when a player's data is loaded.
function GM:PlayerDataLoaded(ply, success)
	ply:networkAristaVar("job", arista.config:getDefault("job"))
	ply:networkAristaVar("salary", 0)
	ply:networkAristaVar("access", arista.config:getDefault("access"))

	ply:networkAristaVar("knockOutTime", arista.config:getDefault("knockOutTime"))
	ply:networkAristaVar("spawnTime", arista.config:getDefault("spawnTime"))
	ply:networkAristaVar("arrestTime", arista.config:getDefault("arrestTime"))

	ply:networkAristaVar("tied", false)
	ply:networkAristaVar("unconscious", false)
	ply:networkAristaVar("incapacitated", false)
	ply:networkAristaVar("stunned", false)
	ply:networkAristaVar("tripped", false)
	ply:networkAristaVar("sleeping", false)
	ply:networkAristaVar("exhausted", false)
	ply:networkAristaVar("hideHealthEffects", false)

	ply:networkAristaVar("warrant", "")
	ply:networkAristaVar("nextGender", "")

	ply:networkAristaVar("ragdoll", NULL)

	ply:networkAristaVar("nextSpawnTime", CurTime())
	ply:networkAristaVar("knockOutPeriod", 0)
	ply:networkAristaVar("unarrestTime", 0)
	ply:networkAristaVar("warrantExpireTime", 0)
	ply:networkAristaVar("scaleDamage", 0, true) -- Floating-point
	ply:networkAristaVar("jobTimeExpire", 0)
	ply:networkAristaVar("jobTimeLimit", 0)
	ply:networkAristaVar("goToSleepTime", 0)

	ply:setAristaVar("nextManufactureItem", 0)
	ply:setAristaVar("nextUseItem", 0)
	ply:setAristaVar("nextHolsterWeapon", 0)
	ply:setAristaVar("nextOOC", 0)
	ply:setAristaVar("nextDeploy", 0)

	ply:setAristaVar("nextChangeTeam", {})
	ply:setAristaVar("nextUse", {})
	ply:setAristaVar("gunCounts", {})
	ply:setAristaVar("storedWeapons", {})
	ply:setAristaVar("gunCounts", {})

	-- Incase we have changed default database info.
	if success then
		local changed = false

		for k, v in pairs(arista.config.database) do
			if ply:getAristaVar(k) == nil then
				arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' initalized as '", v, "' (was missing).")

				if istable(v) then ply:setAristaVar(k, v) else ply:networkAristaVar(k, v) end
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

		if ply:rpName() == "" then
			ply:generateDefaultRPName()
			arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") was missing their RP Name, giving them a new one.")
		end
	end)
end

-- Mainly for the purpose of wiping data, since we fix missing vars when data loaded.
function GM:PlayerAddedToDatabase(ply)
	-- Player is new, add them to database.
	for k, v in pairs(arista.config.database) do
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' initalized as '", v, "'.")

		if istable(v) then ply:setAristaVar(k, v) else ply:networkAristaVar(k, v) end
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
	for _, team in pairs(arista.team.stored) do
		for gender, models in pairs(team.models) do
			ply._modelChoices[gender] = ply._modelChoices[gender] or {}

			if #models ~= 1 then
				ply._modelChoices[gender][team.index] = math.random(1, #models)
			else
				ply._modelChoices[gender][team.index] = 1
			end
		end
	end

	timer.Simple(2, function()
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


		net.Start("arista_sendMapEntities")
			net.WriteUInt(table.Count(arista._internaldata.entities), 16)

			for k, v in ipairs(arista._internaldata.entities) do
				net.WriteEntity(v)
			end
		net.Send(ply)

		net.Start("arista_laws")
			net.WriteTable(arista.laws.stored)
		net.Send(ply)
	end)

	-- Kill them silently until we've loaded the data.
	ply:KillSilent()
end

-- Called every frame that a player is dead.
function GM:PlayerDeathThink(ply)
	if not ply._inited then return true end

	-- Return the base class function.
	return self.BaseClass:PlayerDeathThink(ply)
end

-- Called when a player's salary should be adjusted.
function GM:PlayerAdjustSalary(ply)
	if ply:isDonator() then
		local current = ply:getAristaVar("salary") or 1

		ply:setAristaVar("salary", current * arista.config.vars.donatorMult)
		ply._wasDonator = true
	elseif ply._wasDonator then
		local current = ply:getAristaVar("salary") or 1

		ply:setAristaVar("salary", current / arista.config.vars.donatorMult)
		ply._wasDonator = false
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

		local models = arista.team.query(ply:Team(), "models")

		if not ply._modelChoices then return end

		-- Check if the models table exists.
		if models then
			local gen = ply:getGender():lower()
			models = models[gen]

			-- Check if the models table exists for this gender.
			if models then
				local genModels = ply._modelChoices[gen] or {}
				if not genModels[team] then return end

				local model = models[genModels[team]]

				if not model then
					return fallback(ply)
				end

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
	ply:setAristaVar("hideHealthEffects", false)
	ply:setAristaVar("exhausted", false)
	ply:setAristaVar("exhaustedCooldown", false)
	ply:setAristaVar("scaleDamage", 1)
	ply:setAristaVar("sleeping", false)
	ply:setAristaVar("dead", false)
	ply:setAristaVar("tripped", false)
	ply:setAristaVar("stunned", false)
	ply:setAristaVar("cannotBeWarranted", CurTime() + 15)
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
			-- Set some of the ply's variables.
			gamemode.Call("PlayerReSpawn", ply)

			-- Reset player's speeds.
			ply:recapacitate()

			-- Make the ply become conscious again.
			ply:wakeUp(true)

			-- Set the ply's model and give them their loadout.
			self:PlayerSetModel(ply)
			self:PlayerLoadout(ply)
		end

		ply:SetupHands()

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

	for k, v in ipairs(ply:GetWeapons()) do
		local class = v:GetClass()

		-- Check if this is a valid item.
		if arista.item.items[class] then
			if gamemode.Call("PlayerCanDrop", ply, class, true, attacker) ~= false then
				arista.item.items[class]:make(ply:GetPos(), 1)
			end
		end
	end

	local storedWeapons = ply:getAristaVar("storedWeapons")
	if storedWeapons and #storedWeapons > 0 then
		for _, v in ipairs(storedWeapons) do
			local class = v

			-- Check if this is a valid item.
			if arista.item.items[class] then
				if gamemode.Call("PlayerCanDrop", ply, class, true, attacker) ~= false then
					arista.item.items[class]:make(ply:GetPos(), 1)
				end
			end
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
	ply.NextSpawnTime = CurTime() + spawnTime

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
			if entity:getAristaVar("scaleDamage") and entity:getAristaVar("scaleDamage") ~= 0 then damageinfo:ScaleDamage(entity:getAristaVar("scaleDamage")) end

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

	-- Check if the entity is a knocked out player.
	elseif entity:isPlayerRagdoll() and not entity:isCorpse() then
		local ply = entity:getRagdollPlayer()

		-- If they were just ragdolled, give them 2 seconds of damage immunity
		if entity._time and entity._time > CurTime() then
			damageinfo:SetDamage(0)

			return false
		end

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
		if ply:getAristaVar("scaleDamage") and ply:getAristaVar("scaleDamage") ~= 0 and not attacker:IsWorld() then damageinfo:ScaleDamage(ply:getAristaVar("scaleDamage")) end

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

-- Called when a player's weapons should be given.
function GM:PlayerLoadout(ply)
	if ply:hasAccess("tm", true) then ply:Give("gmod_tool") end
	if ply:hasAccess("pm", true) then ply:Give("weapon_physgun") end

	-- Give the player the camera, the hands and the physics cannon.
	ply:Give("gmod_camera")
	ply:Give("hands")

	ply:setAristaVar("spawnWeapons", {})
	ply:setAristaVar("gunCounts", {})

	if ply:Team() and ply:Team() > 0 then
		local team = arista.team.get(ply:Team())

		if not team then
			arista.logs.log(arista.logs.E.FATAL, "TEAM VALID BUT NOT IN TABLE! PLAYER LOADOUT FAILED! CHECK arista.team.stored!")

			return
		end

		if team.guns then
			for _,gun in ipairs(team.guns) do
				local give = true
				local item = false--self.Items[gun]

				if item then
					if item.Category then
						if ply:blacklisted("cat", item.Category) > 0 then
							give = false
						end
					end

					if give then
						ply:getAristaVar("spawnWeapons")[gun] = true
					end
				end

				if give then
					ply:Give(gun)
				end
			end
		end

		if team.ammo then
			for type, ammo in pairs(team.ammo) do
				ply:GiveAmmo(ammo, type, true)
			end
		end
	end

	-- Select the hands by default.
	ply:SelectWeapon("hands")
end

-- Called when the server shuts down or the map changes.
function GM:ShutDown()
	ErrorNoHalt("----------------------\n")
	ErrorNoHalt(os.date().." - Server shutting down\n")
	ErrorNoHalt("----------------------\n")

	for k, v in ipairs(player.GetAll()) do
		v:holsterAll()
		v:saveData()
	end

	arista.database.shutdown()
end

function GM:PlayerSwitchFlashlight(ply, on)
	-- Do not let the player use their flashlight while arrested, unconsious or tied.
	return not (ply:isArrested() or ply:isUnconscious() or ply:isTied())
end

-- Called when the player presses their use key (normally e) on a usable entity.
-- What specifies that an entity is usable is so far unknown, for instance some physics props are usable and others are not.
-- This hook is called once per tick while the player holds the use key down on some entities. Keep this in mind if you are going to notify them of something.
function GM:PlayerUse(ply, ent)
	if ply:isUnconscious() then
		-- If you're unconsious, you can't use things.
		return false
	elseif ply:useDisallowed() and not (ent:IsVehicle() and arista.config.vars.allowArrestedCars) then
		-- Prevent spam
		local nextNotify = ply:getAristaVar("nextNotify")

		if not nextNotify or CurTime() > nextNotify then
			ply:notify("AL_CANNOT_INVALID")

			ply:setAristaVar("nextNotify", CurTime() + 1)
		end

		-- If you're arrested, tied, or stunned you can't use things. (no hands!)
		return false
	elseif arista.entity.isDoor(ent) and not gamemode.Call("PlayerCanUseDoor", ply, ent) then

		-- If the hook says you can't open the door then don't let you. (Prevents doors that should be locked from glitching open)
		return false
	end

	-- Let sandbox/base deal with everything else.
	return self.BaseClass:PlayerUse(ply, ent)
end

function GM:PlayerCanJoinTeam(ply, teamid)
	local teamdata = arista.team.get(teamid)

	if not teamdata then
		return false -- If it's not a valid team (by our standards) then don't join it.
	end

	teamid = teamdata.index

	local nextChange = ply:getAristaVar("nextChangeTeam") or {}

	-- Run a series of checks
	if (nextChange[teamid] or 0) > CurTime() then
		local time = string.ToMinutesSeconds(nextChange[teamid] - CurTime())
		ply:notify("AL_YOU_WAIT_TEAM", time, teamdata.name)

		return false
	elseif ply:hasWarrant() ~= "" then
		ply:notify("AL_CANNOT_TEAM_WARRANTED")

		return false
	elseif ply:isArrested() then
		ply:notify("AL_CANNOT_TEAM_ARRESTED")

		return false
	elseif ply:isTied() then
		ply:notify("AL_CANNOT_TEAM_TIED")

		return false
	elseif gamemode.Call("PlayerCanDoSomething", ply, true) == false then
		return false
	end

	-- Ask the shared hook which handles the complex gang related things.
	return self:PlayerCanJoinTeamShared(ply, teamid)
end

function GM:PlayerDisconnected(ply)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ")  has disconnected.")

	-- Access incase of rejoin
	arista.entity.saveAccess(ply)

	-- Holseter all weapons.
	ply:holsterAll()

	-- Get rid of any inconvenient ragdolls
	ply:wakeUp(true)

	-- Save data.
	ply:saveData()

	-- Call the base class function.
	return self.BaseClass:PlayerDisconnected(ply)
end

-- Called when a player attempts suicide.
function GM:CanPlayerSuicide(ply)
	return false
end

-- Called when a player presses a key.
function GM:KeyPress(ply, key)
	--ply._IdleKick = CurTime() + self.Config["Autokick time"]

	if key == IN_JUMP then
		if ply:isStuck() then
			ply:holsterAll()

			-- Spawn them lightly now that we holstered their weapons.
			local health = ply:Health()
			ply:lightSpawn()
			ply:SetHealth(health)
		elseif ply:isUnconscious() and ply:Alive() and (ply:getAristaVar("knockOutPeriod") or 0) <= CurTime() then
			ply:wakeUp()

			ply:setAristaVar("knockOutPeriod", 0)
		end
	elseif key == IN_USE then
		-- Grab what's infront of us.
		local ent = ply:GetEyeTraceNoCursor().Entity

		if not IsValid(ent) then
			return
		elseif ent:isPlayerRagdoll() then
			ent = ent:getRagdollPlayer()
		end

		--~ Open mah doors ~
		if arista.entity.isDoor(ent) and ent:GetClass() ~= "prop_door_rotating" and gamemode.Call("PlayerCanUseDoor", ply, ent) then
			arista.entity.openDoor(ent, 0)
		--~ Crank dem Containers Boi ~
		elseif arista.container.isContainer(ent) and gamemode.Call("PlayerCanUseContainer", ply, ent) ~= false then
			local contents, io, filter = arista.container.getContents(ent, ply, true)

			local tab = {
				contents = contents,
				meta = {
					io = io,
					filter = filter, -- Only these can be put in here, if nil then ignore, but empty means nothing.
					size = arista.container.getLimit(ent), -- Max space for the container
					entindex = ent:EntIndex(), -- You'll probably want it for something
					name = arista.container.getName(ent) or "Container"
				}
			}

			net.Start("arista_container")
				net.WriteTable(tab)
			net.Send(ply)
		end
	end
end

function GM:SetPlayerSpeed(ply)
	if ply:isIncapacitated() or not ply:recapacitate() then
		ply:incapacitate()
	end
end

-- Called when a player presses F1.
function GM:ShowHelp(ply)
	net.Start("arista_menu")
	net.Send(ply)
end

-- Called when a player presses F2.
function GM:ShowTeam(ply)
	local door = ply:GetEyeTraceNoCursor().Entity

	-- Check if the player is aiming at a door. 128 ^ 2
	if not (IsValid(door) and arista.entity.isOwnable(door) and ply:GetPos():DistToSqr(ply:GetEyeTraceNoCursor().HitPos) <= 16384) then
		return
	end

	if gamemode.Call("PlayerCanOwnDoor", ply, door) then
		net.Start("arista_buyDoor")
		net.Send(ply)

		return
	end

	if not gamemode.Call("PlayerCanViewEnt", ply, door) then
		ply:notify("AL_CANNOT_NOACCESS")

		return
	end

	local detailstable = {}

	detailstable.access = table.Copy(door._owner.access)

	local owner = arista.entity.getOwner(door)
	table.insert(detailstable.access, owner)

	if owner == ply then
		detailstable.owned = {
			sellable = tobool(door._isDoor and not door._unsellable) or nil,
			name = gamemode.Call("PlayerCanSetEntName", ply, door) ~= false and arista.entity.getName(door) or nil,
		}
	end

	detailstable.owner = arista.entity.getPossessiveName(door)

	if door._isDoor then
		detailstable.owner = detailstable.owner .. " door"
	else
		detailstable.owner = detailstable.owner .. " " .. door:getTitle()
	end

	net.Start("arista_access")
		net.WriteTable(detailstable)
	net.Send(ply)
end

function GM:ShowSpare1(ply)
end

-- Called when a ply attempts to spawn a SWEP.
function GM:PlayerSpawnSWEP(ply, class, weapon)
	if ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a weapon (", class, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a weapon (", class, ").")

		return false
	end
end

-- Called when a player is given a SWEP.
function GM:PlayerGiveSWEP(ply, class, weapon)
	if ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " gave themselves a weapon (", class, ").")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to sgive themselves a weapon (", class, ").")

		return false
	end
end

-- Called when attempts to spawn a SENT.
function GM:PlayerSpawnSENT(ply, class)
	if ply:IsSuperAdmin() then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.SPAWN, ply, " spawned a ", class, ".")

		return true
	else
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.SPAWN, ply, " tried (and failed) to spawn a ", class, ".")

		return false
	end
end

-- Create a timer to automatically clean up decals.
function GM.ClearDecals()
	if arista.config.vars.clearDecals then
		for k, v in ipairs(player.GetAll()) do
			v:ConCommand("r_cleardecals\n")
		end
	end
end
timer.Create("Cleanup Decals", 60, 0, GM.ClearDecals)
