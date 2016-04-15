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
	QFrame.Init(self)

	self:SetTitle(arista.lang:Get"AL_DERMA_MAINMENU")
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(false)
	self:SetDraggable(false)

	self.btnClose.DoClick = function(self)
		arista.derma.menu.toggle()
	end

	-- Create the tabs property sheet.
	self.tabs = vgui.Create("QPropertySheet", self)

	-- For refreshing.
	self.panels = {}

	self.tabs.addSheet = function(tabs, name, panel, icon)
		self.panels[#self.panels+1] = panel
		tabs:AddSheet(name, panel, icon)
	end

	-- Add the sheets for the other menus to the property sheet.
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_CHARACTER",		vgui.Create("arista_character", self.tabs),		"icon16/user.png")
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_INVENTORY",		vgui.Create("arista_inventory", self.tabs),		"icon16/application_view_tile.png")
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_STORE",			vgui.Create("arista_store", 	self.tabs),		"icon16/box.png")
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_CREDITS",		vgui.Create("arista_credits", 	self.tabs),		"icon16/group.png")
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_LAWS",			vgui.Create("arista_laws", 		self.tabs),		"icon16/world.png")
	self.tabs:addSheet(arista.lang:Get"AL_DERMA_HELP",			vgui.Create("arista_help", 		self.tabs),		"icon16/page.png")
end

function PANEL:Reload()
	if (self.panels) then
		for k, v in ipairs(self.panels) do
			v:InvalidateLayout()
		end
	end

	self:InvalidateLayout()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	QFrame.PerformLayout(self)

	self:SetVisible(arista.derma.menu.open)
	self:SetSize(arista.derma.menu.width, arista.derma.menu.height)
	self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self:GetTall() / 2)

	-- Stretch the tabs to the parent.
	if self.tabs then
		self.tabs:Dock(FILL)
		self.tabs:DockMargin(5, 10, 5, 5)
	end

	-- Size To Contents.
	self:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_menu", PANEL, "QFrame")

-- A function to toggle the menu.
function arista.derma.menu.toggle()
	if arista._playerInited then
		arista.derma.menu.open = not arista.derma.menu.open

		-- Toggle the screen clicker.
		gui.EnableScreenClicker(arista.derma.menu.open)

		-- Check if the main menu exists.
		if arista.derma.menu.panel and arista.derma.menu.panel:IsValid() then
			arista.derma.menu.panel:SetVisible(arista.derma.menu.open)

			arista.derma.menu.panel:Reload()
			timer.Simple(0.1, function() arista.derma.menu.panel:Reload() end)
		else
			arista.derma.menu.panel = vgui.Create("arista_menu")
			arista.derma.menu.panel:MakePopup()
		end
	end
end

-- Hook the net message to toggle the menu from the server.
net.Receive("arista_menu", arista.derma.menu.toggle)