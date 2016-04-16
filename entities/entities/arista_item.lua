AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Item"
ENT.Author = "Lexi, Q2F2"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Amount")
	self:NetworkVar("String", 0, "Item")
end

if CLIENT then
	function ENT:espPaint(lines, pos, distance, lookingat)
		local item = self:GetItem()
		item = arista.item.items[item]

		if not item then return end

		local amount = self:GetAmount()
		local word = ""

		if amount > 1 then
			word = amount .. " " .. item.plural
		else
			local firstLetter = item.name[1]:lower()
			word = (firstLetter:lower():find("[aeio]", 1, true) and "An " or "A ") .. item.name
		end

		lines:add("Name", word, color_orange, 1)

		if not lookingat then return end

		local use = input.LookupBinding("+use"):upper()
		local shift = input.LookupBinding("+speed"):upper()

		if item.equippable and arista.lp:KeyDown(IN_SPEED) then
			lines:add("Instructions", arista.lang:Get("AL_X_PLUS_X_TO_X", use, shift, item.equipword), color_brightgreen, 2)
		else
			lines:add("Instructions", arista.lang:Get("AL_X_TO_X", use, arista.lang:Get("AL_PICKUP")), color_brightgreen, 2)
		end

		lines:add("Size", arista.lang:Get("AL_SIZE_X", item.size), color_white, 3)
	end

	return
end

-- This is called when the entity initializes.
function ENT:Initialize()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_BBOX)
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:CPPISetOwner(game.GetWorld())

	-- Get the physics object of the entity.
	local physicsObject = self:GetPhysicsObject()

	-- Check if the physics object is a valid entity.
	if IsValid(physicsObject) then
		physicsObject:Wake();
		physicsObject:EnableMotion(true)
	end
end

-- A function to set the item of the entity
function ENT:setItem(item, amount)
	self.item = item
	self:SetItem(item.uniqueID)

	self:SetAmount(amount or 1)

	self:SetModel(item.model)
	if item.skin then
		self:SetSkin(item.skin)
	end
end

-- Update the ent's amount
function ENT:updateAmount(add)
	self:SetAmount(self:GetAmount() + add or 0)

	if self:GetAmount() <= 0 then
		self:Remove()
	end
end

function ENT:CanTool(ply)
	return ply:IsAdmin()
end

function ENT:PhysgunPickup(ply)
	return ply:IsAdmin()
end

-- Called when the entity is used.
function ENT:Use(activator, caller)
	if not (activator:IsPlayer() and self.item) then
		return
	end

	local item = self.item
	local nextUseItem = activator:getAristaVar("nextUseItem") or 0

	if activator:KeyDown(IN_SPEED) and item.equippable then
		if not activator:IsAdmin() and nextUseItem > CurTime() then
			activator:notify("AL_CANNOT_USE_ITEM_SPECIFIC", "AL_ITEM", nextUseTime - CurTime())

			return false
		elseif activator:InVehicle() and item.NoVehicles then
			activator:notify("AL_CANNOT_USE_ITEM_VEHICLE")

			return false
		elseif gamemode.Call("PlayerCanUseItem", activator, item.uniqueID) == false then
			return false
		end

		activator:setAristaVar("nextUseItem", CurTime() + 2)

		if item.weapon then
			activator:setAristaVar("nextHolsterWeapon", CurTime() + 5)
		end

		if item:use(activator) then
			arista.inventory.update(activator, item.uniqueID, 1, true)

			self:updateAmount(-1)

			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, activator:Name(), "(", activator:SteamID(), ") equiped a dropped ", item.name, ".")
		end

		return
	end

	local picked = 0
	local amt = self:GetAmount()

	if self.item.size <= 0 or arista.inventory.canFit(activator, item.size * amt) then
		local a, b, c, d = arista.inventory.update(activator, item.uniqueID, amt)
		if not a then
			activator:notify(b, c, d)

			return
		end

		picked = amt
	else
		for i = 1, amt do
			local s, f, c, d = arista.inventory.update(activator, item.uniqueID, 1)

			if not s then
				activator:notify(f, c, d)

				break
			end

			picked = picked + 1
		end
	end

	if picked > 0 then
		if picked == 1 then
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, activator:Name(), "(", activator:SteamID(), ") picked up a ", item.name, ".")
		else
			arista.logs.event(arista.logs.E.LOG, arista.logs.E.ITEM, activator:Name(), "(", activator:SteamID(), ") picked up ", picked, " ", item.plural, ".")
		end

		self:updateAmount(-picked)
	end
end
