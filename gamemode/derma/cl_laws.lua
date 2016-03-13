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
end

function PANEL:Think()
	if arista.laws.update then return end
	arista.laws.update = false

	-- Get the asploded text.
	local asploded = string.Explode("\n", arista.config:getDefault("laws"))

	for k,v in ipairs(arista.laws.stored) do
		table.insert(asploded, v)
	end

	local laws = {}
	local key = 0
	self.itemsList:Clear()
	-- Loop through our laws.
	for k, v in pairs(asploded) do
		if (k < #asploded or v ~= "") then
			if (string.sub(v, 1, 1) == "[" and string.sub(v, -1) == "]") then
				key = key + 1

				-- Insert a new laws title.
				laws[key] = { title = string.sub(v, 2, -3), laws = {}, editable = tobool(string.sub(v, -3, -3)) }
			else
				if ( laws[key] ) then
					local wrapped = {}

					-- Wrap the text to the width of the menu.
					cider.chatBox.wrapText(v, "Default", arista.derma.menu.width - 48, 0, wrapped)

					-- Loop through the wrapped text.
					for k2, v2 in pairs(wrapped) do
						if v2 ~= "" then
							table.insert(laws[key].laws, v2)
						end
					end
				end
			end
		end
	end

	-- Loop through our laws.
	for k, v in pairs(laws) do
		local header = vgui.Create("arista_laws_Header", self)

		-- Tell the header if it's text is editable.
		--header.edit( v.editable )

		-- Set the text of the header label and add it to the item list.
		header.label:SetText(v.title) self.itemsList:AddItem(header)

		-- Create the text for this title.
		local text = vgui.Create("arista_laws_Text", self)

		-- Set the laws for this title and add it to the item list.
		text:SetText(v.laws) self.itemsList:AddItem(text)
	end
	if LocalPlayer():IsAdmin() or LocalPlayer():Team() == TEAM_MAYOR then
		local button = vgui.Create("DButton", self)
		button._NextPress = CurTime()
		button:SetText("Edit")
		button.DoClick = function()
			if button._NextPress > CurTime() then
				return false
			end
			button._NextPress = CurTime() + 120
			local EditPanel = vgui.Create( "DFrame" )
			EditPanel:SetPos( (ScrW()- 400)/2,(ScrH() -500)/2 )
			EditPanel:SetSize( 400 ,265 )
			EditPanel:SetTitle( "Edit the City Laws" )
			EditPanel:SetVisible( true )
			EditPanel:SetDraggable( true )
			EditPanel:ShowCloseButton( true )
			EditPanel:MakePopup()
			boxes = {}
			y = 28
			for i = 1,10 do
				boxes[i] = vgui.Create("DTextEntry",EditPanel)
				boxes[i]:SetPos(10,y)
				boxes[i]:SetValue(cider.laws.stored[i])
				boxes[i]:SetSize(EditPanel:GetWide()-20,16)
				y = y + boxes[i]:GetTall() + 5
			end
			local savebutton = vgui.Create("DButton",EditPanel)
			savebutton:SetText("Save")
			savebutton.DoClick = function()
				--[[text = ""
				for k,v in pairs(boxes) do
					val = v:GetValue()
					if string.len(val) > 80 then
						val = string.sub(val,1,80)
					end
					text = text..string.Replace(string.Replace(val,"#","")," ","_").."#"
				end
				text = string.sub(text,1,-2)
				RunConsoleCommand("cider", "laws", text)]]
				local tab = {}
				local diff = false
				for k,v in ipairs(boxes) do
					tab[k] = v:GetValue()
					if tab[k] ~= cider.laws.stored[k] then
						diff = true
					end
				end
				--PrintTable(tab)
				if diff then
					datastream.StreamToServer( "arista_Laws",tab)
				end
				EditPanel:Close()
				button._NextPress = CurTime() + 120
			end
			savebutton:SetPos(EditPanel:GetWide()-savebutton:GetWide()-10,y)--[[
			y = y + button:GetTall() + 5
			print (y)]]
		end
		self.itemsList:AddItem(button)
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22, 0, 0)
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Register the panel.
vgui.Register("arista_laws", PANEL, "Panel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init() self.labels = {} end

-- Set Text.
function PANEL:SetText(text)
	for k, v in pairs(self.labels) do v:Remove() end

	-- Define our x and y positions.
	local y = 5

	-- Loop through the text we're given.
	for k, v in pairs(text) do
		local label = vgui.Create("DLabel", self)

		-- Set the text of the label.
		label:SetText( v )
		label:SetTextColor(color_black)
		label:SizeToContents()

		-- Insert the label into our labels table.
		table.insert(self.labels, label)

		-- Increase the y position.
		y = y + label:GetTall() + 8
	end

	-- Set the size of the panel.
	self:SetSize(arista.derma.menu.width, y)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	local y = 5

	-- Loop through all of our labels.
	for k, v in pairs(self.labels) do
		self.labels[k]:SetPos(8, y)

		-- Increase the y position.
		y = y + self.labels[k]:GetTall() + 8
	end
end

-- Register the panel.
vgui.Register("arista_lawsText", PANEL, "DPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
	self.label:SetText("N/A")
	self.label:SetFont("ChatFont")
	self.label:SetTextColor(color_black)
	self.label:SizeToContents()
end
-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.label:SetPos(self:GetWide() / 2 - self.label:GetWide() / 2, self:GetTall() / 2 - self.label:GetTall() / 2)
	self.label:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_lawsHeader", PANEL, "DPanel")
