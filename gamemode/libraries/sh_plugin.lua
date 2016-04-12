AddCSLuaFile()

arista.plugin = {}
arista.plugin.stored = {}

function GM:LoadPlugins()
	local count = 0

	arista.logs.log(arista.logs.E.LOG, "Loading Plugins:")

	local path = "plugins/"
	local files, folders = arista.file.findInLua(path .. "*")

	for _, id in ipairs(folders) do
		if not id:find(".", 1, true) then
			if arista.config.vars.disabledPlugins[id] then continue end

			PLUGIN = {}

			if arista.file.exists(path .. id .. "/sh_init.lua") then
				include(path .. id .. "/sh_init.lua")
			end

			if (SERVER) then
				if arista.file.exists(path .. id .. "/sv_init.lua") then
					include(path..id.."/sv_init.lua")
				end

				if arista.file.exists(path .. id .. "/cl_init.lua") then
					AddCSLuaFile(path .. id .. "/cl_init.lua")
				end
			elseif arista.file.exists(path .. id .. "/cl_init.lua") then
				include(path .. id .. "/cl_init.lua")
			end

			if PLUGIN.name then
				MsgN(" Loaded plugin '" .. PLUGIN.name .. "'")
				arista.plugin.stored[id] = PLUGIN

				count = count + 1
			end

			PLUGIN = nil
		end
	end

	if arista._inited then
		hook.Call("LoadData", self)
	end

	arista.logs.log(arista.logs.E.LOG, "Loaded ", count, " plugins.")
end

-- Concommand for debug
if SERVER then
	concommand.Add("arista_reload_plugins", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		gamemode.Call("LoadPlugins")
	end)
elseif GetConVar("developer"):GetInt() > 0 then -- Don't want the peons to get this command.
	concommand.Add("arista_reload_plugins_cl", function()
		gamemode.Call("LoadPlugins")
	end)
end

function GM:GetPlugin(id)
	-- If we're passed a valid plugin ID, then return the plugin
	local id = string.lower(id)

	if arista.plugin.stored[id] then
		return arista.plugin.stored[id]
	end

	local res, len

	-- Otherwise, we're looking for part of a name.
	for _, data in pairs(arista.plugin.stored) do
		if data.name:lower():find(id, 1, true) then
			local lon = data.name:len()

			if res then
				if lon < len then
					res = data
					len = lon
				end
			else
				res = data
				len = lon
			end
		end
	end

	return res
end
