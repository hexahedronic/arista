if arista.derma.menu and arista.derma.menu.panel and arista.derma.menu.open then
	MsgN("  Refreshed, trying to clean up menu...")

	gui.EnableScreenClicker(false)

	arista.derma.menu.panel:Remove()
	arista.derma.menu.panel = nil
end

arista.derma.menu = {}
arista.derma.menu.open = open

local width = 700
if ScrW() > width then
	arista.derma.menu.width = width
else
	arista.derma.menu.width = ScrW()
end
arista.derma.menu.height = ScrH() - 40

-- Define a new panel.
local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetTitle("Main Menu")
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(false)
	self:ShowCloseButton(false)
	self:SetDraggable(false)

	-- Create the close button.
	self.close = vgui.Create("DButton", self)
	self.close:SetText("Close")
	self.close.DoClick = function(self)
		arista.derma.menu.toggle()
	end

	-- Create the tabs property sheet.
	self.tabs = vgui.Create("DPropertySheet", self)

	-- Add the sheets for the other menus to the property sheet.
	self.tabs:AddSheet("Character", vgui.Create("arista_character", self.tabs), "icon16/user.png")
	--[[self.tabs:AddSheet("Help", vgui.Create("cider_Help", self.tabs), "icon16/page.png")
	self.tabs:AddSheet("Laws", vgui.Create("cider_Laws",self.tabs),"icon16/world.png")
	self.tabs:AddSheet("Rules", vgui.Create("cider_Rules", self.tabs), "icon16/exclamation.png")
	self.tabs:AddSheet("Inventory", vgui.Create("cider_Inventory", self.tabs), "icon16/application_view_tile.png")
	self.tabs:AddSheet("Store", vgui.Create("cider_Store", self.tabs), "icon16/box.png")
	self.tabs:AddSheet("Changelog",vgui.Create("cider_Changelog", self.tabs), "icon16/plugin.png")
	self.tabs:AddSheet("Donate", vgui.Create("cider_Donate", self.tabs), "icon16/heart.png")
	self.tabs:AddSheet("Credits",vgui.Create("cider_Credits",self.tabs), "icon16/group.png")]]
	--self.tabs:AddSheet("Log",vgui.Create("cider_Log",self.tabs), "icon16/page_white_magnify.png")
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:SetVisible(arista.derma.menu.open)
	self:SetSize(arista.derma.menu.width, arista.derma.menu.height)
	self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self:GetTall() / 2)

	-- Set the size and position of the close button.
	self.close:SetSize(48, 18)
	self.close:SetPos(self:GetWide() - self.close:GetWide() - 4, 3)

	-- Stretch the tabs to the parent.
	self.tabs:StretchToParent(4, 28, 4, 4)

	-- Size To Contents.
	self:SizeToContents()

	-- Perform the layout of the main frame.
	DFrame.PerformLayout(self)
end

-- Register the panel.
vgui.Register("arista_menu", PANEL, "DFrame")

-- A function to toggle the menu.
function arista.derma.menu.toggle()
	if arista._playerInited then
		arista.derma.menu.open = not arista.derma.menu.open

		-- Toggle the screen clicker.
		gui.EnableScreenClicker(arista.derma.menu.open)

		-- Check if the main menu exists.
		if arista.derma.menu.panel then
			arista.derma.menu.panel:SetVisible(arista.derma.menu.open)
		else
			arista.derma.menu.panel = vgui.Create("arista_menu")
			arista.derma.menu.panel:MakePopup()
		end
	end
end

-- Hook the net message to toggle the menu from the server.
net.Receive("arista_menu", arista.derma.menu.toggle)