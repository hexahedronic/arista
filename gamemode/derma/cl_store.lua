local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.team = arista.lp:Team()
	self.headers = {}
	self:SetSize(arista.derma.menu.width, arista.derma.menu.height - 8)

	-- Create a panel list to store the items.
	self.itemsList = vgui.Create("DPanelList", self)
		self.itemsList:SizeToContents()
		self.itemsList:SetPadding(2)
		self.itemsList:SetSpacing(3)
		self.itemsList:StretchToParent(4, 4, 12, 44)
		self.itemsList:EnableVerticalScrollbar()

	-- Create a table to store the categories.
	local categories = {}

	-- Loop through the items
	for k, v in pairs(arista.item.items) do
		if v.store and v.cost and v.batch then
			local cat = v.category

			if cat and GAMEMODE:GetCategory(cat) then
				categories[cat] = categories[cat] or {}

				-- Insert the item into the category table.
				table.insert(categories[cat], k)
			else
				categories.none = categories.none or {}

				table.insert(categories.none, k)
			end
		end
	end
	-- Loop through the categories.
	for k, v in pairs(categories) do
		if k == "none" then
			table.sort(v, function(a, b) return arista.item.items[a].cost > arista.item.items[b].cost end)

			-- Loop through the items.
			for k2, v2 in pairs(v) do
				self.currentItem = v2

				-- Add the item to the item list.
				self.itemsList:AddItem(vgui.Create("arista_storeItem", self))
			end
		else
			local c = GAMEMODE:GetCategory(k)

			if not c.noShow then -- If the category doesn't want to show up (like it's plugin is missing) then don't show it.
				self.headers[k] = vgui.Create("QCollapsibleCategory", self)
					self.headers[k]:SetSize(arista.derma.menu.width, 50) -- Keep the second number at 50
					local canMake = arista.team.query(self.team, "canmake")
					if not canMake then
						arista.logs.log(arista.logs.E.DEBUG, "ERROR FETCHING JOB CANMAKE!")
						canMake = {}
					end
					self.headers[k]:SetExpanded(table.HasValue(canMake, k)) -- Expanded when popped up
					self.headers[k]:SetLabel(c.name)
					self.headers[k]:SetTooltip(c.description)
				self.itemsList:AddItem(self.headers[k])

				local subitemsList = vgui.Create("DPanelList", self)
					subitemsList:SetAutoSize(true)
					subitemsList:SetPadding(2)
					subitemsList:SetSpacing(3)
				self.headers[k]:SetContents(subitemsList)

				-- Sort the items by cost.
				table.sort(v, function(a, b) return arista.item.items[a].cost > arista.item.items[b].cost end)

				-- Loop through the items.
				for k2, v2 in pairs(v) do
					self.currentItem = v2

					-- Add the item to the item list.
					subitemsList:AddItem(vgui.Create("arista_storeItem", self))
				end
			end
		end
	end
end

function PANEL:Think()
	local job = arista.lp:Team()

	if job ~= self.team then
		self.team = job

		for k, v in pairs(self.headers) do
			v:Toggle()
			v:SetExpanded(table.HasValue(arista.team.query(self.team, "canmake", {}), k))
		end
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22, 0, 0)
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Register the panel.
vgui.Register("arista_store", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.item = self:GetParent().currentItem

	local item = arista.item.items[self.item]
	-- Get the cost of the item in total.
	local cost = item.cost * item.batch

	-- The name of the item.
	self.label = vgui.Create("DLabel", self)
		self.label:SetTextColor(color_white)

	-- Check if it is not a single batch.
	if item.batch > 1 then
		self.label:SetText(item.batch .. " " .. item.plural.." (" .. arista.lang.currency .. cost .. ")")
	else
		self.label:SetText(item.batch .. " " .. item.name .. " (" .. arista.lang.currency .. cost .. ")")
	end

	-- The description of the item.
	self.description = vgui.Create("DLabel", self)
		self.description:SetTextColor(color_white)
		self.description:SetText(item.description)

	-- Set the size of the panel.
	self:SetSize(arista.derma.menu.width, 75)

	-- Create the button and the spawn icon.
	self.button = vgui.Create("QButton", self)
	self.spawnIcon = vgui.Create("SpawnIcon", self)

	-- Set the text of the button.
	self.button:SetText(arista.lang:Get"AL_DERMA_MANUFACTURE")
	self.button:SetSize(80, 22)
	self.button.DoClick = function()
		RunConsoleCommand("arista", "manufacture", self.item)
	end

	-- Set the model of the spawn icon to the one of the item.
	self.spawnIcon:SetModel(item.model, item.skin)
	self.spawnIcon:SetToolTip()
	self.spawnIcon.DoClick = function() return end
	self.spawnIcon.OnMousePressed = function() return end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.spawnIcon:SetPos(4, 5)
	self.label:SetPos(self.spawnIcon.x + self.spawnIcon:GetWide() + 8, 5)
	self.label:SizeToContents()
	self.description:SetPos(self.spawnIcon.x + self.spawnIcon:GetWide() + 8, 24)
	self.description:SizeToContents()
	self.button:SetPos(self.spawnIcon.x + self.spawnIcon:GetWide() + 8, self.spawnIcon.y + self.spawnIcon:GetTall() - self.button:GetTall())
end

-- Register the panel.
vgui.Register("arista_storeItem", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
		self.label:SetText("N/A")
		self.label:SizeToContents()
		self.label:SetTextColor(color_white)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.label:SetPos((self:GetWide() / 2) - (self.label:GetWide() / 2), 5)
	self.label:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_storeHeader", PANEL, "QPanel")
