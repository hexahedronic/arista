local PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(arista.derma.menu.width, arista.derma.menu.height - 8)
	arista.lp._nextChangeTeam = arista.lp._nextChangeTeam or {}

	-- Create a panel list to store the items.
	self.itemsList = vgui.Create("DPanelList", self)
		self.itemsList:SizeToContents()
		self.itemsList:SetPadding(2)
		self.itemsList:SetSpacing(3)
		self.itemsList:StretchToParent(4, 4, 12, 44)
		self.itemsList:EnableVerticalScrollbar()

	-- We'll do the rest in the think func
	arista.team.changed = true
end

function PANEL:Think()
	if self:GetWide() < 32 then self:InvalidateLayout(true) return end
	if not arista.team.changed then return end
	if not arista.client._modelChoices then return end

	arista.team.changed = false

	local lgroup = arista.team.getGroupByTeam(arista.lp:Team())

	-- Wipe the itemlist so we can renew it
	self.itemsList:Clear()

	-- Create the job control.
	self.rpname = vgui.Create("arista_characterTextEntry", self)
		self.rpname.label:SetText(arista.lang:Get"AL_DERMA_NAME")
		self.rpname.label:SizeToContents()
		self.rpname.button:SetText(arista.lang:Get"AL_DERMA_CHANGE")
		self.rpname.button.DoClick = function()
			RunConsoleCommand("arista", "name", self.rpname.textEntry:GetValue())
		end

		local name = arista.lp:rpName() or ""
		self.rpname.textEntry:SetValue(name)

	-- Create the job control.
	self.job = vgui.Create("arista_characterTextEntry", self)
		self.job.label:SetText(arista.lang:Get"AL_DERMA_JOB")
		self.job.label:SizeToContents()
		self.job.button:SetText(arista.lang:Get"AL_DERMA_CHANGE")
		self.job.button.DoClick = function()
			RunConsoleCommand("arista", "job", self.job.textEntry:GetValue())
		end

		local job = arista.lp:getJob() or ""
		self.job.textEntry:SetValue(job)

	-- Create the clan control.
	self.clan = vgui.Create("arista_characterTextEntry", self)
		self.clan.label:SetText(arista.lang:Get"AL_DERMA_CLAN")
		self.clan.label:SizeToContents()
		self.clan.button:SetText(arista.lang:Get"AL_DERMA_CHANGE")
		self.clan.button.DoClick = function()
			RunConsoleCommand("arista", "clan", self.clan.textEntry:GetValue())
		end

		local clan = arista.lp:getClan() or ""
		self.clan.textEntry:SetValue(clan)

	-- Create the details control.
	self.details = vgui.Create("arista_characterTextEntry", self)
		self.details.label:SetText(arista.lang:Get"AL_DERMA_DETAILS")
		self.details.label:SizeToContents()
		self.details.button:SetText(arista.lang:Get"AL_DERMA_CHANGE")
		self.details.button.DoClick = function()
			RunConsoleCommand("arista", "details", self.details.textEntry:GetValue())
		end

		local details = arista.lp:getDetails() or ""
		self.details.textEntry:SetValue(details)

	-- Create the gender control.
	self.gender = vgui.Create("arista_characterGender", self)
		self.gender.label:SetText(arista.lang:Get"AL_DERMA_GENDER")
		self.gender.label:SizeToContents()
		self.gender.button:SetText(arista.lang:Get"AL_DERMA_CHANGE")

	-- Add the controls to the item list.
	self.itemsList:AddItem(self.rpname)
	self.itemsList:AddItem(self.job)
	self.itemsList:AddItem(self.clan)
	self.itemsList:AddItem(self.details)
	self.itemsList:AddItem(self.gender)

	--Store the list of groups here sorted by index
	local groups = {}
	for k, v in pairs(arista.team.storedgroups) do groups[v.index] = v end

	-- Loop through each of our groups
	for index, group in ipairs(groups) do
		local header = vgui.Create("QCollapsibleCategory", self)
			header:SetSize(arista.derma.menu.width, 50) -- Keep the second number at 50
			header:SetLabel(group.name)
			header:SetExpanded(lgroup == group)
			header:SetToolTip(group.description)
		self.itemsList:AddItem(header)

		local subitemsList = vgui.Create("DPanelList", self)
			subitemsList:SetAutoSize(true)
			subitemsList:SetPadding(2)
			subitemsList:SetSpacing(3)
			header:SetContents(subitemsList)
		header.ilist = subitemsList

		-- Store the list of teams here sorted by their index.
		local teams = {}

		-- Loop through the available teams.
		for k, v in pairs(group.teams) do
			teams[k] = arista.team.get(v)
		end

		-- Loop through our sorted teams.
		for k, v in ipairs(teams) do
			self.currentTeam = v.name

			--Check they can join the team
			if gamemode.Call("PlayerCanJoinTeamShared", arista.lp, v.index) then
				-- Create the team panel.
				local panel = vgui.Create("arista_characterTeam", self)

				-- Set the text of the label.
				panel.label:SetText(v.name.." ("..team.NumPlayers(v.index).."/"..v.limit..")")
				panel.label.Think = function()
					panel.label:SetText(v.name.." ("..team.NumPlayers(v.index).."/"..v.limit..")")
					panel.label:SizeToContents()
				end

				panel.description:SetText(v.description)
				panel.button:SetText(arista.lang:Get"AL_DERMA_BECOME")
				panel.button.Think = function()
					if arista.lp:Team() == v.index then
						panel.button:SetDisabled(true)
						panel.button:SetText(arista.lang:Get"AL_DERMA_JOINED")
					else
						local nextChange = arista.lp._nextChangeTeam[v.index]

						if team.NumPlayers(v.index) >= v.limit then
							panel.button:SetDisabled(true)
							panel.button:SetText(arista.lang:Get"AL_DERMA_FULL")
						elseif nextChange and nextChange > CurTime() then
							local time = " " .. string.ToMinutesSeconds(nextChange - CurTime())

							panel.button:SetDisabled(true)
							panel.button:SetText(arista.lang:Get"AL_DERMA_WAIT" .. time)
						else
							panel.button:SetDisabled(false)
							panel.button:SetText(arista.lang:Get"AL_DERMA_BECOME")
						end
					end
				end

				panel.button.DoClick = function()
					RunConsoleCommand("arista", "team", v.index)
				end

				-- Add the controls to the item list.
				subitemsList:AddItem(panel)
			end
		end
	end

	self.itemsList:Rebuild()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22, 0, 0)
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Register the panel.
vgui.Register("arista_character", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
		self.label:SizeToContents()
		self.label:SetTextColor(color_white)

	self.textEntry = vgui.Create("QTextEntry", self)

	-- Create the button.
	self.button = vgui.Create("QButton", self)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.label:SetPos(8, 5)
	self.label:SizeToContents()

	self.button:SizeToContents()
	self.button:SetTall(16)
	self.button:SetWide(self.button:GetWide() + 16)

	self.textEntry:SetSize(self:GetWide() - self.button:GetWide() - self.label:GetWide() - 32, 16)
	self.textEntry:SetPos(self.label.x + self.label:GetWide() + 8, 5)

	self.button:SetPos(self.textEntry.x + self.textEntry:GetWide() + 8, 5)
end

-- Register the panel.
vgui.Register("arista_characterTextEntry", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
		self.label:SizeToContents()
		self.label:SetTextColor(color_white)

	self.textButton = vgui.Create("QButton", self)
		self.textButton:SetDisabled(true)

	-- Create the button.
	self.button = vgui.Create("QButton", self)
	self.button.DoClick = function()
		local menu = DermaMenu()

		-- Add male and female options to the menu.
		menu:AddOption(arista.lang:Get"AL_MALE", function() RunConsoleCommand("arista", "gender", "male") end)
		menu:AddOption(arista.lang:Get"AL_FEMALE", function() RunConsoleCommand("arista", "gender", "female") end)

		-- Open the menu and set it's position.
		menu:Open()
	end
end

-- Called every frame.
function PANEL:Think()
	self.textButton:SetText(arista.lp:getGender() or arista.lang:Get"AL_MALE")
	self.textButton:SetContentAlignment(5)
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.label:SetPos(8, 5)
	self.label:SizeToContents()

	self.button:SizeToContents()
	self.button:SetTall(16)
	self.button:SetWide(self.button:GetWide() + 16)

	self.textButton:SetSize(self:GetWide() - self.button:GetWide() - self.label:GetWide() - 32, 16)
	self.textButton:SetPos(self.label.x + self.label:GetWide() + 8, 5)

	self.button:SetPos(self.textButton.x + self.textButton:GetWide() + 8, 5)
end

-- Register the panel.
vgui.Register("arista_characterGender", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
	self.label:SetTextColor(color_white)

	-- The description of the team.
	self.description = vgui.Create("DLabel", self)
	self.description:SetTextColor(color_white)

	-- Set the size of the panel.
	self:SetSize(arista.derma.menu.width, 75)

	-- Create the button and the spawn icon.
	self.button = vgui.Create("QButton", self)
	self.spawnIcon = vgui.Create("SpawnIcon", self)

	-- Get the team from the parent and set the gender of the spawn icon.
	self.team = self:GetParent().currentTeam
	self.gender = "Male"

	local gender = "male"

	local team = arista.team.stored[self.team]
	local name = team.index
	local models = team.models[gender]
	local modelChoice = arista.client._modelChoices[gender]

	local model = models[arista.client._modelChoices[gender][name]]

	-- Set the model of the spawn icon to the one of the team.
	self.spawnIcon:SetModel(model)
	self.spawnIcon:SetToolTip()
	self.spawnIcon.DoClick = function() return end
	self.spawnIcon.OnMousePressed = function() return end
end

-- Called every frame.
local done = false
function PANEL:Think()
	local gender = arista.lp:getAristaString("nextGender") or ""

	-- Check if the next spawn gender is valid.
	if gender == "" then gender = arista.lp:getGender() end
	if gender == "" then gender = "Male" end

	-- Check if our gender is different.
	if self.gender ~= gender or not done then
		local gender, name = gender:lower(), arista.team.query(self.team, "index", 1)

		local models = arista.team.stored[self.team].models[gender]
		local genModel = arista.client._modelChoices[gender]
		if not models or not genModel then return end

		local model = models[genModel[name]]

		-- Set the model to our randomly selected one.
		self.spawnIcon:SetModel(model)

		-- We've changed our gender now so set it to this one.
		self.gender = gender
		done = true
	end
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
vgui.Register("arista_characterTeam", PANEL, "QPanel")
