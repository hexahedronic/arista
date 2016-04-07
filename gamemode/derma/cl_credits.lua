local PANEL = {}

-- Never remove anyone from here, you can insert yourself if you make significant contributions though.
-- Store the credits in a string.
PANEL.credits = [[
[Arista Credits;color_highpink]
Q2F2 - Rewriting almost the entirety of Applejack, fixing it for Gmod13, replacing deprecated functions ect.
Ghosty - Good friend, being a drama causing retard, helping with ideas, various code.
Liquid - Good friend, finding bugs, various code.
Trixter - Good friend, various code.
[Arista Testers;color_highpink]
Frumorn - 'That one gay retard'
[Applejack Credits;color_lightblue]
kuromeku - kuromeku@gmail.com - http://conna.org - Made the core systems of Cider, populated it with items and released it.
Lexi - mwaness@gmail.com - http://www.ventmob.com/ - Vast swathes of improvements to the script, going with the philosophy that "Light RP doesn't have to be shit."
Drewley - http://www.ventmob.com/ - Hosting the VM server that this script was born on, minor edits.
Jayhawk - www.thebluecommunity.com - Creating awesome textures
[Works included in modified form;color_lightblue]
-[SB]- Spy - The SMod Leg SWep
NoVa - VU Mod
High6 - Door STool
Athos - The corvette and golf
Spacetech - Simple Prop Protection
Kogitsune - Various
[Applejack Thanks;color_lightblue]
The various people of the Lua section of Facepunch - Helping me fix stuff
Drewley - For providing the server, various tools and suggestions that got Applejack to what it is today
Clown, Kizai, Vaut - Suggestions
jDog - More suggestions than I ever want to read
Deamie - Managing to out-do jDog
Stephanov - Finding map exploits, being awsum, tester
Hawkace - Some food based suggestions
Snake Logan - Finding me models when I'm too lazy do it myself
Cuttlefish - Spent $1,000,000 on an alien ballsack
||VM|| Server population - Being my labrats and helping me isolate bugs
kuromeku - For being my inspiration, doing things that started me doing srs lua coding, for writing scripts that I admire and give me something to live up to, for releasing Cider into the public and for being such a retarded asshole and banning me, thus allowing me to start work on this project.
[Applejack Testers;color_lightblue]
(If you have done beta testing on the test server and are not on here, pm me)
Thorium
iShot
TJjokerR
Crillz
Brother Correcticus
Stephanov
Chronic
MartinP
Frosty
deathstar
]]

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

	-- Get the exploded text.
	local exploded = self.credits:Split("\n")
	local credits = {}
	local key = 0

	-- Loop through our credits.
	for k, v in ipairs(exploded) do
		if k < #exploded or v ~= "" then
			if v[1] == "[" and v:sub(-1) == "]" then
				key = key + 1
				v = v:Split(";")

				local colorstring = v[2]:sub(1, -2)

				-- Insert a new credits title.
				credits[key] = {title = v[1]:sub(2), color = _G[colorstring], credits = {}}
			else
				if credits[key] then
					local wrapped = {}

					-- Wrap the text to the width of the menu.
					arista.chatbox.wrapText(v, "Default", arista.derma.menu.width - 48, 0, wrapped)

					-- Loop through the wrapped text.
					for k2, v2 in pairs(wrapped) do
						table.insert(credits[key].credits, v2)
					end
				end
			end
		end
	end

	-- Loop through our credits.
	for k, v in pairs(credits) do
		local header = vgui.Create("arista_creditsHeader", self)

		-- Set the text of the header label and add it to the item list.
		header.label:SetText(v.title)
		header.label:SetTextColor(v.color)
		self.itemsList:AddItem(header)

		-- Create the text for this title.
		local text = vgui.Create("arista_creditsText", self)

		-- Set the credits for this title and add it to the item list.
		text:SetText(v.credits)
		self.itemsList:AddItem(text)
	end
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self:StretchToParent(0, 22, 0, 0)
	self.itemsList:StretchToParent(0, 0, 0, 0)
end

-- Register the panel.
vgui.Register("arista_credits", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.labels = {}
end

-- Set Text.
function PANEL:SetText(text)
	for k, v in pairs(self.labels) do
		v:Remove()
	end

	-- Define our x and y positions.
	local y = 5

	-- Loop through the text we're given.
	for k, v in pairs(text) do
		local label = vgui.Create("DLabel", self)

		-- Set the text of the label.
		label:SetText(v)
		label:SetTextColor(color_white)
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
vgui.Register("arista_creditsText", PANEL, "QPanel")

-- Define a new panel.
PANEL = {}

-- Called when the panel is initialized.
function PANEL:Init()
	self.label = vgui.Create("DLabel", self)
		self.label:SetText("N/A")
		self.label:SetFont("ChatFont")
		self.label:SetTextColor(color_white)
		self.label:SizeToContents()
end

-- Called when the layout should be performed.
function PANEL:PerformLayout()
	self.label:SetPos(self:GetWide() / 2 - self.label:GetWide() / 2, self:GetTall() / 2 - self.label:GetTall() / 2)
	self.label:SizeToContents()
end

-- Register the panel.
vgui.Register("arista_creditsHeader", PANEL, "QPanel")
