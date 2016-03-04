-- todo: this looks like 90% inventory code,
-- possibly split it this into arista_invBase or something and rebuild inventory onto it?

local PANEL = {}

local width, height = ScrW() * 0.75,ScrH() * 0.75
local accessmenu
local localPlayerPosition
local CurTab

local function checkPos()
	if localPlayerPosition ~= LocalPlayer():GetPos() then
		accessmenu:Close()
		accessmenu:Remove()

		-- Disable the screen clicker.
		gui.EnableScreenClicker(false)
		return false
	end

	return true
end

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(width / 2 -10, height - 55)

	-- Create a panel list to store the items.
	self.itemsList = vgui.Create("DPanelList", self)
		self.itemsList:SizeToContents()
		self.itemsList:SetPadding(2)
		self.itemsList:SetSpacing(3)
		self.itemsList:StretchToParent(4, 4, 12, 0)
		self.itemsList:EnableVerticalScrollbar()

	self.updatePanel = false
	self.inventory = {}
	self.action = "error"
	self.type = "error"
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Called every frame.
function PANEL:Think()
	if not self.updatePanel then return end
	self.updatePanel = false

	-- Clear the current list of items.
	self.itemsList:Clear()
	local info = vgui.Create("arista_accessInformation", self)
	info.word = self.name
	self.itemsList:AddItem(info)

	-- Create a table to store the categories.
	local categories = {none = {}}
	local gnd = arista.lp:getGender():lower()
	local kind

	-- Loop through the items.
	for k, v in pairs(self.inventory) do
		if type(v) == "Player" then
			kind, self.type = "Teams", "player"
			categories[v:Team()] = categories[v:Team()] or {}

			local cln = v:getClan()
			local nam = "Name: " .. v:Name()
			if cln ~= "" then
				nam = nam .. "  (" .. cln .. ")"
			end

			local det = v:getDetails()

			local info = {
				nam,
				v:GetModel(),
				det ~= "" and "Details: " .. det or "- No Description -",
				v:UserID()
			}
			table.insert(categories[v:Team()], info)
		elseif v.isTeam then
			kind, self.type = "Groups", "team"
			categories[v.group.group] = categories[v.group.group] or {}

			local info = {
				v.name,
				table.Random(v.models[gnd]),
				v.description,
				v.index
			}
			table.insert(categories[v.group.group], info)
		else
			kind, self.type = "Groups","gang"

			local id = k:Split(";")[1]
			categories[id] = categories[id] or {}

			local info = {
				v.name,
				v.model,
				v.desc,
				v.index
			}
			table.insert(categories[id], info)
		end
	end

	for k, v in pairs(categories) do
		if k == "none" then
			-- Loop through the items.
			for k2, v2 in pairs(v) do
				self.currentItem = v2

				local item = vgui.Create("arista_accessItem", self)
				self.itemsList:AddItem(item)
			end
		else
			local c
			if kind == "Teams" then
				c = arista.team.get(k)
			elseif kind == "Groups" then
				c = arista.team.getGroup(k)
			end

			local header = vgui.Create("DCollapsibleCategory", self)
				header:SetSize(width / 2, 50) -- Keep the second number at 50
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
				self.nobut = false

				if v2[4] == arista.lp:UserID() and self.type == "player" or not accessmenu.owned then
					self.nobut = true
				end

				-- Add the item to the item list.
				local item = vgui.Create("arista_accessItem", self)
				subitemsList:AddItem(item)
			end
		end
	end

	-- Rebuild the items list.
	self.itemsList:Rebuild()
end

-- Register the panel.
vgui.Register("arista_accessInventory", PANEL, "Panel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	-- Set the size and position of the panel.
	self:SetSize(width / 2, 75)
	self:SetPos(1, 5)

	local typ = self:GetParent().type

	-- Set the item that we are.
	local name, model, description, uniqueID = unpack(self:GetParent().currentItem)
	self.action = self:GetParent().action

	-- Create a label for the name.
	self.name = vgui.Create("DLabel", self)
		self.name:SetText(name or "ERROR")
		self.name:SizeToContents()
		self.name:SetTextColor(color_black)

	-- Create a label for the description.
	self.description = vgui.Create("DLabel", self)
		self.description:SetText(description or "ERROR")
		self.description:SizeToContents()
		self.description:SetTextColor(color_black)

	-- Create the spawn icon.
	self.spawnIcon = vgui.Create("SpawnIcon", self)

	-- Set the model of the spawn icon to the one of the item.
	self.spawnIcon:SetModel(model)

	self.spawnIcon:SetToolTip()

	self.spawnIcon.DoClick = function() return end
	self.spawnIcon.OnMousePressed = function() return end

	self.itemFunctions = {}
		self.itemFunctions[1] = self.action

	-- Create the table to store the item buttons.
	self.itemButton = {}

	if self:GetParent().nobut then return end

	-- Loop through the item functions.
	for i = 1, #self.itemFunctions do
		if self.itemFunctions[i] then
			self.itemButton[i] = vgui.Create("DButton", self)
				self.itemButton[i]:SetText(self.itemFunctions[i])
				self.itemButton[i].DoClick = function()
					if not checkPos() then return end
					if accessmenu.buttoned then return end -- If a button has been pressed, we can't do anything until sent an update.

					RunConsoleCommand("arista", "entity", self.itemFunctions[i]:lower(), typ, uniqueID or "ERROR")

					CurTab = accessmenu.sheets:GetActiveTab()
					accessmenu.buttoned = true
				end
		end
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.spawnIcon:SetPos(4, 5)

	self.name:SizeToContents()

	self.description:SetPos(75, 24);
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
vgui.Register("arista_accessItem", PANEL, "DPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	-- Create the space used label.
	self.word = self.word or "argh"

	self.spaceUsed = vgui.Create("DLabel", self)
		self.spaceUsed:SetText(self.word)
		self.spaceUsed:SizeToContents()
		self.spaceUsed:SetTextColor(color_black)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	-- Set the position of the label.
	self.spaceUsed:SetPos((self:GetWide() / 2) - (self.spaceUsed:GetWide() / 2), 5)
	self.spaceUsed:SetText(self.word)
	self.spaceUsed:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_accessInformation", PANEL, "DPanel")

-- Define a new panel.
PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	self.noaccess					= vgui.Create("arista_accessInventory", self)
	self.access						= vgui.Create("arista_accessInventory", self)
	self.noaccess.action	= "Give"
	self.noaccess.name		= "Choices"
	self.access.action		= "Take"
	self.access.name			= "Access List"
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22.5, 0, 0)

	-- Set the position of both lists
	self.noaccess:SetPos(0, 0)
	self.access:SetPos(0 + self.noaccess:GetWide() + 4, 0)
end

-- Register the panel.
vgui.Register("arista_accessColumns", PANEL, "Panel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetTitle("Container")
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

	self.sheets		= vgui.Create("DPropertySheet", self)
		self.players	= vgui.Create("arista_accessColumns", self.sheets)
		self.jobs			= vgui.Create("arista_accessColumns", self.sheets)
		self.gangs		= vgui.Create("arista_accessColumns", self.sheets)

	self.sheets:AddSheet("Players",	self.players,	nil, nil, true)
	self.sheets:AddSheet("Jobs",		self.jobs,		nil, nil, true)
	self.sheets:AddSheet("Gangs",		self.gangs,		nil, nil, true)

	self.texbox	= vgui.Create("DTextEntry",	self)
	self.setbut = vgui.Create("DButton",	self)
		self.setbut:SetText("Set Name")

	local function setName()
		val = self.texbox:GetValue()

		if not val or val == "" then return end

		RunConsoleCommand("arista", "entity", "name", val:sub(1, 32))

		self.texbox:SetText("")
		self.texbox:KillFocus()
	end

	self.texbox.OnEnter = setName
	self.setbut.DoClick = setName

	self.selbut = vgui.Create("DButton",	self)
		self.selbut:SetText("Sell")
		self.selbut.DoClick = function()
			local menu = DermaMenu();

			-- Add an option for yes and no.
			menu:AddOption("No", function() end);
			menu:AddOption("Yes", function()
				RunConsoleCommand("arista", "door", "sell")

				accessmenu:Close()
				accessmenu:Remove()

				gui.EnableScreenClicker(false)
			end)

		-- Open the menu.
		menu:Open()
	end

	-- Capture the position of the local player.
	localPlayerPosition = arista.lp:GetPos()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:SetSize(width, height)
	self:SetPos((ScrW() - width) / 2, (ScrH() - height) / 2)
	self.close:SetSize(48, 16)
	self.selbut:SetSize(48, 16)
	self.setbut:SetSize(60, 16)
	self.texbox:SetSize(self:GetWide()/ 4, 16)
	self.texbox:SetPos(self:GetWide()/ 2 + 2, 27)
	self.setbut:SetPos(self:GetWide()/ 2 + 2 + self.texbox:GetWide() + 5, 27)
	self.selbut:SetPos(self:GetWide() - self.selbut:GetWide() - 10,	27)
	self.close:SetPos(self:GetWide() - self.close:GetWide() - 10, 3)
	self.texbox:SetVisible(false)
	self.setbut:SetVisible(false)
	self.selbut:SetVisible(false)

	if accessmenu.owned then
		if accessmenu.name then
			self.texbox:RequestFocus()
			self.texbox:SetVisible(true)
			self.setbut:SetVisible(true)
		end
		if accessmenu.sellable then
			self.selbut:SetVisible(true)
		end
	else
	end

	self.sheets:SetPos(8, 25)
	self.sheets:StretchToParent(8,25,8,8)
	self.sheets:InvalidateLayout()

	-- Check if the local player's position is different from our captured one.
	checkPos()

	-- Perform the layout of the main frame.
	DFrame.PerformLayout(self)
end

-- Register the panel.
vgui.Register("arista_access", PANEL, "DFrame")

local function updateContainer(decoded)
	if not (accessmenu and ValidPanel(accessmenu)) then return end
	width, height = ScrW() * 0.75, ScrH() * 0.75

	accessmenu:SetTitle(decoded.owner)

	local paccess = {}
	local taccess = {}
	local gaccess = {}

	for _, v in ipairs(decoded.access) do
		if type(v) == "Player" then
			paccess[v:EntIndex()] = v
		elseif type(v) == "number" then
			taccess[v] = cider.team.get(v)
		elseif type(v) == "string" then
			local a, b = unpack(v:Split(";"))
			a, b =  tonumber(a), tonumber(b)

			if a and b then gaccess[v] = table.Copy(arista.team.gangs[a][b]) end
		end
	end

	local pnoaccess = {}
	local tnoaccess = {}
	local gnoaccess = {}

	for _, v in ipairs(player.GetAll()) do
		if not paccess[v:EntIndex()] then
			pnoaccess[v:EntIndex()] = v
		end
	end

	for _,v in pairs(arista.team.stored) do
		if not taccess[v.index] then
			tnoaccess[v.index] = v
		end
	end

	for group, gangtable in pairs(arista.team.gangs) do
		for gang, data in ipairs(gangtable) do
			if not gaccess[group..";"..gang] then
				gnoaccess[group..";"..gang] = table.Copy(data)
			end
		end
	end

	accessmenu.players.noaccess.inventory		= pnoaccess
	accessmenu.players.access.inventory			= paccess
	accessmenu.jobs.noaccess.inventory			= tnoaccess
	accessmenu.jobs.access.inventory				= taccess
	accessmenu.gangs.noaccess.inventory			= gnoaccess
	accessmenu.gangs.access.inventory				= gaccess
	accessmenu.players.noaccess.updatePanel	= true
	accessmenu.players.access.updatePanel		= true
	accessmenu.jobs.noaccess.updatePanel		= true
	accessmenu.jobs.access.updatePanel			= true
	accessmenu.gangs.noaccess.updatePanel		= true
	accessmenu.gangs.access.updatePanel			= true

	accessmenu.owned = tobool(decoded.owned)

	if accessmenu.owned then
		accessmenu.sellable = decoded.owned.sellable
		accessmenu.name = decoded.owned.name
	end

	accessmenu:InvalidateLayout()
	accessmenu.buttoned = false
end

function newContainer()
	local decoded = net.ReadTable()

	if accessmenu then accessmenu:Remove() end
	accessmenu = vgui.Create("arista_access")

	gui.EnableScreenClicker(true)

	accessmenu:MakePopup()
	updateContainer(decoded)
end

function updateCatch()
	local decoded = net.ReadTable()

	updateContainer(decoded)
end

net.Receive("arista_Access", newContainer)
net.Receive("arista_AccessUpdate", updateCatch)
