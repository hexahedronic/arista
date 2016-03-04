arista.command = {}
arista.command.stored = {}

-- Add a new command.
function arista.command.add(command, access, arguments, callback, category, help, tip, unpack)
	arista.command.stored[command] = {access = access, arguments = arguments, callback = callback, unpack = tobool(unpack)}

	-- Check to see if a category was specified.
	if category then
		if not help or help == "" then
			--arista.help.add(category, GM.Config["Command Prefix"]..command.." <none>.", tip)
		else
			--arista.help.add(category, GM.Config["Command Prefix"]..command.." "..help..".", tip)
			-- todo: help menu
		end
	end
end

-- This is called when a player runs a command from the console.
function arista.command.consoleCommand(player, _, arguments)
	if not player._inited then return end

	if arguments and arguments[1] then
		local command = table.remove(arguments, 1):lower()

		-- Check to see if the command exists.
		if arista.command.stored[command] then

			-- Loop through the arguments and fix Valve's errors.
			for k, v in ipairs(arguments) do
				arguments[k] = arguments[k]:gsub(" ' ", "'")
				arguments[k] = arguments[k]:gsub(" : ", ":")
			end

			-- Check if the player can use this command.
			if gamemode.Call("PlayerCanUseCommand", player, command, arguments) then
				if #arguments >= arista.command.stored[command].arguments then
					if player:hasAccess(arista.command.stored[command].access) then
						-- Some callbacks remove arguments from the table, and we don't want to lose them )
						local success, fail, msg

						if arista.command.stored[command].unpack then
							success, fail, msg = pcall(arista.command.stored[command].callback, player, unpack(arguments))
						else
							success, fail, msg = pcall(arista.command.stored[command].callback, player, table.Copy(arguments))
						end

						local concat = table.concat(arguments, " "):Trim()

						if success then
							if fail ~= false then
								local text = ""

								if concat ~= "" then
									text = text .. " " .. concat
								end

								arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, player:Name(), "(", player:SteamID(), ") used command ", command, ".")
							else
								if msg and msg ~= "" then
									player:notify(msg)
								end
							end
						else
							ErrorNoHalt(os.date() .. " callback for 'arista " .. command .. " " .. concat .. "' failed: " .. fail .. "\n")
						end
					else
						player:notify("You do not have access to this command, %s.", player:Name())
					end
				else
					player:notify("This command requires %d arguments!", arista.command.stored[command].arguments)
				end
			end
		else
			player:notify("This is not a valid command!")
		end
	else
		player:notify("This is not a valid command!")
	end
end

-- Add a new console command.
concommand.Add("arista", arista.command.consoleCommand)

-- Called when a player says something.
function GM:PlayerSay(ply, text, public)
	-- todo: fix
	--print(ply, text,text:sub(-7), public)
	-- This is a terrible solution. OH WELL LOL
	--if (text:sub(-7) == '" "0.00') then
	--	text = text:sub(1,-8);
		--print(text)
	--end

	local prefix = arista.config.vars.commandPrefix or "/"

	-- Fix Valve's errors. DODO: srsly?
	text = text:gsub(" ' ", "'"):gsub(" : ", ":"):Trim()

	-- The OOC commands have shortcuts.
	if text:sub(1, 2) == "//" then
		text = text:sub(3):Trim()

		if text == "" then
			return ""
		end

		text = prefix .. "ooc " .. text
	elseif text:sub(1, 3) == ".//" then
		text = text:sub(4):Trim()

		if text == "" then
			return ""
		end

		text = prefix .. "looc " .. text
	end

	if text[1] == prefix then
		--TODO: Rewrite with gmatch chunks

		text = text:sub(2)

		local args = text:Split(" ")
		local j, tab, quote = 1, {}, false

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
				text = text:sub(1, -2)
			end

			tab[j] = tab[j] .. text

			if not quote then
				j = j + 1
			end
		end

		arista.command.consoleCommand(ply, _, tab)

		return ""
	else
		--[[if ( gamemode.Call("PlayerCanSayIC", ply, text) ) then
			if (ply:Arrested()) then
				cider.chatBox.addInRadius(ply, "arrested", text, ply:GetPos(), self.Config["Talk Radius"])
			elseif ply:Tied() then
				cider.chatBox.addInRadius(ply, "tied", text, ply:GetPos(), self.Config["Talk Radius"])
			else
				cider.chatBox.addInRadius(ply, "ic", text, ply:GetPos(), self.Config["Talk Radius"])
			end
			GM:Log(EVENT_TALKING,"%s: %s",ply:Name(),text)
		end]]
		-- todo: chat
	end

	-- Return an empty string so the text doesn't show.
	--return ""
	-- todo: chat
	return text
end
