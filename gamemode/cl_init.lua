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
	
	if pl:InVehicle() and pl:GetVehicle():getAristaInt("fpView") then
		origin = origin + Vector(0, 0, pl:GetVehicle():getAristaInt("fpView"))
	end
	
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
		if not (v and IsValid(v) and v:EntIndex() > 0) then continue end

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
