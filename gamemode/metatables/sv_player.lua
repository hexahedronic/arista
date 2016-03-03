local player = FindMetaTable("Player")

function player:databaseAristaVar(var)
	self._databaseVars = self._databaseVars or {}

	self._databaseVars[var] = self:getAristaVar(var)
end

---
-- Load a player's data from the SQL database, overwriting any data already loaded on the player. Performs it's actions in a threaded query.
-- If the player's data has not been loaded after 30 seconds, it will call itself again
function player:loadData()
	arista.database.loadPlayer(self)
end

---
-- Save a player's data to the SQL server in a threaded query.
-- @param create Whether to create a new entry or do a normal update.
function player:saveData(create)
	arista.database.savePlayer(self, create)
end

function player:notify(format, ...)
	-- todo: code here, language system is gonna be
	-- clientsided, so forward all arguments (tostring'ed) and format
	-- and let client sort it out.
	local args = {...}

	net.Start("arista_notify")
		net.WriteString(format)
		net.WriteUInt(#args, 8)

		for k, v in ipairs(args) do
			net.WriteString(v)
		end
	net.Send(self)
end

function player:isDonator()
	local donator = self:getAristaVar("donator")

	return donator and donator > 0
end

function player:getRagdoll()
	return self.ragdoll and self.ragdoll.entity
end

---
-- Give a player access to a the flag(s) specified
-- @param flaglist A list of flags with no spaces or delimiters
function player:giveAccess(flaglist)
	--[[local flag,access
	access = self.cider._Access
	for i = 1, flaglist:len() do
		flag = flaglist:sub(i,i)
		if (not access:find(flag)) then
			access = access .. flag
		end
	end
	self.cider._Access = access]]
end

---
-- Take away away a player's access to the flag(s) specified
-- @param flaglist A list of flags with no spaces or delimiters
function player:takeAccess(flaglist)
	--[[local access
	access = self.cider._Access
	for i = 1, flaglist:len() do
		access = access:gsub(flaglist:sub(i,i), "")
	end
	self.cider._Access = access]]
end

---
-- Blacklist a player from performing a specific activity
-- @param kind What kind of activity. Can be one of "cat","item","cmd" or "team". In order: Item category, specific item, command or specific team/job.
-- @param thing What specific activity. For instance if the kind was 'cmd', the thing could be 'unblacklist'.
-- @param time How long in seconds to blacklist them for.
-- @param reason Why they have been blacklisted.
-- @param blacklister Who blacklisted them. Preferably a string (the name), can also take a player.
function player:blacklist(kind, thing, time, reason, blacklister)
	--[[local blacklist
	if (type(blacklister) == "Player") then
		blacklister = blacklister:Name()
	end
	blacklist = self.cider._Blacklist[kind]
	blacklist = blacklist or {}
	blacklist[thing] = {
		time = os.time() + time * 60,
		reason = reason,
		admin = blacklister
	}
	self.cider._Blacklist[kind] = blacklist]]
end

---
-- Unblacklist a player from a previously existing blacklist.
-- @param kind What kind of activity. Can be one of "cat","item","cmd" or "team". In order: Item category, specific item, command or specific team/job.
-- @param thing What specific activity. For instance if the kind was 'cmd', the thing could be 'unblacklist'.
function player:removeBlacklist(kind, thing)
	--[[local blacklist
	blacklist = self.cider._Blacklist[kind]
	if (blacklist) then
		blacklist[thing] = nil
		if (table.Count(blacklist) == 0) then
			blacklist = nil
		end
		self.cider._Blacklist[kind] = blacklist
	end]]
	-- todo: doors
end

---
-- Gives a player access to a door, unlocks it, sets the door's name and specifies if the player can sell it.
-- @param door The door entity to be given access to
-- @param name The name to give the door (optional)
-- @param unsellable If the player should be prevented from selling this door.
function player:giveDoor(door, name, unsellable)
	if not (arista.entity.isDoor(door) and arista.entity.isOwnable(door)) then
		return
	end

	door._unsellable = unsellable

	arista.entity.setOwnerPlayer(door, self)
	self:AddCount("doors", door)

	if name and name ~= "" then
		arista.entity.setName(door, name)
	end

	door:unLock()
	door:EmitSound("doors/door_latch3.wav")
end

---
-- Removes a player's access to a door, unlocks it and optionally gives them a refund
-- @param door The door to take the access from
-- @param norefund If true, do not give the player a refund
function player:takeDoor(door, norefund)
	if not arista.entity.isDoor(door) or arista.entity.getOwner(door) ~= self then
		return
	end
	-- Unlock the door so that people can use it again and play the door latch sound.
	door:unLock()
	door:EmitSound("doors/door_latch3.wav")

	-- Remove our access to it
	arista.entity.takeAccessPlayer(door, self)
	self:TakeCount("doors", door)

	-- Give the player a refund for the door if we're not forcing it to be taken.
	if not norefund then
		--self:giveMoney(GM.Config["Door Cost"] / 2)
	end
end

do
	local function jobTimer(ply)
		if not IsValid(ply) then return end

		ply:notify("You have reached the timelimit for this job!")
		-- todo: language
		ply:demote()
	end

	---
	-- Makes the player join a specific team with associated actions
	-- @param tojoin What team to join
	-- @return success or failure, failure message.
	function player:joinTeam(tojoin)
		--[[local oldteam
		tojoin = cider.team.get(tojoin)
		if (not tojoin) then
			return false, "That is not a valid team!"
		elseif (self:Blacklisted("team",tojoin.index) > 0) then
			self:BlacklistAlert("team", tojoin.index, tojoin.name)
			return false
		end
		timer.Violate(self:UniqueID().." holster")
		oldteam = self:Team()
		GM:Log(EVENT_TEAM, "%s changed team from %q to %q.", self:Name(), cider.team.query(oldteam, "name", "Unconnected / Joining"), tojoin.name)
		self._NextChangeTeam[oldteam] = CurTime() + cider.team.query(oldteam, "waiting", 300) -- Make it so we can't join our old team for x seconds (default 5 mins)
		self:SetTeam(tojoin.index)
		self._Job = tojoin.name
		self:SetNWString("Job", self._Job)
		if ((self._JobTimeExpire or 0) > CurTime()) then
			self._JobTimeExpire = 0
			self._JobTimeLimit = 0
			timer.Stop("Job Timelimit: "..self:UniqueID())
		end if (tojoin.timelimit != 0) then
			self._JobTimeExpire = tojoin.timelimit + CurTime()
			self._JobTimeLimit = tojoin.timelimit
			timer.Create("Job Timelimit: "..self:UniqueID(), tojoin.timelimit, 1, jobtimer, self)
		end
		-- Change our salary.
		self._Salary = tojoin.salary
		gamemode.Call("PlayerAdjustSalary", self)

		-- Tell the client they can't join this team again.
		umsg.Start("TeamChange", self)
		umsg.Char(oldteam)
		umsg.End()

		-- Some tidying up
		-- Unwarrant the player.
		self:UnWarrant()
		-- Call the hook to tell various things we've changed team
		gamemode.Call("PlayerChangedTeams", self, oldteam, tojoin.index)
		-- Silently kill the player.
		self._ChangeTeam = oldteam
		self:KillSilent()
		-- Return true because it was successful.
		return true]]

		-- todo: team/job stuff
	end
end

---
-- Demotes a player from their current team.
function player:demote()
	self:holsterAll()

	--if cider.team.getGroupLevel(self:Team()) == 1 then
		self:joinTeam(TEAM_DEFAULT)
	--else
	--	self:JoinTeam(cider.team.getGroupBase(cider.team.getGroupByTeam(self:Team())))
	--end
end

local function warrantTimer(ply)
	if not IsValid(ply:IsValid()) then return end

	gamemode.Call("PlayerWarrantExpired", ply, ply:getAristaVar("warrant"))
	ply:unWarrant()
end

---
-- Applies a warrant to a player.
-- @param class The warrant type to apply. 'arrest' or 'search'.
-- @param time Optional, specify the time for the warrant to last
function player:warrant(class, time)
	gamemode.Call("PlayerWarranted", self, class, time)

	self:setAristaVar("warrant", class)
	local expires = time or (class == "arrest" and arista.config.vars.arrestWarrantTime or arista.config.vars.searchWarrantTime)

	-- Prevents any unplesant bugs due to user error.
	if expires <= 0 then
		expires = 0.1
	end

	self:setAristaVar("warrantExpireTime", CurTime() + expires)

	timer.Create("Warrant Expire " .. self:UniqueID(), expires, 1, function() warrantTimer(self, class) end)
end

---
-- Removes the player's warrant
function player:unWarrant()
	gamemode.Call("PlayerUnWarranted", self)

	self:setAristaVar("warrant", nil)
	timer.Destroy("Warrant Expire " .. self:UniqueID())
end

local uptr, downtr = Vector(0, 0, 256), Vector(0, 0, -1024)
local function dobleed(ply)
	if not IsValid(ply) then return end

	local pos = ply:GetPos()
	local tr = util.TraceLine({
		start = pos + uptr,
		endpos = pos + downtr,
		filter = ply,
	})

	util.Decal("Blood", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
end

---
-- Causes the player to leave a trail of blood behind them
-- @param time How many seconds they should bleed for. 0 or nil for infinite bleeding.
function player:bleed(time)
	timer.Start("Bleeding " .. self:UniqueID(), 0.25, (seconds or 0) * 4, function() dobleed(self) end)
end

---
-- Stops the player bleeding immediately.
function player:stopBleeding()
	timer.Destroy("Bleeding " .. self:UniqueID())
end

local function doforce(ragdoll, velocity)
	if IsValid(ragdoll) and IsValid(ragdoll:GetPhysicsObject()) then
		ragdoll:GetPhysicsObject():SetVelocity(velocity)
	end
end
---
-- Knocks out (ragdolls) a player requiring their input to get back up again
-- @param time How long to force them down for. Nil or 0 allows them up instantly.
-- @param velocity What velocity to give to the ragdoll on spawning
function player:knockOut(time, velocity)
	if self:isUnconscious() then return end -- Don't knock us out if we're out already

	if self:InVehicle() then -- This shit goes crazy if you ragdoll in a car. Do not do it.
		self:ExitVehicle()
	end

	-- Grab the player's current bone matrix so the ragdoll spawns as a natural continuation
	local bones = {}
	for i = 0, 70 do
		bones[i] = self:GetBoneMatrix(i)
	end

	local model, ragdoll = self:GetModel()
	if util.IsValidRagdoll(model) then
		ragdoll = ents.Create("prop_ragdoll")
	else
		ragdoll = ents.Create("prop_physics")
	end

	if not IsValid(ragdoll) then
		arista.logs.log(arista.logs.E.WARNING, "Creation of ragdoll for ", self, " failed.")

		return
	end

	-- Set preliminary data
		ragdoll:SetModel(model)
		ragdoll:SetPos(self:GetPos())
		local angles = self:GetAngles()
			angles.p = 0
		ragdoll:SetAngles(angles)
	ragdoll:Spawn()

	-- Stops the ragdoll colliding with players, to prevent accidental/intentional stupid deaths.
	ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	-- Gief to world to prevent people picking it up and waving it about
	--cider.propprotection.GiveToWorld(ragdoll)

	-- Pose the ragdoll in the same shape as us
	for i, matrix in ipairs(bones) do
		ragdoll:SetBoneMatrix(i, matrix)
	end
	-- todo: not working

	-- Try to send it flying in the same direction as us.
	local tid = "Ragdoll Force Application " .. self:UniqueID()
	timer.Create(tid, 0.05, 5, function()
		if not IsValid(self) then timer.Destroy(tid) return end
		doforce(ragdoll, (velocity or self:GetVelocity()) * 5)
	end)
	-- todo: nasty timer

	-- Make it look even more like us.
	ragdoll:SetSkin(self:GetSkin())
	ragdoll:SetColor(self:GetColor())
	ragdoll:SetMaterial(self:GetMaterial())

	if self:IsOnFire() then
		ragdoll:Ignite(16, 0)
	end

	-- Allow other parts of the script to associate it with us.
	ragdoll:networkAristaVar("player", self)

	-- Allow other parts of the script to associate us with it
	self.ragdoll = {
		entity	= ragdoll,
		health	= self:Health(),
		model	= self:GetModel(),
		skin	= self:GetSkin(),
		team	= self:Team(),
	}

	-- We've got some stuff to perform if this isn't a corpse.
	if self:Alive() then
		-- Take the player's weapons away for later returnage
		self:takeWeapons()

		-- If we're being forced down for a while, tell the client.
		if time and time > 0 then
			local period = CurTime() + time
			self:setAristaVar("knockOutPeriod", period)
		else
			self:setAristaVar("knockOutPeriod", 0)
		end
	else
		ragdoll:networkAristaVar("corpse", true)
	end

	-- Get us ready for spectation
	self:StripWeapons()
	self:Flashlight(false)
	self:CrosshairDisable()
	self:stopBleeding()

	-- Spectate!
	self:SpectateEntity(ragdoll)
	self:Spectate(OBS_MODE_CHASE)

	-- Set some infos for everyone else
	self:setAristaVar("unconscious", true)
	self:setAristaVar("ragdoll", ragdoll)

	gamemode.Call("PlayerKnockedOut", self)
end

---
-- Wakes a player up (unragdolls them) immediately
-- @param reset If set, do not give the player back the things they had when they were knocked out.
function player:wakeUp(reset)
	if not self.ragdoll or table.Count(self.ragdoll) == 0 then return end

	-- If the player is on a different team to the one they were on when they were knocked out, respawn them. TODO: Why do this?
	--[[if (self:Team() ~= self.ragdoll.team) then
		self.ragdoll.team = self:Team()
		self:Spawn()
		return
	end]]
	-- todo: ??

	-- Get us out of this spectation
	self:UnSpectate()
	self:CrosshairEnable()

	local ragdoll = self:getRagdoll()

	-- If we're not doing a reset, then there are things we need to do like giving the player stuff back
	if not reset then
		-- Do a light spawn so basic variables are set up
		self:lightSpawn()
		-- Get our weapons back
		self:returnWeapons()

		-- Set the basic info we stored
		self:SetHealth(self.ragdoll.health or 100)

		-- Duplicate the ragdoll's current state if it exists
		if IsValid(ragdoll) then
			self:SetPos(ragdoll:GetPos())
			self:SetModel(ragdoll:GetModel())
			self:SetSkin(ragdoll:GetSkin())
			self:SetColor(ragdoll:GetColor())
			self:SetMaterial(ragdoll:GetMaterial())
		else -- Otherwise set the state we were in to start with
			self:SetModel(self.ragdoll.model)
			self:SetSkin(self.ragdoll.skin)
		end
	end

	-- If the ragdoll exists, remove it.
	if IsValid(ragdoll) then
		ragdoll:Remove()
	end

	-- Wipe the ragdoll table
	self.ragdoll = {}

	-- Reset the various knockout state vars
	self:setAristaVar("stunned", false)
	self:setAristaVar("tripped", false)
	self:setAristaVar("sleeping", false)

	-- Set some infos for everyone else
	self:setAristaVar("unconscious", false)
	self:setAristaVar("ragdoll", NULL)

	gamemode.Call("PlayerWokenUp", self)
end

---
-- Takes a player's weapons away and stores them in a table for later returnal
-- @param noitems Do not save any items the player has equipped
function player:takeWeapons(noitems)
	local stored = {}

	for _, weapon in ipairs(self:GetWeapons()) do
		local class = weapon:GetClass()

		--if not (noitems and GM.Items[class]) then
			stored[class] = true
		--end
	end

	self:setAristaVar("storedWeapons", stored)

	local wep = self:GetActiveWeapon()
	if IsValid(wep) then
		self:setAristaVar("storedWeapon", wep:GetClass())
	else
		self:setAristaVar("storedWeapon", nil)
	end

	self:StripWeapons()
end

---
-- Gives a player their stored weapons back
function player:returnWeapons()
	local res = gamemode.Call("PlayerCanRecieveWeapons", self)

	if res == false then
		return false
	end

	local storedWeapons = self:getAristaVar("storedWeapons")

	for class in pairs(storedWeapons) do
		self:Give(class)
	end

	self:setAristaVar("storedWeapons", {})

	local wep = self:getAristaVar("storedWeapon")
	if wep then
		self:SelectWeapon(wep)
		self:setAristaVar("storedWeapon", nil)
	else
		--self:SelectWeapon("cider_hands")
	end
	-- todo: hands
end

---
-- incapacitates a player - drops their movement speed, prevents them from jumping or doing most things.
function player:incapacitate()
	self:SetRunSpeed(arista.config.vars.incapacitatedRunSpeed)
	self:SetWalkSpeed(arista.config.vars.incapacitatedWalkSpeed)
	self:SetJumpPower(0)
	self:setAristaVar("incapacitated", true)
end

---
-- Recapacitates a player, letting them walk, run and jump like normal
function player:recapacitate()
	local res = gamemode.Call("PlayerCanBeRecapacitated", self)

	if res == false then
		return false
	end

	self:SetRunSpeed(arista.config.vars.runSpeed)
	self:SetWalkSpeed(arista.config.vars.walkSpeed)
	self:SetJumpPower(arista.config.vars.jumpPower)
	self:setAristaVar("incapacitated", false)

	return true
end

---
-- Ties a player up so they cannot do anything but walk about
function player:tieUp()
	if self:isTied() then return end

	self:incapacitate()
	self:takeWeapons()

	self:setAristaVar("tied", true)

	self:Flashlight(false)
end

---
-- Unties a player so that they can do things again
-- @param reset If true, do not give the player their weapons back
function player:unTie(reset)
	if not reset and not self:isTied() then return end

	self:setAristaVar("tied", false)

	if not reset then
		self:recapacitate()
		self:returnWeapons()
	end
end

local function arrestTimer(ply)
	if not IsValid(ply) then return end
	ply:unArrest(true)
	ply:notify("Your arrest time has finished!")
	-- todo: language

	ply:Spawn()
end

---
-- Arrest a player so they cannot do most things, then unarrest them a bit later
-- @param time Optional - Specify how many seconds the player should be arrested for. Will default to the player's ._ArrestTime var
function player:arrest(time)
	gamemode.Call("PlayerArrested", self)

	self:setAristaVar("arrested", true)

	local arrestTime = time or self:getAristaVar("arrestTime")
	timer.Create("UnArrest " .. self:UniqueID(), arrestTime, 1, function() arrestTimer(self) end)

	self:setAristaVar("unarrestTime", CurTime() + arrestTime)

	self:incapacitate()

	self:takeWeapons(true)
	self:StripAmmo()

	self:Flashlight(false)

	self:unWarrant()
	self:unTie(true)
end
---
-- Unarrest an arrested player before their timer has run out.
function player:unArrest(reset)
	if not self:isArrested() then return end
	gamemode.Call("PlayerUnArrested", self)

	self:setAristaVar("arrested", false)
	self:setAristaVar("unarrestTime", 0)

	timer.Destroy("UnArrest "..self:UniqueID())

	if not reset then
		self:recapacitate()
		self:returnWeapons()
	end
end

----------------------------
--     Get Functions      --
----------------------------

---
-- Check if a player has access to the flag(s) specified.
-- @param flaglist A list of flags with no spaces or delimiters
-- @param any Whether to search for any flag on the list (return true at the first flag found), or for every flag on the list. (return false on the first flag not found)
-- @return true on succes, false on failure.
function player:hasAccess(flaglist, any)
	--[[local access, teamaccess, flag
	access = self.cider._Access
	teamaccess = cider.team.query(self:Team(),"access","")
	for i = 1, flaglist:len() do
		flag = flaglist:sub(i,i)
		if(flag == GM.Config["Default Access"]
		or GM.FlagFunctions[flag] and GM.FlagFunctions[flag](self)
		or access:find(flag)
		or teamaccess:find(flag)) then
			if (any) then return true end -- If 'any' is selected, then return true whenever we get a match
		elseif (not any) then -- If 'any' is not selected we don't get a match, return false.
			return false
		end
	end
	-- If 'any' is selected and none have matched, return false. If 'any' is not selected and we have matched every flag return true.
	return not any]]
end

---
-- Checks if a player is blacklisted from using something
-- and also returns the reason and blacklister if they are.
-- @param kind What kind of activity. Can be one of "cat","item","cmd" or "team". In order: Item category, specific item, command or specific team/job.
-- @param thing What specific activity. For instance if the kind was 'cmd', the thing could be 'unblacklist'.
-- @return 0 if the player is not blacklisted, otherwise the time in seconds, the reason and the name of the blacklister.
function player:isBlacklisted(kind, thing)
	--[[local blacklist,time
	blacklist = self.cider._Blacklist[kind]
	if (not (blacklist and blacklist[thing])) then
		return 0
	end
	blacklist = blacklist[thing]
	time = blacklist.time - os.time()
	if (time <= 0) then
		self:UnBlacklist(kind, thing)
		return 0
	end
	return time / 60, blacklist.reason, blacklist.admin]]
end

----------------------------
--    Action Functions    --
----------------------------

---
-- Sends a generic radio message to everyone in the player's team or gang.
-- Also emits a normal speach version of the message.
-- Note: Calls "PlayerAdjustRadioRecipients" to allow plugins to change who hears the message
-- TODO: Remove this and set up a frequency based thingy.
-- @param words The words the player should send in the radio message
function player:sayRadio(words)
	local team = self:Team()
	local gang = false--cider.team.getGang(iteam)
	-- todo: gang

	-- If we're in a gang, send the message to them, otherwise just to our teammates.
	if gang then
		recipients = cider.team.getGangMembers(cider.team.getGroupByTeam(iteam), gang)
	else
		recipients = team.GetPlayers(iteam)
	end

	-- Call a hook to allow plugins to adjust who also gets the message.
	gamemode.Call("PlayerAdjustRadioRecipients", self, words, recipients)

	-- Compile a list of those who can't hear the voice
	local nohear = {}

	-- Loop through every recipient and add the message to their chatbox
	for _, ply in pairs(recipients) do
		--cider.chatBox.add(ply, self, "radio", words)
		nohear[ply] = true
	end

	-- Tell everyone nearby that we just said a waydio
	local pos = self:GetPos()
	for _, ply in pairs(player.GetAll()) do
		--if (not nohear[ply] and ply:GetPos():Distance(pos) <= GM.Config["Talk Radius"]) then
		--	cider.chatBox.add(ply, self, "loudradio", words)
		--end
	end
end

---
-- Adds an emote to the chatbox coming from the player
-- @param words What the emote should say
-- @param other Other person involved, if there is one
function player:emote(words, other)
	local pronoun = self:getPronouns()
	words:gsub("<P>", pronoun)

	if other and IsValid(other) then
		words:gsub("<N>", other:Name())

		local oPronoun = other:getPronouns()
		words:gsub("<O>", oPronoun)
	end

	--cider.chatBox.addInRadius(self, "me", words, self:GetPos(), GM.Config["Talk Radius"])
end

function player:setMoney(amount)
	local amt = math.Clamp(amount, 0, arista.config.vars.maxMoney)
	self:setAristaVar("money", amt)
end

---
-- Adds an amount of money to the player's money count and triggers an alert on the client.
-- @param amount How much money to add (can be negative)
function player:giveMoney(amount)
	local money = self:getMoney()
	self:setMoney(money + amount)

	net.Start("arista_moneyAlert")
		net.WriteInt(amount)
	net.Send(self)
end

---
-- Causes a player to put all their weapons into their inventory instantly. If a weapon will not fit, it is dropped at their feet to reduce loss.
function player:holsterAll()
	if self:InVehicle() then
		self:ExitVehicle() -- This fixes a suprisingly high number of glitches
	end

	--[[local class
	for _, weapon in pairs(self:GetWeapons()) do
		class = weapon:GetClass()
		self:StripWeapon(class)
		if (GM.Items[class]) then
			if (gamemode.Call("PlayerCanHolster", self, class, true) and cider.inventory.update(self, class, 1)) then
				-- ...
			elseif (gamemode.Call("PlayerCanDrop", self, class, true)) then
				GM.Items[class]:Make(self:GetPos(), 1)
			end
		end
	end
	self:SelectWeapon("cider_hands")]]
end

---
-- Lightly spawn a player (Do not reset any important vars)
function player:lightSpawn()
	self:setAristaVar("lightSpawn", true)
	self:Spawn()
end

---
-- Notifies the player that they've been blacklisted from using something
-- @param kind What kind of activity. Can be one of "cat","item","cmd" or "team". In order: Item category, specific item, command or specific team/job.
-- @param thing What specific activity. For instance if the kind was 'cmd', the thing could be 'unblacklist'.
-- @param name The name of what it is
function player:blacklistAlert(kind, thing, name)
	--[[local time, reason, admin = self:Blacklisted(kind, thing)
	if (time >= 1440) then
		time = math.ceil(time / 1440) .. " days"
	elseif (time >= 60) then
		time = math.ceil(time / 60) .. " hours"
	else
		time = time .. " minutes"
	end
	self:Notify("You have been blacklisted from using " .. tostring(name) .. " by " .. admin .. " for " .. time .. " for '" .. reason .. "'!")]]
end
