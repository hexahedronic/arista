AddCSLuaFile()

arista.item = {}
arista.item.items = {}
arista.item.meta = {}
arista.item.cats = {} -- meow
arista.item.index = 0

-- Set the metatable up
arista.item.meta.__index = arista.item.meta

local mt = {
	__call = function(self, tab)
		return setmetatable(tab or {}, self)
	end
}
setmetatable(arista.item.meta, mt)

arista.registry.Item = arista.item.meta

function GM:LoadItems()
	local path = "items/"
	arista.logs.log(arista.logs.E.LOG, "Loading Item Bases:")

	local files, folders, _
	files, _ = arista.file.findInLua(path .. "base/*.lua")

	for _, filename in ipairs(files) do
		local filePath = path .. "base/" .. filename

		if arista.file.valid(filename) then
			ITEM = arista.item.meta()
			ITEM.name = "NULL" -- For the search

			if SERVER then AddCSLuaFile(filePath) end
			include(filePath)

			local uid = filename:sub(1, -5)
			ITEM.uniqueID = uid
			ITEM:register()

			ITEM = nil

			MsgN(" Loaded item base '" .. uid .. "'.")
		end
	end

	arista.logs.log(arista.logs.E.LOG, "Loading Categories:")

	local total = 0
	_, folders = arista.file.findInLua(path .. "*")

	for _, filename in ipairs(folders) do
		local initPath = path .. filename .. "/init.lua"

		if arista.file.valid(filename) and filename ~= "base" then
			local str, count = "", 0
			CAT = {}

			if SERVER then AddCSLuaFile(initPath) end
			include(initPath)

			-- Enumerations.
			local newCat = self:RegisterCategory(CAT)
			_G['CATEGORY_' .. filename:upper()] = newCat

			files, _ = arista.file.findInLua(path .. filename .. "/*.lua")

			for _, item in ipairs(files) do
				local filePath = path .. filename .. "/" .. item

				if arista.file.valid(item) and item ~= "init.lua" then
					if arista.config.vars.disabledItems[filename .. "/" .. item] then continue end
					ITEM = arista.item.meta()

					if SERVER then AddCSLuaFile(filePath) end
					include(filePath)

					local uid = item:sub(1, -5)
					ITEM.uniqueID = uid
					ITEM.category = newCat
					ITEM:register()

					ITEM = nil

					str = str .. ", " .. uid
					count = count + 1
				end
			end

			str = str:sub(3)

			CAT = nil

			total = total + count
			MsgN(" Loaded category '" .. filename .. "' with " .. count .. " items:\n  " .. str)
		end
	end

	arista.logs.log(arista.logs.E.LOG, "Loaded ", total, " items in total.")
end

function GM:RegisterCategory(cat) -- meow
	cat.index = arista.item.index
	arista.item.cats[cat.index] = cat

	arista.item.index = arista.item.index + 1

	return cat.index
end

function GM:GetCategory(id)
	if not id then
		arista.logs.log(arista.logs.E.ERROR, "GetCategory passed nil??")
	return end

	-- If we're passed a valid UniqueID, then return the item
	if arista.item.cats[id] then
		return arista.item.cats[id]
	end

	-- Otherwise, we're looking for part of a name.
	local res, len
	id = id:lower()

	for _, data in pairs(arista.item.cats) do
		local name = data.name:lower()

		if name:find(id, 1, true) then
			local lon = name:len()

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
arista.item.getCat = GM.GetCategory

function GM:GetItem(id)
	-- If we're passed a valid UniqueID, then return the item
	if arista.item.items[id] then
		return arista.item.items[id]
	end

	-- Otherwise, we're looking for part of a name.
	local res, len
	id = id:lower()

	for _, data in pairs(arista.item.items) do
		local name = data.name:lower()

		if name:find(id, 1, true) then
			local lon = name:len()

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
arista.item.get = GM.GetItem

-- Concommand for debug
if SERVER then
	concommand.Add("arista_reload_items", function(ply)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end

		gamemode.Call("LoadItems")
	end)
elseif GetConVar("developer"):GetInt() > 0 then -- Don't want the peons to get this command.
	concommand.Add("arista_reload_items_cl", function()
		gamemode.Call("LoadItems")
	end)
end
