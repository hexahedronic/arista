-- Load specific command types to keep this file cleaner.
arista.file.loadDir("commands/", "Command Library", "Command Libraries")

-- An important. (Very important, do not remove.)
arista.command.add("fuck", "", 0, function(p)
	p:notify("AL_FUCK")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your job title
arista.command.add("job", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "" or words == "none" or words == "default" then
		words = team.GetName(ply:Team())
	end

	ply:setAristaVar("job", words)

	ply:notify("AL_YOU_CHANGE_JOB", words)
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their job name to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your clan.
arista.command.add("clan", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if not words or words == "quit" or words == "none" then
		words = ""
	end

	ply:setAristaVar("clan", words)

	if words == "" then
		ply:notify("AL_YOU_REMOVE_CLAN")
	else
		ply:notify("AL_YOU_CHANGE_CLAN", words)
	end
	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their clan to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- A command to change your clan.
arista.command.add("details", "", 0, function(ply, arguments)
	local words = table.concat(arguments, " ")
	words = words:sub(1, 64):Trim()

	if words == "" or words:lower() == "none" then
		ply:setAristaVar("details", "")

		-- Print a message to the player.
		ply:notify("AL_YOU_REMOVE_DETAILS")
	else
		ply:setAristaVar("details", words)

		-- Print a message to the player.
		ply:notify("AL_YOU_CHANGE_DETAILS", words)
	end

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") changed their details to '", words, "'.")
end, "AL_COMMAND_CAT_COMMANDS")

-- All commands excluding note (i intend to change this a fair bit) and abuse commands
-- abuse commands will be returning but I need to focus more on this stuff atm
--[[
local function getnamething(kind,thing)
	if kind == "team" then
	-- Team blacklist
		local team = cider.team.get(thing)
		if		not team			then return false,thing.." is not a valid team!"
		elseif  not team.blacklist	then return false, team.name.." isn't blacklistable!"
		end
		return team.name, team.index
	elseif kind == "item" then
	-- Item blacklist
		local  item = GM:GetItem(thing)
		if not item then return false,thing.." is not a valid item!" end
		return item.Name, item.UniqueID
	elseif kind == "cat" then
	-- Category blacklist
		local  cat = GM:GetCategory(thing)
		if not cat then return false,thing.." is not a valid category!" end
		return cat.Name, cat.index;
	elseif kind == "cmd" then
	-- Command blacklist
		local cmd = cider.command.stored[thing]
		if not cmd then return false,thing.." is not a valid command!" end
		return thing, thing;
	else
		return false,thing.." is not a valid blacklist type! Valid: team/item/cat/cmd"
	end
end
local function getBlacklistTime(time)
	if (time >= 1440) then
		return math.ceil(time / 1440) .. " days";
	elseif (time >= 60) then
		return math.ceil(time / 60) .. " hours";
	else
		return time .. " minutes";
	end
end
-- A command to blacklist a player from a team.
--/blacklist chronic team police 0 "asshat"
-- team/item/cat/cmd
--<name> <type> <thing> <time> <reason>
--TODO: Make a vgui to handle this shit.
cider.command.add("blacklist", "m", 5, function(ply, target, kind, thing, time, ...)
	local victim = player.Get(target);
	if (not victim) then
		return false, "Invalid player '"..target.."'!";
	end
	kind, thing, time = string.lower(kind), string.lower(thing), tonumber(time);
	if (time < 1) then
		return false, "You cannot blacklist for less than a minute!";
	elseif ((time > 10080 and not ply:IsSuperAdmin()) or (time > 1440 and not ply:IsAdmin())) then
		return false, "You cannot blacklist for that long!";
	end
	local reason = table.concat({...}, " "):sub(1,65):Trim();
	if (not reason or reason == "" or (reason:len() < 5 and not ply:IsSuperAdmin())) then
		return false, "You must specify a reason!";
	end
	-- Get the name of what we're doing and the thing itself.
	local name, thing = getnamething(kind, thing);
	if (not name) then
		return false, thing;
	end
	if (victim:Blacklisted(kind, thing) ~= 0) then
		return false, victim:Name() .. " is already blacklisted from that!";
	end
	if (not gamemode.Call("PlayerCanBlacklist", ply, victim, kind, thing, time, reason)) then
		return false;
	end
	gamemode.Call("PlayerBlacklisted", victim, kind, thing, time, reason, ply);
	victim:Blacklist(kind, thing, time, reason, ply:Name());
	time = getBlacklistTime(time);
	player.NotifyAll("%s blacklisted %s from using %s for %s for %q.", nil, ply:Name(), victim:Name(), name, time, reason);
end, "Moderator Commands", "<player> <team|item|cat|cmd> <thing> <time> <reason>", "Blacklist a player from something", true);

cider.command.add("unblacklist", "m", 3, function(ply, target, kind, thing)
	local victim = player.Get(target);
	if (not victim) then
		return false, "Invalid player '"..target.."'!";
	end
	kind, thing = string.lower(kind), string.lower(thing);
	-- Get the name of what we're doing and the thing itself.
	local name, thing = getnamething(kind, thing);
	if (not name) then
		return false, thing;
	end
	if (victim:Blacklisted(kind, thing) == 0) then
		return false, victim:Name() .. " is not blacklisted from that!";
	end
	if (not gamemode.Call("PlayerCanUnBlacklist", ply, victim, kind, thing)) then
		return false;
	end
	gamemode.Call("PlayerUnBlacklisted", victim, kind, thing, ply);
	victim:UnBlacklist(kind, thing);
	player.NotifyAll("%s unblacklisted %s from using %s.", nil, ply:Name(), victim:Name(), name);
end, "Moderator Commands", "<player> <team|item|cat|cmd> <thing>", "Unblacklist a player from something", true)

cider.command.add("blacklistlist", "m", 1, function(ply, target)
	local victim = player.Get(target);
	if (not victim) then
		return false, "Invalid player '"..target.."'!";
	end
	local blacklist = victim.cider._Blacklist;
	if (table.Count(blacklist) == 0) then
		return false, victim:Name() .. " isn't blacklisted from anything!";
	end
	local printtable, words = {};
	local namelen, adminlen, timelen = 0, 0, 0;
	local time, name, admin, reason
	for kind, btab in pairs(blacklist) do
		if (table.Count(btab) == 0) then
			blacklist[kind] = nil;
		else
			words = {};
			for thing in pairs(btab) do
				time, reason, admin = victim:Blacklisted(kind, thing);
				if (time ~= 0) then
					name = getnamething(kind, thing);
					time = getBlacklistTime(time);
					if ( name:len() > namelen ) then  namelen = name:len();  end
					if (admin:len() > adminlen) then adminlen = admin:len(); end
					if (time:len()  > timelen ) then  timelen = time:len();  end
					words[#words + 1] = {name, time, admin, reason};
				end
			end
			if (#words ~= 0) then
				printtable[#printtable + 1] = {kind, words};
			end
		end
	end
	if (#printtable == 0) then
		return false, victim:Name() .. " isn't blacklisted from anything!";
	end
	local a,b,c = ply.PrintMessage, ply, HUD_PRINTCONSOLE;
	-- A work of art in ASCII formatting. A shame it is soon to be swept away
		a(b,c, "----------------------------[ Blacklist Details ]-----------------------------");
		local w = "%-" .. namelen + 2 .. "s| %-" .. timelen + 2 .. "s| %-" .. adminlen + 2 .. "s| %s";
		a(b,c,w:format("Thing", "Time", "Admin", "Reason"));
		for _,t in ipairs(printtable) do
			a(b,c, "-----------------------------------[ "..string.format("%-4s",t[1]).." ]------------------------------------");
			for _,t in ipairs(t[2]) do
				a(b,c,w:format(t[1], t[2], t[3], t[4]));
			end
		end
	-- *sigh*
	player:Notify("Blacklist details have been printed to your console.",0);
end, "Moderator Commands", "<player>", "Print a player's blacklist to your console (temp)", true);

-- A command to demote a player.
cider.command.add("demote", "b", 2, function(ply, target, ...)
	local victim = player.Get(target);
	if (not victim) then
		return false, "Invalid player '"..target.."'!";
	end
	local reason = table.concat({...}, " "):sub(1,65):Trim();
	if (not reason or reason == "" or (reason:len() < 5 and not ply:IsSuperAdmin())) then
		return false, "You must specify a reason!";
	end
	if (not gamemode.Call("PlayerCanDemote", ply, victim)) then
		return false;
	end
	local tid = victim:Team();
	victim:Demote();
	player.NotifyAll("%s demoted %s from %s for %q.", nil, ply:Name(), victim:Name(), team.GetName(tid), reason);
end, "Commands", "<player> <reason>", "Demote a player from their current team.", true);

cider.command.add("save", "s", 0, function(ply)
	player.SaveAll()
	GM:Log(EVENT_PUBLICEVENT,"%s saved everyone's profiles.", ply:Name())
end, "Super Admin Commands", "", "Forceably save all profiles")

-- A command to give a player some money.
cider.command.add("givemoney", "b", 1, function(ply, amt)
	local victim = ply:GetEyeTraceNoCursor().Entity;
	if (not (IsValid(victim) and victim:IsPlayer())) then
		return false, "You must look at a player to give them money!";
	end
	amt = tonumber(amt);
	if (not amt or amt < 1) then
		return false, "You must specify a valid amount of money!";
	end
	amt = math.floor(amt);
	if (not ply:CanAfford(amt)) then
		return false, "You do not have enough money!";
	end
	ply:GiveMoney(-amt);
	victim:GiveMoney(amt);

	ply:Emote("hands " .. victim:Name() .. " a wad of money.");

	ply:Notify("You gave " .. victim:Name() .. " $" .. amt .. ".", 0);
	victim:Notify(ply:Name() .. " gave you $" .. amt .. ".", 0);
	GM:Log(EVENT_EVENT, "%s gave %s $%i.", ply:Name(), victim:Name(), amt);
end, "Commands", "<amount>", "Give some money to the player you're looking at.", true);

-- A command to drop money.
cider.command.add("dropmoney", "b", 1, function(ply, amt)
	-- Prevent fucktards spamming the dropmoney command.
	ply._NextMoneyDrop = ply._NextMoneyDrop or 0;
	if ((ply._NextMoneyDrop or 0) > CurTime()) then
		return false, "You need to wait another " .. (ply._NextMoneyDrop - CurTime()).. " seconds before dropping more money.";
	end
	local pos = ply:GetEyeTraceNoCursor().HitPos;
	if (ply:GetPos():Distance(pos) > 255) then
		pos = ply:GetShootPos() + ply:GetAimVector() * 255;
	end
	amt = tonumber(amt);
	if (not amt or amt < 1) then
		return false, "You must specify a valid amount of money!";
	end
	amt = math.floor(amt);
	if (not ply:CanAfford(amt)) then
		return false, "You do not have enough money!";
	elseif (amt < 500) then -- Fucking spammers again.
		return false, "You cannot drop less than $500.";
	end
	ply._NextMoneyDrop = CurTime() + 30;
	ply:GiveMoney(-amt);
	cider.propprotection.PlayerMakePropOwner(GM.Items["money"]:Make(pos, amt), ply, true);
	GM:Log(EVENT_EVENT,"%s dropped $%i.", ply:Name(), amt);
end, "Commands", "<amount>", "Drop some money where you are looking.", true);

local function containerHandler(ply, item, action, number)
	local container = ply:GetEyeTraceNoCursor().Entity
	if not (ValidEntity(container) and cider.container.isContainer(container) and ply:GetPos():Distance( ply:GetEyeTraceNoCursor().HitPos ) <= 128) then
		return false,"That is not a valid container!"
	elseif not gamemode.Call("PlayerCanUseContainer",ply,container) then
		return false,"You cannot use that container!"
	end
	item = item:lower()
	action = action:lower()
	if (action ~= "put" and action ~= "take") then
		return false, "Invalid option: "..action.."!";
	end
	number = math.floor(tonumber(number) or 1);
	if (number < 1) then
		return false, "Invalid amount!";
	elseif not GM.Items[item]  then
		return false,"Invalid item!"
	end
	local cInventory,io,filter = cider.container.getContents(container,ply,true)
	local pInventory = ply.cider._Inventory
	if action == "put" then
		local amount = item == "money" and ply.cider._Money or pInventory[item]
		number = math.abs(tonumber(number) or amount or 0)
		if not (amount and amount > 0 and amount >= number) then
			return false, "You do not have enough items!"
		end
	else
		local amount = cInventory[item]
		number = math.abs(tonumber(number) or amount or 0)
		if not (amount and math.abs(amount) > 0 and math.abs(amount) >= number) then
			return false, "There aren't enough items in the container!"
		elseif amount < 0 then
			return false, "You cannot take that item out!"
		end
	end
	if filter and action == "put" and not filter[item] then
		return false, "You cannot put that item in!"
	end
	do
		local action = action == "put" and CAN_PUT or CAN_TAKE
		if not( action & io == action) then
			return false,"You cannot do that!"
		end
	end
	if number == 0 then return false, "Invalid amount!" end
	if action == "take" then number = -number end
	return cider.container.update(container,item,number,nil,ply)
end

cider.command.add("container", "b", 2, function(ply, ...)
	-- I use a handler because returning a value is so much neater than a pyramid of ifs.
	local res,msg = containerHandler(ply, ...)
	if res then
		local entity = ply:GetEyeTraceNoCursor().Entity
		local contents,io,filter = cider.container.getContents(entity,ply,true)
		local tab = {
			contents = contents,
			meta = {
				io = io,
				filter = filter, -- Only these can be put in here, if nil then ignore, but empty means nothing.
				size = cider.container.getLimit(entity), -- Max space for the container
				entindex = entity:EntIndex(), -- You'll probably want it for something
				name = cider.container.getName(entity) or "Container"
			}
		}
		datastream.StreamToClients( ply, "cider_Container_Update", tab );
	else
		SendUserMessage("cider_CloseContainerMenu",ply);
	end
	return res,msg
end, "Menu Handlers", "<item> <put|take> <amount>", "Put or take an item from a container", true);

do --isolate vars
	local function conditional(ply,pos)
		return ply:IsValid() and ply:GetPos() == pos;
	end
	local function success(ply,_,class)
		if (not ply:IsValid()) then return end
		ply._Equipping = false;
		local s,f = cider.inventory.update(ply, class, 1);
		if (not s) then
			ply:Emote(GM.Config["Weapon Timers"]["Equip Message"]["Abort"]:format(ply._GenderWord));
			if (f and f ~= "") then
				ply:Notify(f, 1);
			end
			return
		end
		ply:StripWeapon(class);
		GM:Log(EVENT_EVENT, "%s holstered "..ply._GenderWord.." %s.",ply:Name(),GM.Items[class].Name);
		ply:SelectWeapon("cider_hands");
		local weptype = GM.Items[class].WeaponType
		if weptype then
			ply:Emote(GM.Config["Weapon Timers"]["Equip Message"]["Plugh"]:format( weptype, ply._GenderWord ));
		end
	end

	local function failure(ply)
		if (not ply:IsValid()) then return end
		ply:Emote(GM.Config["Weapon Timers"]["Equip Message"]["Abort"]:format(ply._GenderWord));
		ply._Equipping = false;
	end

	-- A command to holster your current weapon.
	cider.command.add("holster", "b", 0, function(ply)
		local weapon = ply:GetActiveWeapon();

		-- Check if they can holster another weapon yet.
		if ( !ply:IsAdmin() and ply._NextHolsterWeapon and ply._NextHolsterWeapon > CurTime() ) then
			return false, "You cannot holster this weapon for "..math.ceil( ply._NextHolsterWeapon - CurTime() ).." second(s)!";
		else
			ply._NextHolsterWeapon = CurTime() + 2;
		end

		-- Check if the weapon is a valid entity.
		if not ( ValidEntity(weapon) and GM.Items[weapon:GetClass()] ) then
			return false, "This is not a valid weapon!";
		end
		local class = weapon:GetClass();
		if not ( gamemode.Call("PlayerCanHolster", ply, class) ) then
			return false
		end

		ply._Equipping = ply:GetPos()
		local delay = GM.Config["Weapon Timers"]["equiptime"][GM.Items[class].WeaponType or -1] or 0
		if not (delay and delay > 0)then
			success(ply,_,class);
			return true
		end
		timer.Conditional(ply:UniqueID().." holster", delay, conditional, success, failure, ply, ply:GetPos(), class);
		ply:Emote(GM.Config["Weapon Timers"]["Equip Message"]["Start"]:format(ply._GenderWord));
	end, "Commands", nil, "Holster your current weapon.");
end

-- A command to drop your current weapon.
cider.command.add("drop", "b", 0, function()
	return false, "Use /holster instead.";
end, "Commands", nil, "Put in for DarkRP players. Do not use.");

-- A command to warrant a player.
cider.command.add("warrant", "b", 1, function(ply, arguments)
	local target = player.Get(arguments[1])

	-- Get the class of the warrant.
	local class = string.lower(arguments[2] or "");

	-- Check if a second argument was specified.
	if (class == "search" or class == "arrest") then
		if (target) then
			if ( target:Alive() ) then
				if (target._Warranted ~= class) then
					if (!target.cider._Arrested) then
						if (CurTime() > target._CannotBeWarranted) then
							if ( hook.Call("PlayerCanWarrant",GAMEMODE, ply, target, class) ) then
								hook.Call("PlayerWarrant",GAMEMODE, ply, target, class);

								-- Warrant the player.
								target:Warrant(class);
							end
						else
							return false, target:Name().." has only just spawned!";
						end
					else
						return false, target:Name().." is already arrested!";
					end
				else
					if (class == "search") then
						return false, target:Name().." is already warranted for a search!";
					elseif (class == "arrest") then
						return false, target:Name().." is already warranted for an arrest!";
					end
				end
			else
				return false, target:Name().." is dead and cannot be warranted!";
			end
		else
			return false, arguments[1].." is not a valid player!"
		end
	else
		return false, "Invalid warrant type. Use 'search' or 'arrest'"
	end
end, "Commands", "<player> <search|arrest>", "Warrant a player.");

-- A command to unwarrant a player.
cider.command.add("unwarrant", "b", 1, function(ply, arguments)
	local target = player.Get(arguments[1])

	-- Check to see if we got a valid target.
	if (target) then
		if (target._Warranted) then
			if ( hook.Call("PlayerCanUnwarrant",GAMEMODE, ply, target) ) then
				hook.Call("PlayerUnwarrant",GAMEMODE, ply, target);

				-- Warrant the player.
				target:UnWarrant();
			end
		else
			return false, target:Name().." does not have a warrant!"
		end
	else
		return false, arguments[1].." is not a valid player!"
	end
end, "Commands", "<player>", "Unwarrant a player.");

do -- Reduce the upvalues poluting the area.
	local function conditional(ply, pos)
		return IsValid(ply) and ply:GetPos() == pos;
	end

	local function success(ply)
		ply:KnockOut();
		GM:Log(EVENT_EVENT, "%s went to sleep.", ply:Name());
		ply._Sleeping = true;
		ply:Emote("slumps to the floor, asleep.");
		ply:SetCSVar(CLASS_LONG, "_GoToSleepTime");
	end

	local function failure(ply)
		ply:SetCSVar(CLASS_LONG, "_GoToSleepTime");
	end
	-- A command to sleep or wake up.
	cider.command.add("sleep", "b", 0, function(ply)
		if (ply._Sleeping and ply:KnockedOut()) then
			return ply:WakeUp();
		end
		timer.Conditional(ply:UniqueID().." sleeping timer", GM.Config["Sleep Waiting Time"], conditional, success, failure, ply, ply:GetPos());
	end, "Commands", nil, "Go to sleep or wake up from sleeping.");
end

cider.command.add("trip", "b", 0, function(ply,arguments)
	if ply:GetVelocity() == Vector(0,0,0) then
		return false,"You must be moving to trip!"
	elseif ply:InVehicle() then
		return false,"There is nothing to trip on in here!";
	end
	ply:KnockOut(5)
	ply._Tripped = true
	cider.chatBox.addInRadius(ply, "me", "trips and falls heavily to the ground.", ply:GetPos(), GM.Config["Talk Radius"]);
	GM:Log(EVENT_EVENT,"%s fell over.",ply:GetName())
end, "Commands", "", "Fall over while walking. (bind key \"say /trip\")");

cider.command.add("fallover", "b", 0, function(ply,arguments)
	if not (ply:KnockedOut() or ply:InVehicle()) then
		ply:KnockOut(5)
		ply._Tripped = true
		cider.chatBox.addInRadius(ply, "me", "slumps to the ground.", ply:GetPos(), GM.Config["Talk Radius"]);
		GM:Log(EVENT_EVENT,"%s fell over.",ply:GetName())
	end
end, "Commands", "", "Fall over.");

-- Commit mutiny.
cider.command.add("mutiny","b",1,function(ply,arguments)
	local target = player.Get( arguments[1] ) or nil
	if not (ValidEntity(target) and target:IsPlayer()) then
		return false, arguments[1].." is not a valid player!"
	end
	local pteam,tteam = ply:Team(),target:Team()
	if 	cider.team.getGroupByTeam(pteam)	~=	cider.team.getGroupByTeam	(tteam)		or
		cider.team.getGang		 (pteam) 	~=	cider.team.getGang			(tteam)		or
		cider.team.getGang		 (tteam)	==	nil										or
		cider.team.getGroupLevel (pteam)	>=	cider.team.getGroupLevel	(tteam)		or
		not										cider.team.hasAccessGroup	(tteam,"D")	then
			return false,"You cannot mutiny against this person"
	end
	target._Depositions = target._Depositions or {}
	if target._Depositions [ply:UniqueID()] then
		return false,"You have already tried to mutiny against your leader!"
	else
		target._Depositions[ply:UniqueID()] = ply
	end
	for ID,ply in pairs(target._Depositions) do
		if ValidEntity(ply) then
			local pteam = ply:Team()
			if 	cider.team.getGroupByTeam(pteam)	~=	cider.team.getGroupByTeam(tteam)	or
				cider.team.getGang		 (pteam) 	~=	cider.team.getGang		 (tteam)	or
				cider.team.getGroupLevel (pteam)	>=	cider.team.getGroupLevel (tteam)	then
					target._Depositions	 [ID]		 =	nil
			end
		else
			target._Depositions[ID] = nil
		end
	end
	local count	= table.Count(target._Depositions)
	local num	=  math.floor( table.Count( cider.team.getGangMembers( cider.team.getGroupByTeam(tteam), cider.team.getGang(tteam) ) ) * GM.Config["Mutiny Percentage"])
	if  num < GM.Config["Minimum to mutiny"] then
		num = GM.Config["Minimum to mutiny"]
	end
	if count < num then
		ply:Notify("Not enough of the gang agrees with you yet to do anything, but they acknowledge your thoughts...")
		GM:Log(EVENT_EVENT,"%s voted to mutiny against %s. %i/%i",ply:Name(),target:Name(),count,num)
		return
	end
	target:Notify("Your gang has overthrown you!",1)
	target:Demote()
	player.NotifyAll("%s was overthrown as leader.",nil,target:Name())
end, "Commands","<player>","Try to start a mutiny against your leader")

-- A command to give Donator status to a player.
cider.command.add("donator", "s", 1, function(ply, arguments)
	local target = player.Get( arguments[1] )

	-- Calculate the days that the player will be given Donator status for.
	local days = math.ceil(tonumber( arguments[2] ) or 30);

	-- Check if we got a valid target.
	if not (target) then
		return false, arguments[1].." is not a valid player!"
	end
		target.cider._Donator = os.time() + (86400 * days);

		-- Give them their access and save their data.
		target:GiveAccess("tpew");
		target:SaveData();

		-- Give them the tool and the physics gun.
		target:Give("gmod_tool");
		target:Give("weapon_physgun");

		-- Set some Donator only player variables.
		target._SpawnTime = target._SpawnTime / 2;
		target._ArrestTime = target._ArrestTime / 2;
		target._KnockOutTime = target._KnockOutTime / 2;

		-- Print a message to all players about this player getting Donator status.
		player.NotifyAll("%s has given Donator status to %s for %i day(s).", nil, ply:Name(), target:Name(), days);
end, "Super Admin Commands", "<player> <days|none>", "Give Donator status to a player.");

cider.command.add("action","b",1,function(ply,arguments)
	local text = table.concat(arguments, " ");

	-- Check if the there is enough text.
	if (text == "") then
		return false,"You did not specify enough text!"
	end
	cider.chatBox.addInRadius(ply, "action", text, ply:GetPos(), GM.Config["Talk Radius"]);
end, "Commands", "<text>", "Add an environmental emote")

cider.command.add("globalaction","m",1,function(ply,arguments)
	local text = table.concat(arguments, " ");

	-- Check if the there is enough text.
	if (text == "") then
		return false,"You did not specify enough text!"
	end
	cider.chatBox.add(nil,ply, "action", text);
end, "Moderator Commands", "<text>","Add a global environmental emote")

-- Set an ent's master
cider.command.add("setmaster","s",1,function(ply, masterID)
	local entity = ply:GetEyeTraceNoCursor().Entity
	local master = Entity(masterID)
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity)) then
		return false,"That is not a valid entity!"
	elseif not ((ValidEntity(master) and cider.entity.isOwnable(master)) or masterID == 0) then
		return false,"That is not a valid entity ID!"
	end
	if masterID == 0 then
		master = NULL
		GM:Log(EVENT_ENTITY, "%s unset a %s's master",ply:Name(),entity._isDoor and "door" or entity:GetNWString("Name","entity"))
	else
		GM:Log(EVENT_ENTITY, "%s set a %s's master",ply:Name(),entity._isDoor and "door" or entity:GetNWString("Name","entity"))
	end
	cider.entity.setMaster(entity,master)
	hook.Call("EntityMasterSet",GAMEMODE,entity,master)
end, "Super Admin Commands", "<ID of master|0>", "Set/Unset an ent's master",true)

-- Seal a door
cider.command.add("seal","s",0,function(ply,unseal)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity)) then
		return false,"That is not a valid entity!"
	end
	if unseal then
		entity._Sealed = false

		if (entity:GetDTInt(3) & OBJ_SEALED == OBJ_SEALED) then
			entity:SetDTInt(3, entity:GetDTInt(3) -  OBJ_SEALED);
		end
		hook.Call("EntitySealed",GAMEMODE,entity,true)
		GM:Log(EVENT_ENTITY, "%s unsealed a %s,",ply:Name(),entity._isDoor and "door" or entity:GetNWString("Name","entity"))
	else
		entity._Sealed = true
		if (entity:GetDTInt(3) & OBJ_SEALED ~= OBJ_SEALED) then
			entity:SetDTInt(3, entity:GetDTInt(3) +  OBJ_SEALED);
		end
		hook.Call("EntitySealed",GAMEMODE,entity)
		GM:Log(EVENT_ENTITY, "%s sealed a %s,",ply:Name(),entity._isDoor and "door" or entity:GetNWString("Name","entity"))
	end
end, "Super Admin Commands", "[unseal]", "Seal/Unseal an entity so it cannot be used",true)

cider.command.add("setname","s",1,function(ply,arguments)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity) and entity._isDoor) then
		return false,"That is not a valid door!"
	end
	local words = table.concat(arguments," "):Trim():sub(1,25)
	if not words or words == "" then
		words = ""
	end
	entity:SetNWString("Name",words)
	GM:Log(EVENT_ENTITY, "%s changed a door's name to %q.",ply:Name(),words)
	hook.Call("EntityNameSet",GAMEMODE,entity,words)
end, "Super Admin Commands", "<name>", "Set the name of a door")

cider.command.add("setowner","s",1,function(ply,kind,id,gangid)
	local entity = ply:GetEyeTraceNoCursor().Entity
	if not (ValidEntity(entity) and cider.entity.isOwnable(entity) and entity._isDoor) then
		return false,"That is not a valid door!"
	end
	entity = cider.entity.getMaster(entity) or entity
	local target
	local name
	if kind == "player" then
		target = player.Get(id)
		if not target then return false, "Invalid player specified!" end
		cider.entity.setOwnerPlayer(entity,target)
		name = target:Name()
	elseif kind == "team" then
		target = cider.team.get(id)
		if not target then return false, "Invalid team specified!" end
		name = target.name
		target = target.index
		cider.entity.setOwnerTeam(entity,target)
	elseif kind == "gang" and gangid then
		print("gange")
		id = tonumber(id);
		gangid = tonumber(gangid);
		if not (cider.team.gangs[id] and cider.team.gangs[id][gangid]) then
			return false,"Invalid gang"
		end
		cider.entity.setOwnerGang(entity,id,gangid)
		name = cider.team.gangs[id][gangid][1]
		target = {id,gangid};
	elseif kind == "remove" then
		cider.entity.clearData(entity,true)
		target = ""
	end
	if not target then
		return false, "Invalid target!"
	end
	cider.entity.updateSlaves(entity)
	hook.Call("EntityOwnerSet",GAMEMODE,entity,kind,target)
	GM:Log(EVENT_ENTITY, "%s gave ownership of %s to %s.",ply:Name(),entity._isDoor and "door" or entity:GetNWString("Name","entity"),name)
end, "Super Admin Commands", "<player|team|gang|remove> [identifier] [gang identifier]", "Set the owner of a door",true)
]]
