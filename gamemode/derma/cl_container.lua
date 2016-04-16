local PANEL = {}
local width, height = ScrW() * 0.75, ScrH() * 0.75
local containermenu,targetEntity

local function closeMenu()
	if containermenu and ValidPanel(containermenu) then
		containermenu:Close()
		containermenu:Remove()

		gui.EnableScreenClicker(false)

		RunConsoleCommand("_arista_containerfinished")
	end
end
net.Receive("arista_closeContainerMenu", closeMenu)

local function checkPos()
	if not (arista.lp:Alive() and arista.lp:GetEyeTraceNoCursor().Entity == targetEntity) then
		closeMenu()

		return false
	end

	return true
end

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(width / 2 - 12, height - 40)

	-- Create a panel list to store the items.
	self.itemsList = vgui.Create("DPanelList", self)
		self.itemsList:SizeToContents()
		self.itemsList:SetPadding(2)
		self.itemsList:SetSpacing(3)
		self.itemsList:StretchToParent(4, 4, 12, 44)
		self.itemsList:EnableVerticalScrollbar()

	self.updatePanel = false
	self.mSpace = 40
	self.inventory = {}
	self.action = 0
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Called every frame.
function PANEL:Think()
	if self.updatePanel then
		self.updatePanel = false

		-- Clear the current list of items.
		self.itemsList:Clear();
		local info = vgui.Create("arista_containerInformation", self)
			info.mSpace = self.mSpace
			info.word = self.name
			info.inventory = self.inventory
		self.itemsList:AddItem(info)

		-- Create a table to store the categories.
		local categories = {none = {}}

		-- Loop through the items.
		for k, v in pairs(self.inventory) do
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

		for k, v in pairs(categories) do
			if k == "none" then
				-- Loop through the items.
				for k2, v2 in pairs(v) do
					self.currentItem = v2
					self.itemsList:AddItem(vgui.Create("arista_containerItem", self))
				end
			else
				local c = GAMEMODE:GetCategory(k)

				if not c.noShow then -- If the category doesn't want to show up (like it's plugin is missing) then don't show it.
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
						subitemsList:AddItem(vgui.Create("arista_containerItem", self))
					end
				end
			end
		end

		-- Rebuild the items list.
		self.itemsList:Rebuild()
	end
end

-- Register the panel.
vgui.Register("arista_containerInventory", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()

	-- Set the size and position of the panel.
	self:SetSize(width / 2, 75)
	self:SetPos(1, 5)

	-- Set the item that we are.
	self.item = self:GetParent().currentItem
	self.action = self:GetParent().action

	local amount = self:GetParent().inventory[self.item]
	local notake = false

	local item = arista.item.items[self.item]
	if amount < 0 or item.size < 0 	then
		notake = true
		amount = math.abs(amount)
	end

	-- Create a label for the name.
	self.name = vgui.Create("DLabel", self)
		local word = (amount > 1) and item.plural or item.name
		self.name:SetText(amount .. " " .. word .. " (" .. arista.lang:Get("AL_SIZE_X", item.size) .. ")")
		self.name:SizeToContents()
		self.name:SetTextColor(color_white)

	-- Create a label for the description.
	self.description = vgui.Create("DLabel", self)
		self.description:SetText(item.description or "")
		self.description:SizeToContents()
		self.description:SetTextColor(color_white)

	-- Create the spawn icon.
	self.spawnIcon = vgui.Create("SpawnIcon", self)
		self.spawnIcon:SetModel(item.model, item.skin)
		self.spawnIcon:SetToolTip()
		self.spawnIcon.DoClick = function() return end
		self.spawnIcon.OnMousePressed = function() return end
		self.itemFunctions = {}

	-- Check to see if the item has an on use callback.
	if not notake and bit.band(self.action, containermenu.meta.io) == self.action then
		if self.action == CONTAINER_CAN_PUT then
			if not containermenu.meta.filter or containermenu.meta.filter[self.item] then
				table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_PUT")
			end
		else
			table.insert(self.itemFunctions, arista.lang:Get"AL_DERMA_TAKE")
		end
	end

	-- Create the table to store the item buttons.
	self.itemButton = {}

	--TODO: Deal with this horrible mess of inline functions
	local function menus(self)
		if not checkPos() then return end

		if containermenu.buttoned then return end -- If a button has been pressed, we can't do anything until sent an update.

		if amount < 2 then
			RunConsoleCommand("arista", "container", item.uniqueID, string.lower(self:GetValue()), 1)
			containermenu.buttoned = true

			return
		end

		local menu = DermaMenu()

		-- Add an option for yes and no.
		menu:AddOption("1", function()
			RunConsoleCommand("arista", "container", item.uniqueID, string.lower(self:GetValue()), 1)

			-- Close the main menu.
			if containermenu and ValidPanel(containermenu) then containermenu.buttoned = true end
		end)

		menu:AddOption(arista.lang:Get"AL_DERMA_ALL", function()
			RunConsoleCommand("arista", "container", item.uniqueID, string.lower(self:GetValue()), "all")

			-- Close the main menu.
			if containermenu and ValidPanel(containermenu) then containermenu.buttoned = true end
		end)

		menu:AddOption(arista.lang:Get"AL_DERMA_AMOUNT", function()
				local editPanel = vgui.Create("QFrame")
					editPanel:SetPos((ScrW() - 50) / 2, (ScrH() - 38) / 2)
					editPanel:SetSize(100 ,76)
					editPanel:SetTitle(arista.lang:Get"AL_DERMA_AMOUNT")
					editPanel:SetVisible(true)
					editPanel:SetDraggable(true)
					editPanel:ShowCloseButton(true)
					editPanel:MakePopup()

				local box = vgui.Create("QTextEntry", editPanel)
					box:SetPos(10, 28)
					box:SetSize(editPanel:GetWide() - 20, 16)
					box:RequestFocus()

					local func = function()
						local val = tonumber(box:GetValue())
						if (not val) or string.sub(val,1,1) == "-" then return end
						RunConsoleCommand("arista", "container", item.uniqueID, string.lower(self:GetValue()), math.floor(val))
						editPanel:Close()

						-- Close the main menu.
						if containermenu and ValidPanel(containermenu) then containermenu.buttoned = true end
					end
					box.OnEnter = func

				local button = vgui.Create("QButton", editPanel)
					button:SetText(self:GetValue())
					button.DoClick = func
					button:SetPos(editPanel:GetWide() - button:GetWide() - 10, 46)
		end)

		-- Open the menu.
		menu:Open()
	end

	-- Loop through the item functions.
	for i = 1, #self.itemFunctions do
		if self.itemFunctions[i] then
			self.itemButton[i] = vgui.Create("QButton", self)
				self.itemButton[i]:SetText(self.itemFunctions[i])
				self.itemButton[i].DoClick = menus
		end
	end

	self:InvalidateLayout()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	if not self.spawnIcon then return end

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
vgui.Register("arista_containerItem", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	-- Create the space used label.
	self.word = self.word or "argh"

	self.spaceUsed = vgui.Create("DLabel", self)
	self.spaceUsed:SetText(self.word .. " " .. arista.lang:Get"AL_HUD_SPACEUSED" .. "MMMMM/MMMMM")
	self.spaceUsed:SizeToContents()
	self.spaceUsed:SetTextColor(color_white)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	-- Set the position of the label.
	self.spaceUsed:SetPos((self:GetWide() / 2) - (self.spaceUsed:GetWide() / 2), 5)
	self.spaceUsed:SetText(self.word .. " " .. arista.lang:Get"AL_HUD_SPACEUSED" .. arista.inventory.getSize(self.inventory) .. "/" .. self.mSpace)
	self.spaceUsed:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_containerInformation", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	QFrame.Init(self)

	self:SetTitle(arista.lang:Get"AL_DERMA_CONTAINER")
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(true)

	-- Create the close button.
	self.btnClose.DoClick = closeMenu

	-- Capture the position of the local player.
	self.localPlayerPosition = arista.lp:GetPos()

	self.pInventory = vgui.Create("arista_containerInventory", self)
	self.cInventory = vgui.Create("arista_containerInventory", self)

	self.pInventory.action = CONTAINER_CAN_PUT
	self.pInventory.name = arista.lang:Get"AL_DERMA_YOUR_INVENTORY"

	self.cInventory.action = CONTAINER_CAN_TAKE
	self.cInventory.name = arista.lang:Get"AL_DERMA_CONT_INVENTORY"
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	QFrame.PerformLayout(self)
	self:SetSize(width, height)
	self:SetPos((ScrW() - width) / 2, (ScrH() - height) / 2)

	if not self.pInventory then return end

	-- Set the position of both lists
	self.pInventory:Dock(LEFT)
	self.pInventory:DockMargin(5, 10, 0, 5)
	self.cInventory:Dock(RIGHT)
	self.cInventory:DockMargin(0, 10, 5, 5)
end

function PANEL:Think()
	if not self.pInventory then return end
	checkPos()

	local m = arista.lp:getMoney()
	m = m > 0 and m or nil

	if self.pInventory.inventory["money"] == m then return end

	self.pInventory.inventory["money"] = m
	self.pInventory.updatePanel = true
end

-- Register the panel.
vgui.Register("arista_container", PANEL, "QFrame")

local function updateContainer(decoded)
	if not (containermenu and IsValid(containermenu)) then return end

	containermenu.meta = decoded.meta
	targetEntity = Entity(decoded.meta.entindex)

	if not IsValid(targetEntity) then
		ErrorNoHalt("Invalid entity passed to the container menu!")
		closeMenu()

		return
	end

	containermenu:SetTitle(decoded.meta.name)

	local pinventory = table.Copy(arista.inventory.stored)
	local cinventory = decoded.contents

	local m = arista.lp:getMoney()
	pinventory["money"] = m > 0 and m or nil

	containermenu.pInventory.inventory = pinventory
	containermenu.cInventory.inventory = cinventory

	containermenu.cInventory.mSpace = containermenu.meta.size
	containermenu.pInventory.mSpace = arista.inventory.getMaximumSpace()

	containermenu.pInventory.updatePanel = true
	containermenu.cInventory.updatePanel = true
	containermenu.buttoned = false
end

local function newContainer()
	if containermenu then closeMenu() end

	local decoded = net.ReadTable()

	containermenu = vgui.Create("arista_container")

	gui.EnableScreenClicker(true)

	containermenu:MakePopup()
	updateContainer(decoded)
end

net.Receive("arista_container", newContainer)
net.Receive("arista_containerUpdate", function()
	local decoded = net.ReadTable()

	updateContainer(decoded)
end)
