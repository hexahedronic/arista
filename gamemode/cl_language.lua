arista.lang = {}

arista.lang.currency = "£"
arista.lang.selected = "EN"

-- Don't edit EN or I will rip your throat out. If you want to
-- translate it MAKE A NEW TABLE FOR IT AND SET THE DEFAULT TO IT.

arista.lang.tbl = {}

arista.lang.tbl.EN = {
	-- MISC
	["AL_FUCK"] = "FUCK!",
	["AL_WAT"] = "wat",

	["AL_SECONDS"] = "second(s)",
	["AL_MINS"] = "minute(s)",
	["AL_HOURS"] = "hour(s)",
	["AL_DAYS"] = "day(s)",

	["AL_ITEM"] = "item",
	["AL_PICKUP"] = "pickup",
	["AL_UNTIE"] = "untie",

	["AL_TEAMS"] = "Teams",
	["AL_GROUPS"] = "Groups",

	["AL_YES"] = "Yes",
	["AL_NO"] = "No",
	["AL_MALE"] = "Male",
	["AL_FEMALE"] = "Female",

	["AL_BLACKLISTDETAILS"] = "Blacklist details have been printed to your console.",
	["AL_GOT_SECONDHAND"] = "You got " .. arista.lang.currency .. "%d for selling your %s secondhand.",

	["AL_A"] = "A ",
	["AL_A_BUTTON"] = "A Button",

	["AL_DROP_THAT"] = "drop that",
	["AL_DESTROY_THAT"] = "destroy that",

	["AL_STATE_ARRESTED"] = "(Arrested)",
	["AL_STATE_TIED"] = "(Tied)",
	["AL_STATE_SEARCH"] = "(Search Warrant)",
	["AL_STATE_ARREST"] = "(Arrest Warrant)",

	-- SPECIFIC THINGS
	["AL_DOOR_SALE"] = "For Sale - Press F2",

	-- GENERAL FORUMLAE
	["AL_X_PLUS_X_TO_X"] = "'%s' + '%s' to %s.",
	["AL_X_TO_X"] = "'%s' to %s.",
	["AL_SIZE_X"] = "Size: %s",
	["AL_X_SALARY"] = "You received " .. arista.lang.currency .. "%d salary.",
	["AL_X_CANNOT_USE_X"] = "%ss cannot use %s!",
	["AL_X_CORPSE"] = "'s corpse",
	["AL_X_DEAD"] = " (dead)",
	["AL_CANNOT_X_MAX"] = "You've hit the %s limit!",
	["AL_CANNOT_X_ENCUMBERED"] = "You cannot %s, you will be over encumbered!",
	["AL_X_CANNOT_MANUFACTURE_X"] = "%ss cannot manufacture %s.",
	["AL_X_UNBLACKLIST_X_FROM_X"] = "%s unblacklisted %s from using %s.",
	["AL_X_BLACKLIST_X_FROM_X_FOR_X_BECAUSE_X"] = "%s blacklisted %s from using %s for %s %s for %q",
	["AL_X_IS_ALREADY_BLACKLISTED"] = "%s is already blacklisted from that!",
	["AL_X_NOT_BLACKLISTED_ANYTHING"] = "%s isn't blacklisted from anything!",
	["AL_X_GIVE_X_DONATOR_X_DAYS"] = "%s has given Donator status to %s for %i day(s).",
	["AL_X_ISNT_BLACKLISTABLE"] = "%s isn't blacklistable!",

	-- PLAYER CANNOT PERFORM ACTION
	["AL_CANNOT_GENERIC"] = "You cannot do that to this!",
	["AL_CANNOT_INVALID"] = "You cannot do that in this state!",
	["AL_CANNOT_NOACCESS"] = "You do not have access to that!",
	["AL_CANNOT_TALK"] = "You cannot talk in this state!",
	["AL_CANNOT_RAM"] = "You cannot ram this door!",
	["AL_CANNOT_RAM_NOAUTH"] = "You do not have the authority to ram this door.",
	["AL_CANNOT_HOLSTER"] = "You cannot holster this weapon!",
	["AL_CANNOT_NOREASON"] = "You must specify a reason!",
	["AL_CANNOT_NOTENOUGHTEXT"] = "You did not specify enough text!",

	["AL_CANNOT_DROPMONEY_FAST"] = "You need to wait another %d seconds before dropping more money.",

	["AL_CANNOT_BLACKLIST_LONG"] = "You cannot blacklist for that long!",
	["AL_CANNOT_BLACKLIST_SHORT"] = "You cannot blacklist for less than 1 minute!",

	["AL_CANNOT_USE_ITEM"] = "You cannot use another item for %d more seconds!",
	["AL_CANNOT_USE_ITEM_SPECIFIC"] = "You cannot use another %s for %d more seconds!",
	["AL_CANNOT_USE_ITEM_VEHICLE"] = "You cannot use that item while in a vehicle!",

	["AL_CANNOT_JOIN_SAME"] = "You are already in that team!",
	["AL_CANNOT_JOIN_FULL"] = "That team is full.",

	["AL_CANNOT_GENDER_SAME"] = "You are already %s!",

	["AL_CANNOT_TIE"] = "You must look at a player to tie them up!",

	["AL_CANNOT_MANUFACTURE"] = "You cannot manufacture another item for %s seconds(s)!",

	["AL_CANNOT_DOOR_OWNED"] = "This door is already owned!",
	["AL_CANNOT_DOOR_UNSELLABLE"] = "You cannot sell this door.",

	["AL_CANNOT_CONTAINER_NOITEMS"] = "There aren't enough items in the container!",
	["AL_CANNOT_CONTAINER_TAKE"] = "You cannot take that item out!",
	["AL_CANNOT_CONTAINER_PUT"] = "You cannot put that item in!",
	["AL_CANNOT_CONTAINER_USE"] = "You cannot use that container!",

	["AL_CANNOT_PM_SELF"] = "You can't PM yourself.",

	["AL_CANNOT_ADVERT"] = "You must wait %d %s before using advert again!",

	["AL_CANNOT_SPAWN_CAR"] = "You must buy your car from the store!",

	["AL_CANNOT_OOC_COOLDOWN"] = "You must wait %d %s before using OOC again!",

	["AL_CANNOT_TEAM_WARRANTED"] = "You cannot change teams while warranted!",
	["AL_CANNOT_TEAM_ARRESTED"] = "You cannot change teams while arrested!",
	["AL_CANNOT_TEAM_TIED"] = "You cannot change teams while tied up!",
	["AL_CANNOT_TEAM_BASE"] = "You can only change groups via the base classes!",
	["AL_CANNOT_TEAM_GROUP"] = "You cannot go straight to this group!",
	["AL_CANNOT_TEAM_GANGBASE"] = "You can only change gangs via the base class!",
	["AL_CANNOT_TEAM_GENERIC"] = "You cannot join that team!",

	["AL_CANNOT_DEMOTE_DEFAULT"] = "You cannot demote players from the default team!",
	["AL_CANNOT_DEMOTE_GENERIC"] = "You cannot demote %s right now!",
	["AL_CANNOT_DEMOTE_GROUP"] = "You cannot demote players in a different group!",
	["AL_CANNOT_DEMOTE_BASE"] = "You cannot demote a player from the base class!",
	["AL_CANNOT_DEMOTE_HIGHER"] = "You cannot demote a player with a higer level than you!",
	["AL_CANNOT_DEMOTE_SAME"] = "You do not have access to demote players at the same level as yourself!",
	["AL_CANNOT_DEMOTE_NOACCESS"] = "You do not have access to demote this player!",
	["AL_CANNOT_DEMOTE_GANG"] = "You cannot demote players in other gangs!",

	["AL_CANNOT_CONTAINER_FIT"] = "Cannot fit that item in!",

	["AL_CANNOT_LAWS_CHANGE"] = "You may not change the laws.",

	["AL_CANNOT_HOLSTER"] = "You cannot holster this weapon for %d second(s)!",
	["AL_CANNOT_NOAMMO"] = "You don't have enough ammunition for this weapon!",

	-- INVALID OBJECT
	["AL_INVALID_ACTION"] = "Invalid action specified!",
	["AL_INVALID_ITEM"] = "This is not a valid item!",
	["AL_INVALID_CATEGORY"] = "This is not a valid category!",
	["AL_INVALID_AMOUNT"] = "Invalid amount!",
	["AL_INVALID_TEAM"] = "Invalid team!",
	["AL_INVALID_GENDER"] = "That is not a valid gender!",
	["AL_INVALID_DOOR"] = "This is not a valid door!",
	["AL_INVALID_ENTITY"] = "This is not a valid entity!",
	["AL_INVALID_NAME"] = "Choose a different name.",
	["AL_INVALID_TARGET"] = "Invalid target!",
	["AL_INVALID_MESSAGE"] = "You must specify a message!",
	["AL_INVALID_MODEL"] = "That's not a valid model!",
	["AL_INVALID_CONTAINER"] = "That's not a valid container!",
	["AL_INVALID_GANG"] = "That's not a valid gang!",
	["AL_INVALID_COMMAND"] = "That's not a command!",
	["AL_INVALID_BLACKLIST"] = "That is not a valid blacklist type! (Valid: team/item/cat/cmd)",
	["AL_INVALID_WEAPON"]= "That is not a valid weapon!",

	-- PLAYER PERFORMED ACTION
	["AL_YOU_MANUFACTURED"] = "You manufactured %s.",
	["AL_YOU_PURCHASE"] = "Purchase this for " .. arista.lang.currency .. "%d?",

	["AL_YOU_ARRESTED"] = "You are arrested.",
	["AL_YOU_TIED"] = "You have been tied up!",
	["AL_YOU_KEVLAR"] = "You are wearing kevlar which reduces damage by 50%%.",
	["AL_YOU_WAKEUP"] = "Press '%s' to wake up!",
	["AL_YOU_GETUP"] = "Press '%s' to get up!",

	["AL_YOU_CHANGE_GENDER"] = "You will be %s next time you spawn.",
	["AL_YOU_CHANGE_JOB"] = "You have changed your job title to '%s'.",
	["AL_YOU_CHANGE_DETAILS"] = "You have changed your details to '%s'.",
	["AL_YOU_CHANGE_CLAN"] = "You have changed your details to '%s'.",

	["AL_YOU_REMOVE_DETAILS"] = "You have removed your details.",
	["AL_YOU_REMOVE_CLAN"] = "You have left your clan.",

	["AL_YOU_NOT_ENOUGHMONEY"] = "You do not have enough money!",
	["AL_YOU_NOT_DROPENOUGH"] = "You cannot drop less than " .. arista.lang.currency .. "%d.",

	["AL_YOU_SEARCH_WARRANT"] = "You have a search warrant which expires in %d %s.",
	["AL_YOU_ARREST_WARRANT"] = "You have an arrest warrant which expires in %d %s.",

	["AL_YOU_UNARRESTED_IN"] = "You will be unarrested in %d %s.",
	["AL_YOU_UNARRESTED"] = "Your arrest time has finished!",

	["AL_YOU_TEAM_NAME"] = "Your team's member",

	["AL_YOU_FINISH_KNOTS"] = "You will finish the knots in %s second(s).",
	["AL_YOU_FINISH_TIED"] = "You are being tied up!",

	["AL_YOU_WAIT_SPAWN"] = "You must wait %s second(s) to spawn.",
	["AL_YOU_WAIT_GETUP"] = "You must wait %s second(s) to get up.",
	["AL_YOU_WAIT_SLEEP"] = "You will fall asleep in %s second(s).",
	["AL_YOU_WAIT_TEAM"] = "You must wait %s before you can become a %s!",
	["AL_YOU_WAIT_TIMELIMIT"] = "You have reached the timelimit for this job!",
	["AL_YOU_WAIT_LAWS"] = "You must wait another %d minute(s) to update the laws!",

	["AL_YOU_PROP_LIMIT"] = "You have hit the prop limit!",
	["AL_YOU_PROP_BANNED"] = "You cannot spawn banned props!",
	["AL_YOU_PROP_TOOBIG"] = "That prop is too big!",
	["AL_YOU_PROP_TOOFAST"] = "You cannot spawn another prop for %d second(s)!",

	["AL_YOU_DONATOR_REMOVE"] = "Your Donator status has expired!",
	["AL_YOU_DONATOR_EXPIRE_DAYS"] = "Your Donator status expires in %d day(s).",
	["AL_YOU_DONATOR_EXPIRE_HOURS"] = "Your Donator status expires in %d hour(s) %d minute(s) and %d second(s).",

	["AL_YOU_DOOR_REFUND"] = "You got " .. arista.lang.currency .. "%d for selling your door.",

	-- DERMA BUTTONS AND SUCH
	["AL_DERMA_MANUFACTURE"] = "Manufacture",
	["AL_DERMA_GIVE"] = "Give",
	["AL_DERMA_CHOICES"] = "Choices",
	["AL_DERMA_TAKE"] = "Take",
	["AL_DERMA_ACCESSLIST"] = "Access List",
	["AL_DERMA_PLAYERS"] = "Players",
	["AL_DERMA_JOBS"] = "Jobs",
	["AL_DERMA_GANGS"] = "Gangs",
	["AL_DERMA_GENDER"] = "Gender",
	["AL_DERMA_SETNAME"] = "Set Name",
	["AL_DERMA_CLOSE"] = "Close",
	["AL_DERMA_SELL"] = "Sell",
	["AL_DERMA_JOB"] = "Job",
	["AL_DERMA_DETAILS"] = "Details",
	["AL_DERMA_CHANGE"] = "Change",
	["AL_DERMA_CLAN"] = "Clan",
	["AL_DERMA_BECOME"] = "Become",
	["AL_DERMA_JOINED"] = "Joined",
	["AL_DERMA_WAIT"] = "Wait",
	["AL_DERMA_FULL"] = "Full",
	["AL_DERMA_MAINMENU"] = "Main Menu",
	["AL_DERMA_CHARACTER"] = "Character",
	["AL_DERMA_INVENTORY"] = "Inventory",
	["AL_DERMA_STORE"] = "Store",
	["AL_DERMA_ALL"] = "All",
	["AL_DERMA_AMOUNT"] = "Amount",
	["AL_DERMA_USE"] = "Use",
	["AL_DERMA_DROP"] = "Drop",
	["AL_DERMA_PICKUP"] = "Pickup",
	["AL_DERMA_DESTROYALL"] = "Destroy All",
	["AL_DERMA_PUT"] = "Put",
	["AL_DERMA_TAKE"] = "Take",
	["AL_DERMA_CONTAINER"] = "Container",
	["AL_DERMA_YOUR_INVENTORY"] = "Your Inventory",
	["AL_DERMA_CONT_INVENTORY"] = "Container Inventory",
	["AL_DERMA_CREDITS"] = "Credits",
	["AL_DERMA_EDIT"] = "Edit",
	["AL_DERMA_EDITLAWS"] = "Edit the City Laws",
	["AL_DERMA_SAVE"] = "Save",
	["AL_DERMA_LAWS"] = "Laws",
	["AL_DERMA_HELP"] = "Help",
	["AL_DERMA_NAME"] = "Name",

	-- HUD ELEMENTS
	["AL_HUD_RPNAME"] = "Name: ",
	["AL_HUD_JOB"] = "Job: ",
	["AL_HUD_GENDER"] = "Gender: ",
	["AL_HUD_DETAILS"] = "Details: ",
	["AL_HUD_CLAN"] = "Clan: ",
	["AL_HUD_MONEY"] = "Balance: " .. arista.lang.currency,
	["AL_HUD_SALARY"] = "Salary: " .. arista.lang.currency,
	["AL_HUD_NAME"] = "Name: ",
	["AL_HUD_NODESC"] = "No Description",
	["AL_HUD_SPACEUSED"] = "Space Used: ",

	["AL_HUD_HEALTH"] = "Health: ",
	["AL_HUD_AMMO"] = "Ammo: ",
	["AL_HUD_TIMELEFT"] = "Time Left: ",

	-- ANOTHER PLAYER
	["AL_PLAYER_NO_WARRANT"] = "%s does not have an arrest warrant!",
	["AL_PLAYER_GIVEACCESS"] = "%s gave %s access to the %q flag%s",
	["AL_PLAYER_TAKEACCESS"] = "%s took %s's access to the %q flag%s",
	["AL_PLAYER_UPDATELAWS"] = "%s just updated the city laws.",
	["AL_PLAYER_NOTBLACKLISTED"] = "%s is not blacklisted from that!",
	["AL_PLAYER_YOU_GAVE"] = "You gave %s " .. arista.lang.currency .. "%s.",
	["AL_PLAYER_GAVE_YOU"] = "%s gave you " .. arista.lang.currency .. "%s.",
	["AL_PLAYER_DEMOTED"] = "%s demoted %s from %s for %q.",

	-- DONT HAVE ENOUGH / NEED MORE
	["AL_NEED_ANOTHER_MONEY"] = "You need another " .. arista.lang.currency .. "%d!",

	["AL_DONT_HAVE_AMOUNT"] = "You don't have that many %s!",
	["AL_DONT_HAVE_ITEMS"] = "You do not have enough items!",
	["AL_DONT_OWN_ITEM"] = "You do not own any %s!",

	-- COMMANDS
	["AL_COMMAND_CAT_MENU"] = "Menu Handlers",

	["AL_COMMAND_TEAM"] = "Change your team.",
	["AL_COMMAND_TEAM_HELP"] = "<team>",

	["AL_COMMAND_INVENTORY"] = "Perform an inventory action on an item.",
	["AL_COMMAND_INVENTORY_HELP"] = "<item> <destroy|drop|use> [amount]",

	["AL_COMMAND_MANUFACTURE"] = "Manufacture an item from the store.",
	["AL_COMMAND_MANUFACTURE_HELP"] = "<item>",

	["AL_COMMAND_GENDER"] = "Change your gender.",
	["AL_COMMAND_GENDER_HELP"] = "<male|female>",

	["AL_COMMAND_DOOR"] = "Perform an action on a door you're looking at.",
	["AL_COMMAND_DOOR_HELP"] = "<purchase|sell>",

	["AL_COMMAND_ENTITY"] = "Perform an action on the entity you're looking at.",
	["AL_COMMAND_ENTITY_HELP"] = "<give|take> <ID> <type> or <name> <mynamehere>",

	["AL_COMMAND_CONTAINER"] = "Put or take an item into/from a container.",
	["AL_COMMAND_CONTAINER_HELP"] = "<item> <put|take> <amount>",


	["AL_COMMAND_CAT_COMMANDS"] = "Commands",

	["AL_COMMAND_JOB"] = "Change your job title or reset it.",
	["AL_COMMAND_JOB_HELP"] = "[text]",

	["AL_COMMAND_FUCK"] = "Free gratuitous swearing.",
	["AL_COMMAND_FUCK_HELP"] = "",

	["AL_COMMAND_CLAN"] = "Change your clan or quit your current one.",
	["AL_COMMAND_CLAN_HELP"] = "[text|quit|none]",

	["AL_COMMAND_NAME"] = "Change your rp-name.",
	["AL_COMMAND_NAME_HELP"] = "[text|random|default]",

	["AL_COMMAND_DETAILS"] = "Change your details or make them blank.",
	["AL_COMMAND_DETAILS_HELP"] = "[text|none]",

	["AL_COMMAND_PM"] = "Send an OOC private messsage to a player.",
	["AL_COMMAND_PM_HELP"] = "<player> <text>",

	["AL_COMMAND_Y"] = "Yell to players near you.",
	["AL_COMMAND_Y_HELP"] = "<text>",

	["AL_COMMAND_W"] = "Whisper to players near you.",
	["AL_COMMAND_W_HELP"] = "<text>",

	["AL_COMMAND_ME"] = "Emote; e.g: <your name> cries a river.",
	["AL_COMMAND_ME_HELP"] = "<text>",

	["AL_COMMAND_ADVERT"] = "Send an advert to all players (" .. arista.lang.currency .. arista.config.costs.advert .. ").",
	["AL_COMMAND_ADVERT_HELP"] = "<text>",

	["AL_COMMAND_RADIO"] = "Send a message to all players on your team.",
	["AL_COMMAND_RADIO_HELP"] = "<text>",

	["AL_COMMAND_OOC"] = "Say something out of character to everyone. (shortcut: //<text>)",
	["AL_COMMAND_OOC_HELP"] = "<text>",

	["AL_COMMAND_LOOC"] = "Say something out of character to the people around you. (shortcut: .//<text>)",
	["AL_COMMAND_LOOC_HELP"] = "<text>",

	["AL_COMMAND_A"] = "Say something to the other admins.",
	["AL_COMMAND_A_HELP"] = "<text>",

	["AL_COMMAND_M"] = "Say something to the other mods and admins.",
	["AL_COMMAND_M_HELP"] = "<text>",

	["AL_COMMAND_ACTION"] = "Add an environmental emote.",
	["AL_COMMAND_ACTION_HELP"] = "<text>",

	["AL_COMMAND_DROPMONEY"] = "Drop some money where you are looking.",
	["AL_COMMAND_DROPMONEY_HELP"] = "<amount>",

	["AL_COMMAND_DEMOTE"] = "Demote a player from their current team",
	["AL_COMMAND_DEMOTE_HELP"] = "<player> <reason>",

	["AL_COMMAND_HOLSTER"] = "Holster your current weapon.",
	["AL_COMMAND_HOLSTER_HELP"] = "",

	["AL_COMMAND_REQUEST"] = "Request assistance from the government.",
	["AL_COMMAND_REQUEST_HELP"] = "<text>",

	["AL_COMMAND_LOCKDOWN"] = "Request or initiate a lockdown.",
	["AL_COMMAND_LOCKDOWN_HELP"] = "",

	["AL_COMMAND_UNLOCKDOWN"] = "Request the end of or end the current lockdown.",
	["AL_COMMAND_UNLOCKDOWN_HELP"] = "",

	["AL_COMMAND_DROP"] = "Put in for DarkRP players, do not use.",
	["AL_COMMAND_DROP_HELP"] = "",

	["AL_COMMAND_WARRANT"] = "Warrant a player.",
	["AL_COMMAND_WARRANT_HELP"] = "<player> <search|arrest>",

	["AL_COMMAND_UNWARRANT"] = "Unwarrant a player.",
	["AL_COMMAND_UNWARRANT_HELP"] = "<player>",

	["AL_COMMAND_GIVEMONEY"] = "Give the player you are looking at money.",
	["AL_COMMAND_GIVEMONEY_HELP"] = "<amount>",

	["AL_COMMAND_SLEEP"] = "Go to sleep or wake up from sleeping.",
	["AL_COMMAND_SLEEP_HELP"] = "",

	["AL_COMMAND_TRIP"] = "Fall over whilst walking.",
	["AL_COMMAND_TRIP_HELP"] = "",

	["AL_COMMAND_FALLOVER"] = "Fall over.",
	["AL_COMMAND_FALLOVER_HELP"] = "",

	["AL_COMMAND_MUTINY"] = "Try to start a mutiny against your leader.",
	["AL_COMMAND_MUTINY_HELP"] = "<leader>",


	["AL_COMMAND_CAT_ADMIN"] = "Admin Commands",

	["AL_COMMAND_GIVEACCESS"] = "Give access to a player.",
	["AL_COMMAND_GIVEACCESS_HELP"] = "<player> <access>",

	["AL_COMMAND_TAKEACCESS"] = "Take access from a player.",
	["AL_COMMAND_TAKEACCESS_HELP"] = "<player> <access>",

	["AL_COMMAND_RESTARTMAP"] = "Restart the map immediately.",
	["AL_COMMAND_RESTARTMAP_HELP"] = "",


	["AL_COMMAND_CAT_MOD"] = "Moderator Commands",

	["AL_COMMAND_BLACKLIST"] = "Blacklist a player from something.",
	["AL_COMMAND_BLACKLIST_HELP"] = "<player> <team|item|cat|cmd> <thing> <time> <reason>",

	["AL_COMMAND_UNBLACKLIST"] = "Unblacklist a player from something.",
	["AL_COMMAND_UNBLACKLIST_HELP"] = "<player> <team|item|cat|cmd> <thing>",

	["AL_COMMAND_BLACKLISTLIST"] = "Print a player's blacklist to your console.",
	["AL_COMMAND_BLACKLISTLIST_HELP"] = "<player>",

	["AL_COMMAND_GLOBALACTION"] = "Add a global environmental emote.",
	["AL_COMMAND_GLOBALACTION_HELP"] = "<text>",


	["AL_COMMAND_CAT_SADMIN"] = "Super Admin Commands",

	["AL_COMMAND_SETMASTER"] = "Set/Unset an ent's master.",
	["AL_COMMAND_SETMASTER_HELP"] = "<masterID>",

	["AL_COMMAND_SEAL"] = "Seal/Unseal an entity so it cannot be used.",
	["AL_COMMAND_SEAL_HELP"] = "[unseal]",

	["AL_COMMAND_SETNAME"] = "Set the name of a door.",
	["AL_COMMAND_SETNAME_HELP"] = "<name>",

	["AL_COMMAND_SETNAME"] = "Set the owner of a door.",
	["AL_COMMAND_SETNAME_HELP"] = "<player|team|gang|remove> [identifier] [gang identifier]",

	["AL_COMMAND_DONATOR"] = "Give Donator status to a player.",
	["AL_COMMAND_DONATOR_HELP"] = "<player> [days]",

	["AL_COMMAND_SAVE"] = "Forceably save all profiles",
	["AL_COMMAND_SAVE_HELP"] = "",

	["AL_COMMAND_SETOWNER"] = "Set an entity's owner.",
	["AL_COMMAND_SETOWNER_HELP"] = "<kind> <id> [gang]",

	["AL_COMMAND_FIRESPREAD"] = "Enables/disables fire spreading.",
	["AL_COMMAND_FIRESPREAD_HELP"] = "<enable>",

	["AL_COMMAND_FIRESPREAD_ENABLE"] = "Fire spreading enabled.",
	["AL_COMMAND_FIRESPREAD_DISABLE"] = "Fire spreading disabled.",

	-- BACKWARDS COMPAT
	["AL_METHOD_UNSUPORTED"] = "This method is no longer supported.",
}

local missing = {}
function arista.lang.findMissingLocalization()
	arista.logs.log(arista.logs.E.LOG, "Now printing detected missing localization strings:")
	arista.logs.logNoPrefix(arista.logs.E.LOG, "Missing from other langs:")
	for l, s in pairs(arista.lang.tbl.EN) do
		for k, v in pairs(arista.lang.tbl) do
			if not v[l] then
				print(k .. " = ", l)
			end
		end
	end

	arista.logs.logNoPrefix(arista.logs.E.LOG, "Missing calls:")
	for i, v in ipairs(missing) do
		print("\n-", v.s)
		print(v.t)
	end
end

function arista.lang:Get(str, ...)
	local str = str or ""

	--do if str:StartWith("AL_HUD") then return "cyka: " else return "cyka" end end
	local lang = self.selected or "EN"

	lang = self.tbl[lang]
	local form = lang[str]

	if not form then
		form = str
		if form:StartWith("AL_") then missing[#missing+1] = {s = form, t = debug.traceback()} end
	end

	form = form:format(...)

	return form or ""
end

-- For plugins to add their own translations
function arista.lang:Add(str, tbl)
	for lang, trans in pairs(tbl) do
		if self.tbl[lang] then
			if not self.tbl[lang][str] then self.tbl[lang][str] = trans end
		end
	end
end

if GetConVar("developer"):GetInt() > 0 then
	concommand.Add("arista_lang_find_missing", function()
		arista.lang.findMissingLocalization()
	end)
end
