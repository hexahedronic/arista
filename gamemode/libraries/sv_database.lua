arista.database = {}

function arista.database.initialize()
	-- We aren't using sql for now.
end

function arista.database.savePlayer(ply, create)
	-- pdata because I am lazy, I will re-add SQL support later.

	local data = ply._databaseVars
	if create then
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been recreated for the database.")

		return
	end

	data = arista.utils.serialize(data)

	ply:SetPData(arista.config.table, data)
	arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been saved to the database.")
end

-- callback for SQL implementation
function arista.database.fetchPlayer(ply, callback)
	local data = ply:GetPData(arista.config.table)

	if not data then
		arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has joined for the first time and has been inserted into the database.")

		gamemode.Call("PlayerAddedToDatabase", ply)
		callback(nil)

		return
	end

	data = arista.utils.deSerialize(data)

	callback(data)
end

function arista.database.loadPlayer(ply)
	arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") is now being loaded.")

	local f = function(tbl)

		if tbl then
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been loaded from the database.")

			for k, v in pairs(tbl) do
				arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' loaded as '", v, "'.")

				if istable(v) then ply:setAristaVar(k, v) else ply:networkAristaVar(k, v) end
				ply:databaseAristaVar(k)
			end
		end

		gamemode.Call("PlayerDataLoaded", ply, tbl ~= nil)
	end

	arista.database.fetchPlayer(ply, f)
end
