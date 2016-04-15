-- arista: RolePlay FrameWork --

surface.CreateFont("arista_hud", {
	font = "Arial",--"Fira Sans",
	size = 17
})
surface.CreateFont("arista_hudSmall", {
	font = "Arial",--"Fira Sans",
	size = 14
})

surface.CreateFont("CSKillIcons", {
	font = "csd",
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	shadow = false,
	additive = true,
})

surface.CreateFont("CSSelectIcons", {
	font = "csd",
	size = 100,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = false,
	shadow = false,
	additive = true,
})

-- Stop showing loadingscreen when we refresh.
local set, cl
if arista and arista._playerInited then
	set = true
	cl = table.Copy(arista.client)
end

include("sh_init.lua")

arista.client = {}

if set then
	arista._playerInited = true
	arista.client = table.Copy(cl)

	cl = nil
end

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
color_highred =			Color(255, 075, 075, 255)
color_redorange =		Color(255, 150, 125, 255)
color_orange =			Color(255, 125, 000, 255)
color_brightgreen =		Color(125, 255, 050, 255)
color_highgreen =		Color(150, 225, 075, 255)
color_purpleblue =		Color(125, 050, 255, 255)
color_purple = 			Color(150, 075, 200, 255)
color_highblue =		Color(125, 200, 255, 255)
color_lightblue =		Color(075, 150, 255, 255)
color_pink =			Color(255, 075, 150, 255)
color_highpink =		Color(200, 150, 225, 255)
color_darkgray =		Color(025, 025, 025, 255)
color_lightgray =		Color(150, 150, 150, 255)
color_yellow =			Color(250, 230, 070, 255)
color_cream =			Color(255, 255, 150, 255)
color_darkgreen =       Color(030, 120, 045, 255)

--Alpha'd
color_red_alpha =		Color(255, 050, 050, 200)
color_orange_alpha =	Color(240, 190, 060, 200)
color_lightblue_alpha =	Color(100, 100, 255, 200)
color_darkgray_alpha =	Color(025, 025, 025, 150)
color_black_alpha =		Color(000, 000, 000, 200)
color_alpha =		Color(000, 000, 000, 000)

net.Receive("arista_sendMapEntities", function()
	local amt = net.ReadUInt(16)

	for i = 1, amt do
		local ent = net.ReadEntity()

		arista._internaldata.entities[ent] = ent
	end
end)

net.Receive("arista_notify", function()
	local inChat = net.ReadBool()
	local form = net.ReadString()
	local amt = net.ReadUInt(8)

	local args = {}
	for i = 1, amt do
		args[i] = arista.lang:Get(net.ReadString(v))
	end

	arista.logs.logNoPrefix(arista.logs.E.DEBUG, "Notification string:", form)
	form = arista.lang:Get(form, unpack(args))

	if inChat then chat.AddText(color_red, "! ", color_cream, form) else notification.AddLegacy(form, NOTIFY_GENERIC, 4) end
	surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")

	MsgN(form)
end)

net.Receive("arista_moneyAlert", function()
	local alert = {
		add = 1,
		alpha = 255,
	}

	local sign = net.ReadBool()
	local amount = net.ReadUInt(32)

	if not sign then
		alert.color = color_red
		alert.text = "-" .. amount
	else
		alert.color = color_green
		alert.text = "+" .. amount
	end

	table.insert(arista.client.moneyAlerts, alert)
end)

local startupmenu = CreateClientConVar("arista_menu_startup", "1", true)

local function playerInit(tab)
	arista.lp = LocalPlayer()

	if IsValid(arista.lp) then
		arista._playerInited = true
		arista.client._modelChoices = tab

		if startupmenu:GetBool() then
			arista.derma.menu.toggle()
		end
	else
		timer.Simple(0.5, function() playerInit(tab) end)
	end
end

-- Hook into when the player has initialized.
net.Receive("arista_modelChoices", function()
	local tab = {}
	local length = net.ReadUInt(8) or 0

	for i = 1, length do
		local gender = net.ReadString() or ""
		tab[gender] = {}

		local leng = net.ReadUInt(8) or 0

		for j = 1, leng do
			local team = net.ReadUInt(8) or 0
			local choice = net.ReadUInt(8) or 0

			tab[gender][team] = choice
		end
	end

	playerInit(tab)
end)

function GM:OnAchievementAchieved(ply, achid)
	arista.chatbox.chatText(ply:EntIndex(), ply:Name(), achievements.GetName(achid), "achievement")
end

-- Stop spam related to missing gm hook.
function GM:ChatboxMessageHandle() end

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

-- Called when an entity is created.
function GM:OnEntityCreated(entity)
	if LocalPlayer() == entity then
		arista.lp = entity
	end

	-- Call the base class function.
	return self.BaseClass:OnEntityCreated(entity)
end

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
local icoCache = {}
function GM:DrawBar(font, x, y, width, height, color, text, maximum, variable, bar, icon)
	surface.SetDrawColor(color_black_alpha)
	surface.DrawRect(x, y, width, height)

	surface.SetDrawColor(color_darkgray_alpha)
	surface.DrawRect(x + 2, y + 2, width - 4, height - 4)

	surface.SetDrawColor(color)
	surface.DrawRect(x + 2, y + 2, math.Clamp(((width - 4) / maximum) * variable, 0, width - 4), height - 4)

	-- Set the font of the text to this one.
	surface.SetFont(font)

	-- Adjust the x and y positions so that they don't screw up.
	local _x = math.floor(x + (width / 2))
	local _y = math.floor(y + 2)

	local w, h = surface.GetTextSize(text)
	w = w / 2

	-- Draw text on the bar.
	surface.SetTextPos(_x - w + 1, _y + 1)
	surface.SetTextColor(color_black)
	surface.DrawText(text)

	surface.SetTextPos(_x - w, _y)
	surface.SetTextColor(color_white)
	surface.DrawText(text)

	if icon then
		if not icoCache[icon] then
			local _icon = Material(icon .. ".png")
			icoCache[icon] = _icon
		end

		icon = icoCache[icon]
		surface.SetMaterial(icon)
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect(x + 4, y + 1, 16, 16)
	end

	-- Check if a bar table was specified.
	if bar then bar.y = bar.y - height end
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
		if not (v and IsValid(v) and v:EntIndex() > 0) then return end

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
	elseif hp < 50 and not ply:getAristaBool("hideHealthEffects") then
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

		-- Don't bother localising this, they haven't got to the language menu yet lmao.

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

	local color = color
	if alpha then color = Color(color.r, color.g, color.b, alpha) end

	-- Check if we shouldn't left align it, if we have a callback, and if we should draw a shadow.
	if not left then x = x - (width / 2) end
	if callback then x, y = callback(x, y, width, height) end

	if shadow then
		surface.SetTextColor(0, 0, 0, color.a)
		surface.SetTextPos(x + 1, y + 1)
		surface.DrawText(text)
	end

	-- Draw the text on the player.
	surface.SetTextColor(color)
	surface.SetTextPos(x, y)
	surface.DrawText(text)

	-- Return the new y position.
	return y + height + 8
end

local playerInfo = CreateClientConVar("arista_drawplayerinfo", "1", true, true)
local matCache = {}
-- Draw the player's information.
function GM:DrawPlayerInformation()
	local ply = arista.lp

	local width = 0
	local height = 0

	if not playerInfo:GetBool() then
		return width - 8, height
	end

	-- Create a table to store the text.
	local text = {}
	local information = {}

	-- Insert the player's information into the text table.
	text[#text+1] = {arista.lang:Get"AL_HUD_RPNAME" .. ply:rpName(), "icon16/user"}
	text[#text+1] = {arista.lang:Get"AL_HUD_GENDER" .. ply:getGender(), ply:getGender() == "Female" and "icon16/female" or "icon16/male"}
	text[#text+1] = {arista.lang:Get"AL_HUD_SALARY" .. ply:getSalary(), "icon16/folder_go"}
	text[#text+1] = {arista.lang:Get"AL_HUD_MONEY" .. ply:getMoney(), "icon16/star"}
	text[#text+1] = {arista.lang:Get"AL_HUD_DETAILS" .. ply:getDetails(), "icon16/status_offline"}
	text[#text+1] = {arista.lang:Get"AL_HUD_CLAN" .. ply:getClan(), "icon16/group"}
	text[#text+1] = {arista.lang:Get"AL_HUD_JOB" .. ply:getJob(), "icon16/wrench"}

	-- Loop through each of the text and adjust the width.
	for k, v in ipairs(text) do
		local split = v[1]:Split(":")

		if split[2]:Trim() ~= "" then
			if v[2] then
				width = self:AdjustMaximumWidth("arista_hud", v[1], width, nil, 24)
			else
				width = self:AdjustMaximumWidth("arista_hud", v[1], width)
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
	surface.SetDrawColor(color_black_alpha)
	surface.DrawRect(x, y, width, height)

	-- Increase the x and y position by 8.
	x = x + 8
	y = y + 8

	-- Draw the information on the box.
	for k, v in pairs(information) do
		local ico = v[2] .. ".png"

		if ico then
			self:DrawInformation(v[1], "arista_hud", x + 24, y, color_white, 255, true)

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
	self:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_red_alpha, arista.lang:Get"AL_HUD_HEALTH" .. health, 100, health, bar, "icon16/heart")
end

-- Draw the timer bar.
function GM:DrawTimerBar(bar)
	local jobTimeExpire = arista.lp:getAristaInt("jobTimeExpire") or 0
	local jobTimeLimit = arista.lp:getAristaInt("jobTimeLimit") or 0
	local expire = jobTimeExpire - CurTime()

	local percent = math.Clamp((expire / jobTimeLimit) * 100, 0, 100)
	local time = string.ToMinutesSeconds(math.floor(expire))

	self:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_orange_alpha, arista.lang:Get"AL_HUD_TIMELEFT" .. time, 100, percent, bar)
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
		self:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_lightblue_alpha, arista.lang:Get"AL_HUD_AMMO" .. clipOne .. " [" .. clipAmount .. "]", clipMaximum, clipOne, bar)
	end
end

-- Called when the bottom bars should be drawn.
function GM:DrawBottomBars(bar) end

-- Called when the top text should be drawn.
function GM:DrawTopText(text)
	-- Check if the player is warranted.
	if arista.lp:hasWarrant() ~= "" then
		local warrantExpireTime = arista.lp:getAristaInt("warrantExpireTime") or 0

		-- Text which is extended to the notice.
		local extension = 0
		local extensionType

		-- Check if the warrant expire time exists.
		if warrantExpireTime and warrantExpireTime > 0 then
			local seconds = math.floor(warrantExpireTime - CurTime())

			if seconds > 60 then
				extension = math.ceil(seconds / 60)
				extensionType = arista.lang:Get("AL_MINS")
			else
				extension = seconds
				extensionType = arista.lang:Get("AL_SECONDS")
			end
		end

		-- Check the class of the warrant.
		if arista.lp:hasWarrant() == "search" then
			text.y = self:DrawInformation(arista.lang:Get("AL_YOU_SEARCH_WARRANT", extension, extensionType), "ChatFont", text.x, text.y, color_brightgreen, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
		elseif arista.lp:hasWarrant() == "arrest" then
			text.y = self:DrawInformation(arista.lang:Get("AL_YOU_ARREST_WARRANT", extension, extensionType), "ChatFont", text.x, text.y, color_brightgreen, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
		end
	end

	-- Check if the player is arrested.
	if arista.lp:isArrested() then
		local unarrestTime = arista.lp:getAristaInt("unarrestTime") or 0

		-- Check if the unarrest time is greater than the current time.
		if unarrestTime > CurTime() then
			local seconds = math.floor(unarrestTime - CurTime())
			local mins = math.ceil(seconds / 60)

			-- Check if the amount of seconds is greater than 0.
			if seconds > 0 then
				if seconds > 60 then
					text.y = self:DrawInformation(arista.lang:Get("AL_YOU_UNARRESTED_IN", mins, arista.lang:Get("AL_MINS")), "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
						return x - width - 8, y
					end)
				else
					text.y = self:DrawInformation(arista.lang:Get("AL_YOU_UNARRESTED_IN", mins, arista.lang:Get("AL_SECONDS")), "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
						return x - width - 8, y
					end)
				end
			else
				text.y = self:DrawInformation(arista.lang:Get("AL_YOU_ARRESTED"), "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
					return x - width - 8, y
				end)
			end
		else
			text.y = self:DrawInformation(arista.lang:Get("AL_YOU_ARRESTED"), "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
				return x - width - 8, y
			end)
		end
	end

	if arista.lp:isTied() then
		text.y = self:DrawInformation(arista.lang:Get("AL_YOU_TIED"), "ChatFont", text.x, text.y, color_lightblue, 255, true, function(x, y, width, height)
			return x - width - 8, y
		end)
	end

	-- Check if the player is wearing kevlar.
	if arista.lp:getAristaFloat("scaleDamage") == 0.5 then
		text.y = self:DrawInformation(arista.lang:Get("AL_YOU_KEVLAR"), "ChatFont", text.x, text.y, color_pink, 255, true, function(x, y, width, height)
			return x - width - 8, y
		end)
	end
end

-- Called every time the HUD should be painted.

function GM:HUDPaint()
	if not IsValid(arista.lp) then arista.lp = LocalPlayer() return end

	if not arista._playerInited then return end
	self:HUDPaintESP()

	-- Bypass the camera, show what server this was taken on.
	self:DrawInformation(arista.config.vars.serverWebsite, "ChatFont", ScrW(), ScrH(), color_white, 255, true, function(x, y, width, height)
		return x - width - 8, y - height - 8
	end)

	if self:IsUsingCamera() then return end

	local donator = arista.lp:getAristaInt("donator")

	if donator and donator > 0 then
		local expire = math.max(donator - os.time(), 0)

		if expire > 1 then
			local days = math.floor(((expire / 60) / 60) / 24)

			if days <= 0 then
				local hours = math.floor(expire / 3600)

				if hours <= 4 then
					hours = string.format("%02.f", hours)
					local minutes = string.format("%02.f", math.floor(expire / 60 - (hours * 60)))
					local seconds = string.format("%02.f", math.floor(expire - hours * 3600 - minutes * 60))

					self:DrawInformation(arista.lang:Get("AL_YOU_DONATOR_EXPIRE_HOURS", hours, minutes, seconds), "ChatFont", ScrW(), ScrH(), color_highred, 255, true, function(x, y, width, height)
						return x - width - 8, y - height - 24
					end)
				end
			end
		end
	end

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
			table.remove(arista.client.moneyAlerts, k)
		end
	end

	-- Get the size of the information box.
	local width, height = self:DrawPlayerInformation()

	-- A table to store the bar and text information.
	local bar = {x = width + 16, y = ScrH() - 24, width = 144, height = 18}
	local text = {x = ScrW(), y = 8}

	-- Draw the player's health and ammo bars.
	if arista.lp:Health() < 100 then
		self:DrawHealthBar(bar)
	end

	self:DrawAmmoBar(bar)

	local jobTimeExpire = arista.lp:getAristaInt("jobTimeExpire") or 0
	if jobTimeExpire and jobTimeExpire > CurTime() then
		self:DrawTimerBar(bar)
	end

	-- Call a hook to let plugins know that we're now drawing bars and text.
	gamemode.Call("DrawBottomBars", bar)
	gamemode.Call("DrawTopText", text)

	-- Check if the next spawn time is greater than the current time.
	local x, y = self:GetScreenCenterBounce()
	y = y + 16

	local jump = input.LookupBinding("+jump"):upper()

	-- Get the player's next spawn time.
	local nextSpawnTime = arista.lp:getAristaInt("nextSpawnTime") or 0
	local goToSleepTime = arista.lp:getAristaInt("goToSleepTime") or 0
	local tying = arista.lp:getAristaInt("tying") or 0
	local beTied = arista.lp:getAristaBool("beTied") or false

	if not arista.lp:Alive() and nextSpawnTime > CurTime() then
		local seconds = math.floor(nextSpawnTime - CurTime())

		-- Check if the amount of seconds is greater than 0.
		if seconds > 0 then
			self:DrawInformation(arista.lang:Get("AL_YOU_WAIT_SPAWN", seconds), "ChatFont", x, y, color_white, 255)
		end
	elseif arista.lp:isUnconscious() and arista.lp:Alive() then
		local knockOutPeriod = arista.lp:getAristaInt("knockOutPeriod") or 0
		local text = ""

		-- Check if the unknock out time is greater than the current time.
		if knockOutPeriod > CurTime() then
			local seconds = math.floor(knockOutPeriod - CurTime())

			text = arista.lang:Get("AL_YOU_WAIT_GETUP", seconds)
		elseif arista.lp:isSleeping() then
			text = arista.lang:Get("AL_YOU_WAKEUP", jump)
		else
			text = arista.lang:Get("AL_YOU_GETUP", jump)
		end

		self:DrawInformation(text, "ChatFont", x, y, color_white, 255)
	elseif goToSleepTime > CurTime() then
		local seconds = math.floor(goToSleepTime - CurTime())

		if seconds > 0 then
			self:DrawInformation(arista.lang:Get("AL_YOU_WAIT_SLEEP", seconds), "ChatFont", x, y,  color_white, 255)
		end
	elseif tying > CurTime() then
		local seconds = math.floor(tying - CurTime())

		if seconds > 0 then
			self:DrawInformation(arista.lang:Get("AL_YOU_FINISH_KNOTS", seconds), "ChatFont", x, y,  color_white, 255)
		end
	elseif beTied then
		self:DrawInformation(arista.lang:Get("AL_YOU_FINISH_TIED"), "ChatFont", x, y, color_white, 255)
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

-- Stop players bypassing my post proccesses with theirs
function GM:PostProcessPermitted()
	return arista.lp:IsAdmin()
end

-- Called when a player begins typing.
function GM:StartChat(team)
	--return true
end

-- Called when a player says something or a message is received from the server.
function GM:ChatText(index, name, text, filter)
	if filter == "none" or (filter == "chat" and name == "Console") then
		arista.chatbox.chatText(index, name, text, filter)
	end

	-- Return true because we handle this our own way.
	return true
end

function GM:Initialize()
	arista.logs.log(arista.logs.E.LOG, os.date().." - Finished connecting")

	-- Call the base class function.
	return self.BaseClass:Initialize()
end

function GM:ForceDermaSkin()
	return self.BaseClass:ForceDermaSkin()
end
