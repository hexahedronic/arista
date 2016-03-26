local closeOnDrop = CreateClientConVar("arista_menu_closeondrop", "1", true)

local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(arista.derma.menu.width, arista.derma.menu.height - 8)

	-- Create a panel list to store the items.
	self.itemsList = vgui.Create("DPanelList", self)
		self.itemsList:SizeToContents()
		self.itemsList:SetPadding(2)
		self.itemsList:SetSpacing(3)
		self.itemsList:StretchToParent(4, 4, 12, 44)
		self.itemsList:EnableVerticalScrollbar()

	-- Set this to true to begin with so that we do one starting update.
	arista.inventory.updatePanel = true

	-- We call think just once on initialize so that we can update.
	self:Think()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22, 0, 0)
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Called every frame.
function PANEL:Think()
	if arista.inventory.updatePanel then
		arista.logs.log(arista.logs.E.DEBUG, "Updating clientside inventory panel.")
		arista.inventory.updatePanel = false

		-- Clear the current list of items.
		self.itemsList:Clear()

		local invInfo = vgui.Create("arista_inventoryInformation", self)
		self.itemsList:AddItem(invInfo)

			-- Create a table to store the categories.
		local categories = {none = {}}

		-- Loop through the items.
		for k, v in pairs(arista.inventory.stored) do
			arista.logs.log(arista.logs.E.DEBUG, "Updating for item " , k, ".")
			local item = arista.item.items[k]

			if item then
				local cat = item.category

				if cat and GAMEMODE:GetCategory(cat) then
					categories[cat] = categories[cat] or {}

					-- Insert the item into the category table.
					table.insert(categories[cat], k)
				else
					table.insert(categories.none, k)
				end
			end
		end

		-- Loop through the categories.
		for k, v in pairs(categories) do
			arista.logs.log(arista.logs.E.DEBUG, "mixtape fire for cat " , k, ".")

			if k == "none" then
				-- Loop through the items.
				for k2, v2 in pairs(v) do
					self.currentItem = v2
					arista.logs.log(arista.logs.E.DEBUG, "mixtape track for item " , k2, " (none).")

					local item = vgui.Create("arista_inventoryItem", self)
					self.itemsList:AddItem(item)
				end
			else
				local c = GAMEMODE:GetCategory(k)

				if not c.noShow then -- If the category doesn't want to show up (like it's plugin is missing) then don't show it.
					arista.logs.log(arista.logs.E.DEBUG, "mixtape track for item " , k2, " (", c, ").")

					local header = vgui.Create("QCollapsibleCategory", self)
						header:SetSize(arista.derma.menu.width, 50) -- Keep the second number at 50
						header:SetLabel(c.name)
						header:SetToolTip(c.description)
					self.itemsList:AddItem(header)

					local subitemsList = vgui.Create("DPanelList", self)
						subitemsList:SetAutoSize(true)
						subitemsList:SetPadding(2)
						subitemsList:SetSpacing(3)
					header:SetContents(subitemsList)

					-- Loop through the items.
					for k2, v2 in pairs(v) do
						self.currentItem = v2

						-- Add the item to the item list.
						local item = vgui.Create("arista_inventoryItem", self)
						subitemsList:AddItem(item)
					end
				end
			end
		end

		-- Rebuild the items list.
		self.itemsList:Rebuild()
	end
end

-- Register the panel.
vgui.Register("arista_inventory", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.itemFunctions = {}

	-- Set the size and position of the panel.
	self:SetSize(arista.derma.menu.width, 75)
	self:SetPos(1, 5)

	-- Set the item that we are.
	self.item = self:GetParent().currentItem

	local item = arista.item.items[self.item]
	local amount = arista.inventory.stored[self.item]

	-- Create a label for the name.
	self.name = vgui.Create("DLabel", self)
		local word = (amount > 1) and item.plural or item.name
		self.name:SetText(amount .. " " .. word .. " (Size: " .. item.size .. ")")
		self.name:SizeToContents()
		self.name:SetTextColor(color_white)

	-- Create a label for the description.
	self.description = vgui.Create("DLabel", self)
		self.description:SetText(item.description)
		self.description:SizeToContents()
		self.description:SetTextColor(color_white)

	-- Create the spawn icon.
	self.spawnIcon = vgui.Create("SpawnIcon", self)
		self.spawnIcon:SetModel(item.model, item.skin)
		self.spawnIcon:SetToolTip()
		self.spawnIcon.DoClick = function() return end
		self.spawnIcon.OnMousePressed = function() return end

	-- Check to see if the item has an on use callback.
	if item.onUse then table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_USE") end
	if item.onDrop then table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_DROP") end
	if item.onSell then table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_SELL") end
	if item.onPickup then table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_PICKUP") end
	if item.onDestroy then table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_DESTROYALL") end

	-- Create the table to store the item buttons.
	self.itemButton = {}

	-- Loop through the item functions.
	for i = 1, #self.itemFunctions do
		local itemFunc = self.itemFunctions[i]

		if itemFunc then
			self.itemButton[i] = vgui.Create("QButton", self)
			self.itemButton[i]:SetText(itemFunc)

			-- Check what type of button it is.
			if itemFunc == arista.lang:Get"AL_DERMA_USE" then
				self.itemButton[i].DoClick = function()
					RunConsoleCommand("arista", "inventory", self.item, "use")

					if item.autoClose then
						arista.derma.menu.toggle()
					end
				end
			elseif itemFunc == arista.lang:Get"AL_DERMA_DROP" then
				self.itemButton[i].DoClick = function()
					if arista.inventory.stored[self.item] < 2 then
						RunConsoleCommand("arista", "inventory", self.item, "drop", 1)

						if closeOnDrop:GetBool() then
							-- Close the main menu.
							arista.derma.menu.toggle()
						end

						return
					end

					local menu = DermaMenu()

					-- Add an option for yes and no.
					menu:AddOption("1", function()
						RunConsoleCommand("arista", "inventory", self.item, "drop", 1)

						if closeOnDrop:GetBool() then
							-- Close the main menu.
							arista.derma.menu.toggle()
						end
					end)

					menu:AddOption(arista.lang:Get"AL_DERMA_ALL", function()
						RunConsoleCommand("arista", "inventory", self.item, "drop", "all")

						if closeOnDrop:GetBool() then
							-- Close the main menu.
							arista.derma.menu.toggle()
						end
					end)

					menu:AddOption(arista.lang:Get"AL_DERMA_AMOUNT", function()
						local amt = function(str)
							local str = tonumber(str)
							if not str then return end

							str = math.floor(str)
							if str < 1 then return end

							RunConsoleCommand("arista", "inventory", self.item, "drop", str)

							if closeOnDrop:GetBool() then
								-- Close the main menu.
								arista.derma.menu.toggle()
							end
						end

						Derma_StringRequest("Amount", "Amount of item to drop.", "1", amt)
					end)

					-- Open the menu.
					menu:Open()
				end
			elseif itemFunc == arista.lang:Get"AL_DERMA_PICKUP" then
				self.itemButton[i].DoClick = function()
					RunConsoleCommand("arista", "inventory", self.item, "pickup")
				end
			elseif itemFunc == arista.lang:Get"AL_DERMA_SELL" then
				self.itemButton[i].DoClick = function()
					local menu = DermaMenu()

					-- Add an option for yes and no.
					menu:AddOption(arista.lang:Get"AL_NO", function() end)
					menu:AddOption(arista.lang:Get"AL_YES", function()
						RunConsoleCommand("arista", "inventory", self.item, "sell")
					end)

					-- Open the menu.
					menu:Open()
				end
			elseif itemFunc == arista.lang:Get"AL_DERMA_DESTROYALL" then
				self.itemButton[i].DoClick = function()
					local menu = DermaMenu()

					-- Add an option for yes and no.
					menu:AddOption(arista.lang:Get"AL_NO", function() end)
					menu:AddOption(arista.lang:Get"AL_YES", function()
						RunConsoleCommand("arista", "inventory", self.item, "destroy")
					end)

					-- Open the menu.
					menu:Open()
				end
			end
		end
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.spawnIcon:SetPos(4, 5)
	self.name:SizeToContents()
	self.description:SetPos(75, 24)
	self.description:SizeToContents()

	-- Define the x position of the item functions.
	local x = self.spawnIcon.x + self.spawnIcon:GetWide() + 8

	-- Set the position of the name and description.
	self.name:SetPos(x, 4)
	self.description:SetPos(x, 24)

	-- Loop through the item functions and set the position of their button.
	for i = 1, #self.itemFunctions do
		if self.itemButton[i] then
			self.itemButton[i]:SetPos(x, 47)

			-- Increase the x position for the next item function.
			x = x + self.itemButton[i]:GetWide() + 4
		end
	end
end

-- Register the panel.
vgui.Register("arista_inventoryItem", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	local maximumSpace = arista.inventory.getMaximumSpace()

	-- Create the space used label.
	self.spaceUsed = vgui.Create("DLabel", self)
		self.spaceUsed:SetText(arista.lang:Get"AL_HUD_SPACEUSED" .. arista.inventory.getSize() .. "/" .. maximumSpace)
		self.spaceUsed:SizeToContents()
		self.spaceUsed:SetTextColor(color_white)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	local maximumSpace = arista.inventory.getMaximumSpace()

	-- Set the position of the label.
	self.spaceUsed:SetPos((self:GetWide() / 2) - (self.spaceUsed:GetWide() / 2), 5)
	self.spaceUsed:SetText(arista.lang:Get"AL_HUD_SPACEUSED" .. arista.inventory.getSize() .. "/" .. maximumSpace)
end

-- Register the panel.
vgui.Register("arista_inventoryInformation", PANEL, "QPanel")
