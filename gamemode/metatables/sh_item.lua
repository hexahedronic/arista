AddCSLuaFile()

local item = FindMetaTable("Item")

if not item then
	arista.logs.log(arista.logs.E.FATAL, "COULD NOT FIND ITEM METATABLE!")

	return
end

---
-- Internal: Registers a populated item table.
function item:register()
	if not self.uniqueID then
		ErrorNoHalt("Item with no uniqueID registered!\nDumping table:\n")
		PrintTable(self)

		return false
	end

	if self.base then
		local base = {}
		self.baseClass = {}

		if type(self.Base) == "table" then
			for _, id in ipairs(self.base) do
				table.Merge(base, arista.item.items[id] or {})
			end
		else
			table.Merge(base, arista.item.items[self.base] or {})
		end

		for k,v in pairs(base) do
			if not self[k] then
				self[k] = v
			end

			self.baseClass[k] = v
		end
	end

	if self.model then
		util.PrecacheModel(self.model)
	end

	arista.item.items[self.uniqueID] = self
end
