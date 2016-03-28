AddCSLuaFile()

arista.file = {}

local dir = arista.gamemode.luaFolder:sub(1, -2)
if not file.Exists("data/" .. dir, "GAME") then file.CreateDir(dir) end

function arista.file.makeDir(path)
	return file.CreateDir(arista.gamemode.luaFolder .. path)
end

function arista.file.findData(path)
	return file.Find("data/" .. arista.gamemode.luaFolder .. path, "GAME")
end

function arista.file.readData(path)
	return file.Read("data/" .. arista.gamemode.luaFolder .. path, "GAME")
end

function arista.file.writeData(path, data)
	return file.Write(arista.gamemode.luaFolder .. path, data)
end

function arista.file.deleteData(path)
	return file.Delete(arista.gamemode.luaFolder .. path)
end

function arista.file.existsData(path)
	return file.Exists("data/" .. arista.gamemode.luaFolder .. path, "GAME")
end

function arista.file.find(path)
	return file.Find(arista.gamemode.folder .. path, "GAME")
end

function arista.file.findInLua(path)
	return file.Find(arista.gamemode.gmFolder .. path, "LUA")
end

function arista.file.exists(path)
	return file.Exists(arista.gamemode.gmFolder .. path, "LUA")
end

function arista.file.valid(name)
	return name[1] ~= "." and not name:find("~", 1, true)
end

function arista.file.loadDir(path, name, plural)
	arista.logs.log(arista.logs.E.LOG, "Loading all " .. plural .. ".")

	local count = 0
	local files = arista.file.findInLua(path .. "*.lua")

	for k, v in pairs(files) do
		if arista.file.valid(v) then
			local prefix = v:sub(1, 3)
			local fname = v:sub(4, -5)

			if prefix == "sh_" then
				include(path .. v)
				MsgN(" Loaded the shared " .. fname .. " " .. name .. ".")

				count = count + 1
			elseif (SERVER) then
				if prefix == "sv_" then
					include(path .. v)
					MsgN(" Loaded the serverside " .. fname .. " " .. name .. ".")

					count = count + 1
				elseif prefix == "cl_" then
					AddCSLuaFile(path .. v)
				end
			elseif prefix == "cl_" then
				include(path..v)
				MsgN(" Loaded the clientside " .. fname .. " " .. name .. ".")

				count = count + 1
			end
		end
	end

	arista.logs.log(arista.logs.E.LOG, "Loaded " .. count .. " " .. plural .. ".")
end
