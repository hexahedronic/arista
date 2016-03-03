arista.derma.door = {}

-- Define a new panel.
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetTitle("Door Menu - NYI")
	-- todo: remove when added
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(true)

	self:ShowCloseButton(false)

	-- Create the close button.
	self.close = vgui.Create("DButton", self)
	self.close:SetText("Close")
	self.close.DoClick = function()
		self:Close()
		self:Remove()

		-- Disable the screen clicker.
		gui.EnableScreenClicker(false)
	end

	-- Capture the position of the local player.
	self._localPlayerPosition = arista.lp:GetPos()

	-- Create the label panels.
	self.label = vgui.Create("DLabel", self)
	self.nameLabel = vgui.Create("DLabel", self)
		self.nameLabel:SetTextColor(color_white)
		self.nameLabel:SetText("Name:")
		self.nameLabel:SizeToContents()

	local function purchase()
		self:Close()
		self:Remove()

		-- Disable the screen clicker.
		gui.EnableScreenClicker(false)

		-- Check if the local player's position is different from our captured one.
		if arista.lp:GetPos() ~= self._localPlayerPosition or not arista.lp:Alive() then
			return
		end

		if self.textEntry:GetValue():Trim() == "" then
			--RunConsoleCommand("cider", "door", "purchase")
		else
			--RunConsoleCommand("cider", "door", "purchase", self.textEntry:GetValue())
		end

		-- todo: maybe arista.runCommand or something? eitherway readd when commands done.
	end

	-- Create the text entry panel.
	self.textEntry = vgui.Create("DTextEntry", self)
	self.textEntry.OnEnter = purchase
	self.textEntry:RequestFocus()

	-- Create the purchase button.
	self.purchase = vgui.Create("DButton", self)
	self.purchase:SetText("Purchase")
	self.purchase.DoClick = purchase

	self:SetVisible(true)
	self:MakePopup()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	local width = math.max(180, self.label:GetWide())
	self:SetSize(8 + width + 8, 28 + self.label:GetTall() + 8 + self.textEntry:GetTall() + 8 + self.purchase:GetTall() + 8)

	-- Set the visibility of the label.
	self.label:SetVisible(true)

	-- Set the position of the menu.
	self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self:GetTall() / 2)

	-- Set the size and position of the close button.
	self.close:SetSize(48, 18)
	self.close:SetPos(self:GetWide() - self.close:GetWide() - 4, 3)

	-- Set the position of the label and the purchase button.
	self.label:SetPos(8, 28)
	self.purchase:SetPos(8, 50)

	-- Set the position of the label, text entry, and button panels.
	self.nameLabel:SetPos(8, 28 + 10)
	self.textEntry:SetPos(8 + self.nameLabel:GetWide() + 8, 28 + 8)
	self.textEntry:SetSize(self:GetWide() - self.nameLabel:GetWide() - 24, 18)
	self.purchase:SetText("Purchase")

	-- Set the position of the label and text entry panels.
	self.nameLabel:SetPos(8, 28 + self.label:GetTall() + 8)
	self.textEntry:SetPos(8 + self.nameLabel:GetWide() + 8, 28 + self.label:GetTall() + 8)

	-- Set the position of the purchase button.
	self.purchase:SetPos(8, 28 + self.label:GetTall() + 8 + self.textEntry:GetTall() + 8)

	local cost = arista.config.costs.door or 0

	self.label:SetTextColor(color_green)
	self.label:SetText("Purchase this door for $" .. cost .. ".")
	-- todo: language
	self.label:SizeToContents()

	-- Set the label and text entry panels to be visible.
	self.nameLabel:SetVisible(true)
	self.textEntry:SetVisible(true)

	-- Set the frame to size itself based on it's contents.
	self:SizeToContents()

	-- Check if the local player's position is different from our captured one.
	if arista.lp:GetPos() ~= self._localPlayerPosition or not arista.lp:Alive() then
		self:Close()
		self:Remove()

		-- Disable the screen clicker.
		gui.EnableScreenClicker(false)
	end

	-- Perform the layout of the main frame.
	DFrame.PerformLayout(self)
end

-- Register the panel.
vgui.Register("arista_door", PANEL, "DFrame")


net.Receive("arista_buyDoor", function()
	-- Enable the screen clicker.
	gui.EnableScreenClicker(true)

	-- Check if the door panel already exists.
	local door = arista.derma.door
	if door.panel then door.panel:Remove() end

	arista.derma.door.panel = vgui.Create("arista_door")
end)
