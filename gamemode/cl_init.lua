-- arista: RolePlay FrameWork --
include("sh_init.lua")

arista.client = {}

-- Set some information for the gamemode.
arista.client.topTextGradient = {}
arista.client.moneyAlerts = {}
arista.client.ammoCount = {}
arista.client.vehiclelist = {}

arista.lp = LocalPlayer()

-- Define a fuckton of colours for efficient GC
--Solid Colours
color_green =			Color(050, 255, 050, 255)
color_red =				Color(255, 050, 050, 255)
color_orange =			Color(255, 125, 000, 255)
color_brightgreen =		Color(125, 255, 050, 255)
color_purpleblue =		Color(125, 050, 255, 255)
color_purple = 			Color(150, 075, 200, 255)
color_lightblue =		Color(075, 150, 255, 255)
color_pink =			Color(255, 075, 150, 255)
color_darkgray =		Color(025, 025, 025, 255)
color_lightgray =		Color(150, 150, 150, 255)
color_yellow =			Color(250, 230, 070, 255)

--Alpha'd
color_red_alpha =		Color(255, 050, 050, 200)
color_orange_alpha =	Color(240, 190, 060, 200)
color_lightblue_alpha =	Color(100, 100, 255, 200)
color_darkgray_alpha =	Color(025, 025, 025, 150)
color_black_alpha =		Color(000, 000, 000, 200)

net.Receive("arista_sendMapEntities", function()
	local amt = net.ReadUInt(16)

	for i = 1, amt do
		local ent = net.ReadEntity()

		arista._internaldata.entities[ent] = ent
	end
end)

net.Receive("arista_notify", function()
	local form = net.ReadString()
	local amt = net.ReadUInt(8)

	local args = {}
	for i = 1, amt do
		args[i] = net.ReadString(v)
	end

	form = arista.lang:Get(form)

	local msg = form:format(unpack(args))

	chat.AddText(color_white, msg)
end)

net.Receive("arista_moneyAlert", function()
	local alert = {
		add = 1,
		alpha = 255,
	}
	local amount = net.ReadInt()

	if amount < 0 then
		alert.color = color_red
		alert.text = tostring(amount)
	else
		alert.color = color_green
		alert.text = "+" .. amount
	end

	table.insert(arista.client.moneyAlerts, alert)
end)

function GM:OnAchievementAchieved( ply, achid )
	--cider.chatBox.chatText(ply:EntIndex(), ply:Name(), achievements.GetName(achid), "achievement")
end

-- Override the weapon pickup function.
function GM:HUDWeaponPickedUp(...) end

-- Override the item pickup function.
function GM:HUDItemPickedUp(...) end

-- Override the ammo pickup function.
function GM:HUDAmmoPickedUp(...) end

-- Called when all of the map entities have been initialized.
function GM:InitPostEntity()
	arista.utils.nextFrame(gamemode.Call, "LoadData") -- Tell plugins to load their datas a frame after this.

	arista._inited = true

	-- Call the base class function.
	return self.BaseClass:InitPostEntity()
end

-- ????????????
function GM:ForceDermaSkin()
end

-- Called when an entity is created.
function GM:OnEntityCreated(entity)
	if LocalPlayer() == entity then
		arista.lp = entity
	end

	-- Call the base class function.
	return self.BaseClass:OnEntityCreated(entity)
end

arista._playerInited = true

-- Called when a player presses a bind.
function GM:PlayerBindPress(player, bind, press)
	if not arista._playerInited and bind:find("+jump", 1, true) then
		RunConsoleCommand("retry")
	end

	-- Call the base class function.
	return self.BaseClass:PlayerBindPress(player, bind, press)
end

-- Check if the local player is using the camera.
function GM:IsUsingCamera()
	if not IsValid(arista.lp) then arista.lp = LocalPlayer() return false end

	local wep = arista.lp:GetActiveWeapon()

	if IsValid(wep) and wep:GetClass() == "gmod_camera" then
		return true
	else
		return false
	end
end

-- A function to override whether a HUD element should draw.
function GM:HUDShouldDraw(name)
	if not arista._playerInited and name ~= "CHudGMod" then
		return false
	elseif name == "CHudHealth" or name == "CHudBattery" or name == "CHudSuitPower" or  name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
		return false
	end

	-- Call the base class function.
	return self.BaseClass:HUDShouldDraw(name)
end

-- A function to adjust the width of something by making it slightly more than the width of a text.
function GM:AdjustMaximumWidth(font, text, width, addition, extra)
	surface.SetFont(font)

	-- Get the width of the text.
	local textWidth = surface.GetTextSize(tostring(text:gsub("&", "U"))) + (extra or 0)

	-- Check if the width of the text is greater than our current width.
	if textWidth > width then width = textWidth + (addition or 0) end

	-- Return the new width.
	return width
end

-- A function to draw a bar with a maximum and a variable.
function GM:DrawBar(font, x, y, width, height, color, text, maximum, variable, bar)
	draw.RoundedBox(2, x, y, width, height, color_black_alpha)
	draw.RoundedBox(0, x + 2, y + 2, width - 4, height - 4, color_darkgray_alpha)
	draw.RoundedBox(0, x + 2, y + 2, math.Clamp(((width - 4) / maximum) * variable, 0, width - 4), height - 4, color )
	-- todo: render this manually, avoid un-needed math

	-- Set the font of the text to this one.
	surface.SetFont(font)

	-- Adjust the x and y positions so that they don't screw up.
	x = math.floor(x + (width / 2))
	y = math.floor(y + 1)

	-- Draw text on the bar.
	draw.DrawText(text, font, x + 1, y + 1, color_black, 1)
	draw.DrawText(text, font, x, y, color_white, 1)

	-- Check if a bar table was specified.
	if bar then bar.y = bar.y - height + 4 end
end

-- Get the bouncing position of the screen's center.
function GM:GetScreenCenterBounce(bounce)
	return ScrW() / 2, (ScrH() / 2) + 32 + (math.sin(CurTime()) * (bounce or 8))
end

-- Give the player a first-person view of their corpse
function GM:CalcView(pl, origin, angles, fov)
	if not IsValid(arista.lp) then arista.lp = LocalPlayer() return end

	-- Get their ragdoll
	local ragdoll = arista.lp:getAristaEntity("ragdoll")

	-- Check if it's valid
	if not IsValid(ragdoll) then
		return self.BaseClass:CalcView(pl, origin, angles, fov)
	end

	--find the eyes
	local eyes = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes") or 1)

	-- setup our view
	if not eyes then
		return self.BaseClass:CalcView(pl, origin, angles, fov)
	end

	local view = {
		origin = eyes.Pos,
		angles = eyes.Ang,
		fov = 90,
	}

	return view
end

function GM:HUDDrawTargetID()
	return false
end

function GM:AdjustPosForStupidEnts(ent, pos)
	if ent:IsPlayer() then
		if ent:InVehicle() then
			pos.z = pos.z + 32
		else
			pos.z = pos.z + 55
		end
	elseif ent:GetClass() == "prop_vehicle_jeep" then
		pos = pos + ent:GetUp() * 32
	end

	return pos
end

function GM:Tick()
	arista.client.vehiclelist = {}

	for _,v in ipairs(ents.GetAll()) do
		if v:IsVehicle() then
			arista.client.vehiclelist[#arista.client.vehiclelist+1] = v
		end
	end
end

-- Called when screen space effects should be rendered.
function GM:RenderScreenspaceEffects()
	if not IsValid(arista.lp) then arista.lp = LocalPlayer() return end

	local ply = arista.lp

	local modify = {}
	local color = 0.8
	local addr = 0

	local hp = ply:Health()
	local hpVal = (50 - hp) * 0.025

	-- Check if the player is low on health or stunned.
	if ply:isStunned() then
		color = 0.4
		DrawMotionBlur(0.1, 1, 0)
	elseif hp < 50 and ply._hideHealthEffects then
		if ply:Alive() then
			color = math.Clamp(color - hpVal, 0, color)
		else
			color = 1.13
			addr = 1
		end

		-- Draw the motion blur.
		DrawMotionBlur(math.Clamp(1 - hpVal, 0.1, 1), 1, 0)
	end

	-- Set some color modify settings.
	modify["$pp_colour_addr"] = addr
	modify["$pp_colour_addg"] = 0
	modify["$pp_colour_addb"] = 0
	modify["$pp_colour_brightness"] = 0
	modify["$pp_colour_contrast"] = 1
	modify["$pp_colour_colour"] = color
	modify["$pp_colour_mulr"] = 0
	modify["$pp_colour_mulg"] = 0
	modify["$pp_colour_mulb"] = 0

	if ply:isSleeping() then
		modify["$pp_colour_contrast"] = 0
	end

	-- Draw the modified color.
	DrawColorModify(modify)
end

-- Called when the scoreboard should be drawn.
function GM:HUDDrawScoreBoard()
	self.BaseClass:HUDDrawScoreBoard(player)

	-- Check if the player hasn't initialized yet.
	if not arista._playerInited then
		local w, h = ScrW(), ScrH()
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, w, h)

		-- Set the font of the text to Chat Font.
		surface.SetFont("ChatFont")

		-- Get the size of the loading text.
		local width, height = surface.GetTextSize("Loading!")

		-- Draw a rounded box for the loading text to go on.
		draw.RoundedBox(2, (w / 2) - (width / 2) - 8, (h / 2) - 8, width + 16, 30, color_darkgray)

		-- Draw the loading text in the middle of the screen.
		draw.DrawText("Loading!", "ChatFont", w / 2, h / 2, color_white, 1, 1)

		-- Let them know how to rejoin if they are stuck.
		draw.DrawText("Press 'Jump' to rejoin if you are stuck on this screen!", "ChatFont", w / 2, h / 2 + 32, color_red, 1, 1)
	end
end

-- Draw Information.
function GM:DrawInformation(text, font, x, y, color, alpha, left, callback, shadow)
	surface.SetFont(font)

	-- Get the width and height of the text.
	local width, height = surface.GetTextSize(text)
	if alpha then color.a = alpha end
	-- Check if we shouldn't left align it, if we have a callback, and if we should draw a shadow.
	if not left then x = x - (width / 2) end
	if callback then x, y = callback(x, y, width, height) end
	if shadow then draw.DrawText(text, font, x + 1, y + 1, Color(0, 0, 0, color.a)) end

	-- Draw the text on the player.
	draw.DrawText(text, font, x, y, color)

	-- Return the new y position.
	return y + height + 8
end

local matCache = {}
-- Draw the player's information.
function GM:DrawPlayerInformation()
	local ply = arista.lp

	local width = 0
	local height = 0

	-- Create a table to store the text.
	local text = {}
	local information = {}

	-- Insert the player's information into the text table.
	text[#text+1] = {"Gender: " .. ply:getGender(), "icon16/user"}
	text[#text+1] = {"Salary: $"..ply:getSalary(), "icon16/folder_go"}
	text[#text+1] = {"Money: $"..ply:getMoney(), "icon16/star"}
	text[#text+1] = {"Details: "..ply:getDetails(), "icon16/status_offline"}
	text[#text+1] = {"Clan: "..ply:getClan(), "icon16/group"}
	text[#text+1] = {"Job: "..ply:getJob(), "icon16/wrench"}
	-- todo: language

	-- Loop through each of the text and adjust the width.
	for k, v in ipairs(text) do
		local split = v[1]:Split(":")

		if split[2]:Trim() ~= "" then
			if v[2] then
				width = self:AdjustMaximumWidth("ChatFont", v[1], width, nil, 24)
			else
				width = self:AdjustMaximumWidth("ChatFont", v[1], width)
			end

			-- Insert this text into the information table.
			table.insert(information, v)
		end
	end

	-- Add 16 to the width and set the height of the box.
	width = width + 16
	height = (18 * #information) + 14

	-- The position of the information box.
	local x = 8
	local y = ScrH() - height - 8

	-- Draw a rounded box to put the information text onto.
	draw.RoundedBox(2, x, y, width, height, color_black_alpha)

	-- Increase the x and y position by 8.
	x = x + 8
	y = y + 8

	-- Draw the information on the box.
	for k, v in pairs(information) do
		local ico = v[2] .. ".png"

		if ico then
			self:DrawInformation(v[1], "ChatFont", x + 24, y, color_white, 255, true)

			if not matCache[ico] then
				matCache[ico] = Material(ico)
			end

			-- Draw the icon that respresents the text.
			surface.SetMaterial(matCache[ico])
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(x, y - 1, 16, 16)
		else
			self:DrawInformation(v[1], "ChatFont", x, y, color_white, 255, true)
		end


		-- Increase the y position.
		y = y + 18
	end

	-- Return the width and height of the box.
	return width, height
end

-- Draw the health bar.
function GM:DrawHealthBar(bar)
	local health = math.Clamp(arista.lp:Health(), 0, 100)

	-- Draw the health and ammo bars.
	self:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_red_alpha, "Health: " .. health, 100, health, bar)
end

-- Draw the timer bar.
function GM:DrawTimerBar(bar)
	--[[local percento = math.Clamp((tonumber(arista.lp._JobTimeExpire-CurTime())/tonumber(arista.lp._JobTimeLimit))*100, 0, 100);
	arista.lp._NextEnter = arista.lp._NextEnter or CurTime()
	self:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_orange_alpha, "Time Left: "..string.ToMinutesSeconds(math.floor(tonumber(arista.lp._JobTimeExpire)-CurTime())), 100, percento, bar);]]
end

-- Draw the ammo bar.
function GM:DrawAmmoBar(bar)
	local weapon = arista.lp:GetActiveWeapon()

	-- Check if the weapon is valid.
	if not IsValid(weapon) then return end

	local class = weapon:GetClass()
	local clipOne = weapon:Clip1()

	if not arista.client.ammoCount[class] then
		arista.client.ammoCount[class] = clipOne
	end

	-- Check if the weapon's first clip is bigger than the amount we have stored for clip one.
	if weapon:Clip1() > arista.client.ammoCount[class] then
		arista.client.ammoCount[class] = clipOne
	end

	local clipMaximum = arista.client.ammoCount[class]
	local clipAmount = arista.lp:GetAmmoCount(weapon:GetPrimaryAmmoType())

	-- Check if the maximum clip if above 0.
	if clipMaximum > 0 then
		self:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_lightblue_alpha, "Ammo: " .. clipOne .. " [" .. clipAmount .. "]", clipMaximum, clipOne, bar)
	end
end

-- Called when the bottom bars should be drawn.
function GM:DrawBottomBars(bar) end

-- Called when the top text should be drawn.
function GM:DrawTopText(text)
	-- Check if the player is warranted.
	if arista.lp:isWarranted() ~= "" then
		local warrantExpireTime = arista.lp:getAristaInt("warrantExpireTime") or 0

		-- Text which is extended to the notice.
		local extension = "."

		-- Check if the warrant expire time exists.
		if warrantExpireTime and warrantExpireTime > 0 then
			local seconds = math.floor(warrantExpireTime - CurTime())

			if seconds > 60 then
				extension = " which expires in " .. math.ceil(seconds / 60) .. " minute(s)."
			else
				extension = " which expires in "..seconds.." second(s)."
			end
		end

		-- Check the class of the warrant.
		if arista.lp:isWarranted() == "search" then
			text.y = self:DrawInformation("You have a search warrant" .. extension, "ChatFont", text.x, text.y, color_brightgreen, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
		elseif arista.lp:isWarranted() == "arrest" then
			text.y = self:DrawInformation("You have an arrest warrant" .. extension, "ChatFont", text.x, text.y, color_brightgreen, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
			-- todo: language
		end
	end

	-- Check if the player is arrested.
	if arista.lp:isArrested() then
		local unarrestTime = arista.lp:getAristaInt("unarrestTime") or 0

		-- Check if the unarrest time is greater than the current time.
		if unarrestTime > CurTime() then
			local seconds = math.floor(unarrestTime - CurTime())

			-- Check if the amount of seconds is greater than 0.
			if seconds > 0 then
				if seconds > 60 then
					text.y = self:DrawInformation("You will be unarrested in " .. math.ceil(seconds / 60) .. " minute(s).", "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
						return x - width - 8, y
					end)
				else
					text.y = self:DrawInformation("You will be unarrested in " .. seconds .. " second(s).", "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
						return x - width - 8, y
					end)
				end
			else
				text.y = self:DrawInformation("You are arrested.", "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
					return x - width - 8, y
				end)
			end
		else
			text.y = self:DrawInformation("You are arrested.", "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
		end
	end

	if arista.lp:isTied() then
		text.y = self:DrawInformation("You have been tied up!", "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
			return x - width - 8, y
		end)
	end

	-- Check if the player is wearing kevlar.
	if arista.lp:getAristaInt("scaleDamage") == 0.5 then
		text.y = self:DrawInformation("You are wearing kevlar which reduces damage by 50%.", "ChatFont", text.x, text.y, color_pink, 255, true, function(x, y, width, height)
			return x - width - 8, y
		end)
	end
end

-- Called every time the HUD should be painted.

function GM:HUDPaint()
	if not IsValid(arista.lp) then arista.lp = LocalPlayer() return end

	self:HUDPaintESP()

	-- Bypass the camera, show what server this was taken on.
	self:DrawInformation(arista.config.vars.serverWebsite, "ChatFont", ScrW(), ScrH(), color_white, 255, true, function(x, y, width, height)
		return x - width - 8, y - height - 8
	end)

	if self:IsUsingCamera() then return end

	-- Loop through the money alerts.
	for k, v in ipairs(arista.client.moneyAlerts) do
		v.alpha = math.Clamp(v.alpha - 1, 0, 255)
		v.add = v.add + 1

		-- Draw the money alert.
		self:DrawInformation(v.text, "ChatFont", ScrW(), ScrH() - 24 - v.add, v.color, v.alpha, true, function(x, y, width, height)
			return x - width - 8, y - height - 8
		end)

		-- Check if the alpha is 0.
		if v.alpha <= 0 then
			self.moneyAlerts[k] = nil
		end
	end

	-- Get the size of the information box.
	local width, height = self:DrawPlayerInformation()

	-- A table to store the bar and text information.
	local bar = {x = width + 16, y = ScrH() - 24, width = 144, height = 16}
	local text = {x = ScrW(), y = 8}

	-- Draw the player's health and ammo bars.
	if arista.lp:Health() < 90 then
		self:DrawHealthBar(bar)
	end

	self:DrawAmmoBar(bar)

	--[[if arista.lp._JobTimeExpire and tonumber(arista.lp._JobTimeExpire) > CurTime() then
		self:DrawTimerBar(bar)
	end]]
	-- todo: job bar

	-- Call a hook to let plugins know that we're now drawing bars and text.
	gamemode.Call("DrawBottomBars", bar)
	gamemode.Call("DrawTopText", text)

	-- Set the position of the chat box.
	--cider.chatBox.position = {x = 8, y = math.min(bar.y + 20, ScrH() - height - 8) - 40};
	-- todo: chat

	-- Check if the next spawn time is greater than the current time.
	local x, y = self:GetScreenCenterBounce()
	y = y + 16

	local jump = input.LookupBinding("+jump")

	-- Get the player's next spawn time.
	local nextSpawnTime = arista.lp:getAristaInt("nextSpawnTime") or 0
	local goToSleepTime = arista.lp:getAristaInt("goToSleepTime") or 0
	local tying = arista.lp:getAristaInt("tying") or 0
	local beTied = arista.lp:getAristaBool("beTied") or false

	if not arista.lp:Alive() and nextSpawnTime > CurTime() then
		local seconds = math.floor(nextSpawnTime - CurTime())

		-- Check if the amount of seconds is greater than 0.
		if seconds > 0 then
			self:DrawInformation("You must wait " .. seconds .. " second(s) to spawn.", "ChatFont", x, y, color_white, 255)
		end
	elseif arista.lp:isUnconscious() and arista.lp:Alive() then
		local knockOutPeriod = arista.lp:getAristaInt("knockOutPeriod") or 0

		local text = "ERROR"

		-- Check if the unknock out time is greater than the current time.
		if knockOutPeriod > CurTime() then
			local seconds = math.floor(knockOutPeriod - CurTime())

			text = "You will be able to get up in " .. seconds .. " second(s)."
		elseif arista.lp:isSleeping() then
			text = "Press '" .. jump .. "' to wake up."
		elseif arista.lp:Alive() then
			text = "Press '" .. jump .. "' to get up."
		end

		self:DrawInformation(text, "ChatFont", x, y, color_white, 255)
	elseif goToSleepTime > CurTime() then
		local seconds = math.floor(goToSleepTime - CurTime())

		if seconds > 0 then
			self:DrawInformation("You will fall asleep in " .. seconds .. " second(s).", "ChatFont", x, y,  color_white, 255)
		end
	elseif tying > CurTime() then
		local seconds = math.floor(tying - CurTime())

		if seconds > 0 then
			self:DrawInformation("You will finish the knots in "..seconds.." second(s).", "ChatFont", x, y,  color_white, 255)
		end
	elseif beTied then
		self:DrawInformation("You are being tied up!", "ChatFont", x, y, color_white, 255)
	end

	-- Get whether the player is stuck in the world.
	local stuckInWorld --= arista.lp._StuckInWorld;
	-- todo: stuck

	-- Check whether the player is stuck in the world.
	if stuckInWorld then
		self:DrawInformation("You are stuck! Press '" .. jump .. "' to holster your weapons and respawn.", "ChatFont", ScrW() / 2, (ScrH() / 2) - 16, color_red, 255)
	end

	-- Loop through every player.
	for k, v in ipairs(player.GetAll()) do
		gamemode.Call("PlayerHUDPaint", v)
	end

	-- Call the base class function.
	self.BaseClass:HUDPaint()
end

-- Used to adjust ESP lines.
function GM:AdjustESPLines(lines, tent, pos, distance, lookingat)
end

-- Called for all players.
function GM:PlayerHUDPaint(ply)
end

/*
-- Called to check if a player can use voice.
function GM:PlayerCanVoice(player)
	do return false end
	if !player:IsValid() or !arista.lp:IsValid() then return false end
	if ( player:Alive()
	and player:GetPos():Distance( arista.lp:GetPos() ) <= self.Config["Talk Radius"]
	and !player:GetNetworkedBool("Arrested")
	and !player:KnockedOut() ) then
		return true;
	else
		return false;
	end
end

-- Stop players bypassing my post proccesses with theirs
function GM:PostProcessPermitted() return LocalPlayer():IsAdmin() end

-- Called every frame.
function GM:Think()
	if ( self.Config["Local Voice"] ) then
		for k, v in pairs( player.GetAll() ) do
			if ( hook.Call("PlayerCanVoice",GAMEMODE, v) ) then
				if ( v:IsMuted() ) then v:SetMuted(); end
			else
				if ( !v:IsMuted() ) then v:SetMuted(); end
			end
		end
	end

	-- Call the base class function.
	return self.BaseClass:Think();
end

-- Called when a player begins typing.
function GM:StartChat(team) return true; end

-- Called when a player says something or a message is received from the server.
function GM:ChatText(index, name, text, filter)
	if ( filter == "none" or filter == "joinleave" or (filter == "chat" and name == "Console") ) then
		cider.chatBox.chatText(index, name, text, filter);
	end

	-- Return true because we handle this our own way.
	return true;
end

local function iHasInitializedyay()
	if ValidEntity(LocalPlayer()) then
		GAMEMODE.playerInitialized = true
		if startupmenu:GetBool() then
			cider.menu.toggle()
		end
	else
		timer.Simple(0.2,iHasInitializedyay)
	end
end
-- Hook into when the player has initialized.
usermessage.Hook("cider.player.initialized", iHasInitializedyay);
--[[		umsg.Start("cider_ModelChoices")
		umsg.Short(#player._ModelChoices)
		for name,gender in pairs(player._ModelChoices) do
			umsg.String(name)
			umsg.Short(#gender)
			for team,choice in ipairs(gender) do
				umsg.Short(team)
				umsg.Short(choice)
			end
		end
		umsg.End()]]
	local errors = 0
	local maxerrors = GM.Config["Model Choices Timeout"]
local function CheckForInitalised(tab)

		if errors >= maxerrors then
			ErrorNoHalt"Something is very wrong - reconnecting!"
			RunConsoleCommand("retry");
		elseif errors == maxerrors/2 then
			ErrorNoHalt("Critical error! You have ".. maxerrors/2 .." seconds before your client reconnects!\n")
			ErrorNoHalt("LocalPlayer() is not a valid entity after "..errors.." seconds of gameplay!")
			ErrorNoHalt("LocalPlayer(): "..tostring(LocalPlayer()).."\n")
			ErrorNoHalt("---------------------------\n")
		end
		if !ValidEntity(LocalPlayer()) then
			errors = errors + 1
		--	ErrorNoHalt("LocalPlayer is invalid! ("..errors.."/"..maxerrors..")\n")
			return timer.Simple(1,CheckForInitalised,tab)
		end
		--if errors > 0 then ErrorNoHalt"Nevermind it works now...\n" end
		LocalPlayer()._ModelChoices = tab
	end
usermessage.Hook("cider_ModelChoices",function(msg)
	local tab = {}
	local length = msg:ReadShort() or 0
	for i=1, length do
		local gender = msg:ReadString() or ""
		tab[gender] = {}
		local leng = msg:ReadShort()
		for j = 1, leng do
			tab[gender][msg:ReadShort() or 0] = msg:ReadShort() or 0
		end
	end
	CheckForInitalised(tab)
end)

function GM:Initialize()
	ErrorNoHalt(os.date().." - Finished connecting\n")
	-- Call the base class function.
	return self.BaseClass:Initialize()
end

function GM:ForceDermaSkin()
	return self.BaseClass:ForceDermaSkin()
end
*/