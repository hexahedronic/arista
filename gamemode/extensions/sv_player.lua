arista.player = {}

---
-- Notifies every player on the server that has the specified access.
-- @param access The access string to search for
-- @param message The message to display
-- @param level The notification level. Nil or unspecified = chat message. 0 = Water drip. 1 = Failure buzzer. 2 = 'Bip' Notification. 3 = 'Tic' Notification. (Used by the cleanup)
function arista.player.notifyByAccess(access, message, ...)
	for _, ply in pairs(player.GetAll()) do
		if ply:hasAccess(access) then
			ply:notify(message, ...)
		end
	end
end

---
-- Notifies every player on the server and logs a public event
-- @see GM:Log
-- @param message The message to display. (Use same form as GM:Log)
-- @param level The notification level. Nil or unspecified = chat message. 0 = Water drip. 1 = Failure buzzer. 2 = 'Bip' Notification. 3 = 'Tic' Notification. (Used by the cleanup)
-- @param ... A series of strings to be applied to the message string via string.format().
function arista.player.notifyAll(message, ...)
	for _, ply in ipairs(player.GetAll()) do
		ply:notify(message, ...)
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
