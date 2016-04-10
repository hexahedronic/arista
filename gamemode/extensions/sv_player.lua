arista.player = {}

---
-- Notifies every player on the server that has the specified access.
-- @param access The access string to search for
-- @param message The message format to display
function arista.player.notifyByAccess(access, message, ...)
	for _, ply in pairs(player.GetAll()) do
		if ply:hasAccess(access) then
			ply:notify(message, ...)
		end
	end
end

---
-- Removes a players donator status.
-- @param player The player to remove donator from
function arista.player.expireDonator(ply)
	ply:setAristaVar("donator", 0)

	-- Take away their access and save their data.
	ply:setupDonator(false)
	ply:saveData()

	-- Notify the player about how their Donator status has expired.
	ply:notify("AL_YOU_DONATOR_REMOVE")

	gamemode.Call("PlayerAdjustSalary", ply)
end

---
-- Notifies every player on the server and logs a public event
-- @see GM:Log
-- @param message The message to display. (Use same form as GM:Log)
-- @param level The notification level. Nil or unspecified = chat message. 0 = Water drip. 1 = Failure buzzer. 2 = 'Bip' Notification. 3 = 'Tic' Notification. (Used by the cleanup)
-- @param ... A series of strings to be applied to the message string via string.format().
function arista.player.notifyAll(message, ...)
	for _, ply in ipairs(player.GetAll()) do
		ply:notifyChat(message, ...)
	end
end

do
	local function saveallTimer(playerlist)
		for i = 1, 5 do
			local ply = table.remove(playerlist)

			if IsValid(ply) then
				ply:saveData()
			end
		end
	end

	---
	-- Saves every player on the server's data. Unless told otherwise, this will do 5 per frame until they're all done, to ease server load.
	-- @param now Process every player's profile right now - used when time is urgent.
	function arista.player.saveAll(now)
		if now then
			for _, ply in ipairs(player.GetAll()) do
				ply:saveData()
			end

			return
		end

		local plys = player.GetAll()
		saveallTimer(plys)
		if #plys == 0 then return end

		timer.Create("Saving All Player Data", math.ceil(#plys / 5), 0, function() saveallTimer(plys) end)
	end
end

---
-- Gets a player by a part of their name, or their steamID, or their UniqueID, or their UserID.
-- Will provide the player with the shortest name that matches the key. That way a search for 'lex' will return '||VM|| Lexi' even if 'LeXiCaL1ty{GT}' is available.
-- @param id An ID to search for the player by.
-- @return A player if one is found, nil otherwise.
function arista.player.get(id)
	local name = id:lower()
	local num = tonumber(id)
	local res, len

	for _, ply in ipairs(player.GetAll()) do
		local pname = ply:Name():lower()

		if (num and ply:UserID() == num or ply:UniqueID() == num) or ply:SteamID() == id or ply:SteamID64() == id then
			return ply
		elseif pname == name then
			return ply
		elseif pname:find(name) then
			local lon = pname:len()

			if res then
				if lon < len then
					res = ply
					len = lon
				end
			else
				res = ply
				len = lon
			end
		end
	end

	return res
end
