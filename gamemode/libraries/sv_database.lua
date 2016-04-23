arista.database = {}
arista.database.spam = false

function arista.database.initialize()
	if arista.config.storage_type == "sql" then
		require("tmysql4")

		if not tmysql then
			arista.config.storage_type = ""
			error("Failed to load tmysql4")
		end

		local err
		_G._arista_database, err = tmysql.initialize(arista.config.sql.host, arista.config.sql.user, arista.config.sql.pass, arista.config.sql.database, arista.config.sql.port)

		if not _arista_database then
			error("Failed to init database: " .. err)
		end

		arista.logs.log(arista.logs.E.LOG, "ESTABLISHED CONNECTION TO REMOTE SQL DB!")
	end
end

function arista.database.formatColumnsFromTable(data, ply)
	local str, col, val = "", "steamID64,", "'" .. ply:SteamID64() .. "',"
	for k, v in pairs(data) do
		col = col .. k .. ","

		local r = v
		if isstring(r) then
			r = "'" .. r .. "'"
		elseif istable(r) then
			r = "'" .. arista.utils.serialize(r) .. "'"
		end

		str = str .. k .. "=" .. tostring(r) .. ","
		val = val .. tostring(r) .. ","
	end

	return str:sub(1, -2), col:sub(1, -2), val:sub(1, -2)
end

function arista.database.genericCallback(q)
	return function(r)
		local d = r[1]
		if d.error then
			ErrorNoHalt(q .. " -> error with query: " .. d.error .. "\n")
		end
	end
end

function arista.database.savePlayer(ply, create)
	local data = ply._databaseVars
	if not data then
		ErrorNoHalt("Player was missing database table -> " .. tostring(ply) .. "\n")
	end

	if arista.config.storage_type == "pdata" then
		if create then
			arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been recreated for the database.")

			return
		end

		data = arista.utils.serialize(data)

		ply:SetPData(arista.config.sql.table, data)
		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been saved to the database.")
	elseif arista.config.storage_type == "sql" then
		if create then
			arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been created for the database.")

			local datavars, columns, values = arista.database.formatColumnsFromTable(arista.config.database, ply)
			local q = "INSERT INTO `" .. arista.config.sql.table .. "` (" .. columns .. ") VALUES (" .. values .. ");"
			if arista.database.spam then print("create", q) end

			_arista_database:Query(q, arista.database.genericCallback(q))
		elseif data then
			local datavars, columns, values = arista.database.formatColumnsFromTable(data, ply)
			local q = "UPDATE `" .. arista.config.sql.table .. "` SET " .. datavars .. " WHERE steamID64='" .. ply:SteamID64() .. "';"
			if arista.database.spam then print("update", q) end

			_arista_database:Query(q, arista.database.genericCallback(q))
		end

		arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been saved to the database.")
	end
end

-- callback for SQL implementation
function arista.database.fetchPlayer(ply, callback)
	if arista.config.storage_type == "pdata" then
		local data = ply:GetPData(arista.config.sql.table)

		if not data then
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has joined for the first time and has been inserted into the database.")

			gamemode.Call("PlayerAddedToDatabase", ply)
			callback(nil)

			return
		end

		data = arista.utils.deSerialize(data)

		callback(data)
	elseif arista.config.storage_type == "sql" then
		-- sometimes it doesnt load?
		if not _arista_database then
			arista.database.initialize()
		end

		_arista_database:Query("SELECT * FROM `" .. arista.config.sql.table .. "` WHERE steamID64='" .. ply:SteamID64() .. "';", function(res)
			if not (ply and ply:IsValid()) then return end
			local data = res[1]

			if not data.status or data.error then
				local err = data.error or "unknown error"
				error("error getting the sql shit: " .. err)
			end

			if table.Count(data.data) < 1 then
				arista.database.savePlayer(ply, true)
			end

			if arista.database.spam then PrintTable(data) end

			if not data.data[1] then
				arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has joined for the first time and has been inserted into the database.")

				gamemode.Call("PlayerAddedToDatabase", ply)
			end

			callback(data.data[1])
		end)
	end
end

function arista.database.loadPlayer(ply)
	arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") is now being loaded.")

	local f = function(tbl)
		if tbl then
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") has been loaded from the database.")

			for k, v in pairs(tbl) do
				arista.logs.event(arista.logs.E.DEBUG, arista.logs.E.NETEVENT, ply:Name(), "(", ply:SteamID(), ") had database key '", k, "' loaded as '", v, "'.")

				if arista.config.storage_type == "sql" then
					-- stores tables as serialized strings
					if istable(arista.config.database[k]) then
						v = arista.utils.deSerialize(v) or v
					end

					-- stores bools as int
					if isbool(arista.config.database[k]) then
						v = tobool(v)
					end
				end

				if istable(v) then ply:setAristaVar(k, v) else ply:networkAristaVar(k, v) end
				ply:databaseAristaVar(k)
			end
		end

		gamemode.Call("PlayerDataLoaded", ply, tbl ~= nil)
	end

	arista.database.fetchPlayer(ply, f)
end

function arista.database.shutdown()
	if arista.config.storage_type == "sql" then
		if _arista_database then
			_arista_database:Disconnect()
		end
	end
end
