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

								--GM:Log(EVENT_COMMAND,"%s used 'arista %s%s'.",player:Name(),command,text)
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
