-- A function to override whether a HUD element should draw.

local hide =
{
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudSuitPower"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true

}
function GM:HUDShouldDraw(name)
    if hide[name] then 
        return false
    end 
	-- Call the base class function.
	return self.BaseClass:HUDShouldDraw(name)
end

function GM:HUDDrawTargetID()
	return false
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

local WestHUD = {}
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
	local width, height = 0, 0 --self:DrawPlayerInformation()

	-- A table to store the bar and text information.
	local bar = {x = width + 16, y = ScrH() - 24, width = 144, height = 18}
	local text = {x = ScrW(), y = 8}

	-- Draw the player's health and ammo bars.
	if arista.lp:Health() < 100 then
		--self:DrawHealthBar(bar)
	end

	self:DrawAmmoBar(bar)

	local jobTimeExpire = arista.lp:getAristaInt("jobTimeExpire") or 0
	if jobTimeExpire and jobTimeExpire > CurTime() then
		self:DrawTimerBar(bar)
	end

	-- Call a hook to let plugins know that we're now drawing bars and text.
	--gamemode.Call("DrawBottomBars", bar)
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

	WestHUD:DrawHUD()

	gamemode.Call("PlayerHUDPaint", arista.lp)
	
	-- Call the base class function.
	self.BaseClass:HUDPaint()
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
	text[#text+1] = {arista.lang:Get"AL_HUD_SALARY" .. formatNum(ply:getSalary(), 2), "icon16/folder_go"}
	text[#text+1] = {arista.lang:Get"AL_HUD_MONEY" .. formatNum(ply:getMoney(), 2), "icon16/star"}
	text[#text+1] = {arista.lang:Get"AL_HUD_LOCATION" .. ply:getAristaString("Location") or "Wilderness", "icon16/map"}
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

WestHUD.highlightTexture = Material("hud/footer.png", "noclamp smooth")
WestHUD.barBackgroundTexture = Material("hud/backgroundlong.png", "noclamp smooth")
WestHUD.barHealthTexture = Material("hud/health bar.png", "noclamp smooth")
WestHUD.barHungerTexture = Material("hud/hunger bar.png", "noclamp smooth")
WestHUD.barStaminaTexture = Material("hud/stamina bar.png", "noclamp smooth")
WestHUD.barShortTexture = Material("hud/backgroundshort.png", "noclamp smooth")
WestHUD.logoBarTexture = Material("hud/server banner bar top.png", "noclamp smooth")
WestHUD.dbTexture = Material("hud/donator bonds icon.png", "noclamp smooth")

WestHUD.Colors = {}
WestHUD.Colors.White = Color(255, 255, 255)
WestHUD.Colors.Black = Color(0, 0, 0)


surface.CreateFont("WestHUD.Bars", {
	font = "Buffalo Inline 2 Grunge",
	size = 32,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	shadow = false,
	additive = true,
})

surface.CreateFont("WestHUD.Bars.Small", {
	font = "Buffalo Inline 2 Grunge",
	size = 22,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	shadow = false,
	additive = true,
})


function WestHUD:CalculateInfo()

	self.topBarWidth = ScrW()
	self.topBarHeight = self.topBarWidth*0.0552
	self.logo = "JAGGEDSPRINGS.COM"

    self.border = 20
    self.startX = self.border

    self.barHeight = ScreenScale(14)
	self.barWidth = self.barHeight*9.03

	self.barShortHeight = self.barHeight
	self.barShortWidth = self.barShortHeight*3.07

	self.barShortGap = (self.barWidth - self.barShortWidth*3)/2
	
	self.barFillHeight = self.barHeight*0.75
	self.barFillWidth = self.barWidth*0.95

    self.gap = 10

	self.startY = ScrH() - self.border*2 - self.barHeight*5 - self.gap*4 --This is the very top of our HUD.
	
	self.headerY = self.startY
	self.headerX = self.startX

	self.infoStartX = self.startX
	self.infoStartY = self.headerY + self.barHeight + self.gap

	self.healthX = self.headerX
	self.healthY = self.infoStartY + self.gap + self.barHeight

	self.hungerX = self.headerX
	self.hungerY = self.healthY + self.gap + self.barHeight

	self.staminaX = self.headerX
	self.staminaY = self.hungerY + self.gap + self.barHeight

	
	self.barFillGapX = (self.barWidth - self.barFillWidth)/2
	self.barFillGapY = (self.barHeight - self.barFillHeight)/2

	self.barFillX = self.startX + self.barFillGapX

	self.hp = 100
	self.hunger = 100
	self.stamina = 100

	if ScrW() < 1920 then 
		self.font = "WestHUD.Bars.Small"
	else 
		self.font = "WestHUD.Bars"
	end 

	print(self.font)
	
end 

WestHUD:CalculateInfo()

function WestHUD:DrawHUD()

	local ply = LocalPlayer()

	/////////////////////////////////Server Banner///////////////////////////////// 

		surface.SetDrawColor(self.Colors.White)
		surface.SetMaterial(self.logoBarTexture)
		surface.DrawTexturedRect(0, -self.topBarHeight*0.29, self.topBarWidth, self.topBarHeight)

		surface.SetFont("WestHUD.Bars")
		surface.SetTextColor(self.Colors.White)
		local tWidth, tHeight = surface.GetTextSize(self.logo)
		surface.SetTextPos(self.topBarWidth/2 - tWidth/2, self.topBarHeight/3 - tHeight/2)
		surface.DrawText(self.logo)

	/////////////////////////////////End Banner/////////////////////////////////

	
	/////////////////////////////////Drawing Header/////////////////////////////////

		surface.SetDrawColor(self.Colors.Black)
		surface.SetMaterial(self.highlightTexture)
		surface.DrawTexturedRect(self.headerX, self.headerY, self.barWidth, self.barHeight) 

	/////////////////////////////////End Header/////////////////////////////////


	/////////////////////////////////Money and Hours/////////////////////////////////
		surface.SetDrawColor(self.Colors.White)
		surface.SetMaterial(self.barShortTexture)

		local moneyX = self.infoStartX
		surface.DrawTexturedRect(moneyX, self.infoStartY, self.barShortWidth, self.barShortHeight) 

		local money = "$"..formatNum(ply:getMoney(), 2)

		surface.SetFont(self.font)
		local tWidth, tHeight = surface.GetTextSize(money)
		surface.SetTextPos(moneyX + self.barShortWidth/2 - tWidth/2, self.infoStartY + self.barShortHeight/2 - tHeight/2)
		surface.DrawText(money)

		local specialMoneyX = moneyX + self.barShortWidth + self.barShortGap
		surface.DrawTexturedRect(specialMoneyX, self.infoStartY, self.barShortWidth, self.barShortHeight)

		surface.SetMaterial(self.dbTexture)

		local dbSize = self.barShortHeight*0.6
		surface.DrawTexturedRect(specialMoneyX + self.barShortHeight/2, self.infoStartY + self.barShortHeight/2 - dbSize/2, dbSize, dbSize)

		local specialMoney = ply:getBonds()

		surface.SetFont(self.font)
		local tWidth, tHeight = surface.GetTextSize(specialMoney)
		surface.SetTextPos(specialMoneyX + self.barShortWidth/2 - tWidth/2, self.infoStartY + self.barShortHeight/2 - tHeight/2)
		surface.DrawText(specialMoney)

		surface.SetMaterial(self.barShortTexture)
		local hoursPlayedX = specialMoneyX + self.barShortWidth + self.barShortGap
		surface.DrawTexturedRect(hoursPlayedX, self.infoStartY, self.barShortWidth, self.barShortHeight)

		local hoursPlayed = "like 2 IDK"

		surface.SetFont(self.font)
		local tWidth, tHeight = surface.GetTextSize(hoursPlayed)
		surface.SetTextPos(hoursPlayedX + self.barShortWidth/2 - tWidth/2, self.infoStartY + self.barShortHeight/2 - tHeight/2)
		surface.DrawText(hoursPlayed)
	/////////////////////////////////End Money and Hours/////////////////////////////////


	/////////////////////////////////Drawing Health/////////////////////////////////

		surface.SetDrawColor(self.Colors.Black)
		surface.SetMaterial(self.barBackgroundTexture)
		surface.DrawTexturedRect(self.healthX, self.healthY, self.barWidth, self.barHeight)

		surface.SetDrawColor(self.Colors.White)
		surface.SetMaterial(self.barHealthTexture)

		self.hp = Lerp(FrameTime()*10, self.hp, ply:Health())
		local hp = string.format("%.0f%%", self.hp)
		local maxHP = ply:GetMaxHealth()
		local hpFrac = self.hp/maxHP

		render.SetScissorRect( self.barFillX, self.healthY + self.barFillGapY, self.barFillX + self.barFillWidth*hpFrac, self.healthY + self.barFillGapY + self.barFillHeight, true )
			surface.DrawTexturedRect(self.barFillX, self.healthY + self.barFillGapY, self.barFillWidth, self.barFillHeight)
		render.SetScissorRect( 0, 0, 0, 0, false )

		surface.SetFont(self.font)
		surface.SetTextColor(self.Colors.White)
		local tWidth, tHeight = surface.GetTextSize("HEALTH")
		surface.SetTextPos(self.barFillX + self.barFillGapX + self.gap, self.healthY + self.barHeight/2 - tHeight/2)
		surface.DrawText("HEALTH")

		local tWidth, tHeight = surface.GetTextSize(hp)
		surface.SetTextPos(self.barFillX + self.barWidth/2 - tWidth/2, self.healthY + self.barHeight/2 - tHeight/2)
		surface.DrawText(hp)

	/////////////////////////////////End Health/////////////////////////////////

	/////////////////////////////////Drawing Hunger/////////////////////////////////

		surface.SetDrawColor(self.Colors.Black)
		surface.SetMaterial(self.barBackgroundTexture)
		surface.DrawTexturedRect(self.hungerX, self.hungerY, self.barWidth, self.barHeight)

		surface.SetDrawColor(self.Colors.White)
		surface.SetMaterial(self.barHungerTexture)

		local hunger = arista.lp:getAristaInt("hunger") or 100
		local hungerFrac = hunger/100

		render.SetScissorRect( self.barFillX, self.hungerY + self.barFillGapY, self.barFillX + self.barFillWidth*hungerFrac, self.hungerY + self.barFillGapY + self.barFillHeight, true )
			surface.DrawTexturedRect(self.barFillX, self.hungerY + self.barFillGapY, self.barFillWidth, self.barFillHeight)
		render.SetScissorRect( 0, 0, 0, 0, false )

		surface.SetFont(self.font)
		surface.SetTextColor(self.Colors.White)
		local tWidth, tHeight = surface.GetTextSize("HUNGER")
		surface.SetTextPos(self.barFillX + self.barFillGapX + self.gap, self.hungerY + self.barHeight/2 - tHeight/2)
		surface.DrawText("HUNGER") 

		local hungerText = hunger.."%"
		local tWidth, tHeight = surface.GetTextSize(hungerText)
		surface.SetTextPos(self.barFillX + self.barWidth/2 - tWidth/2, self.hungerY + self.barHeight/2 - tHeight/2)
		surface.DrawText(hungerText)

	/////////////////////////////////End Hunger/////////////////////////////////


	/////////////////////////////////Drawing Stamina/////////////////////////////////

		surface.SetDrawColor(self.Colors.Black)
		surface.SetMaterial(self.barBackgroundTexture)
		surface.DrawTexturedRect(self.staminaX, self.staminaY, self.barWidth, self.barHeight)

		surface.SetDrawColor(self.Colors.White)
		surface.SetMaterial(self.barStaminaTexture)

		self.stamina = Lerp(FrameTime()*10, self.stamina, arista.lp:getAristaInt("stamina") or 100)
		local stamina = string.format("%.0f%%", self.stamina)
		local staminaFrac = self.stamina/100

		render.SetScissorRect( self.barFillX, self.staminaY + self.barFillGapY, self.barFillX + self.barFillWidth*staminaFrac, self.staminaY + self.barFillGapY + self.barFillHeight, true )
			surface.DrawTexturedRect(self.barFillX, self.staminaY + self.barFillGapY, self.barFillWidth, self.barFillHeight)
		render.SetScissorRect( 0, 0, 0, 0, false )

		surface.SetFont(self.font)
		surface.SetTextColor(self.Colors.White)
		local tWidth, tHeight = surface.GetTextSize("STAMINA")
		surface.SetTextPos(self.barFillX + self.barFillGapX + self.gap, self.staminaY + self.barHeight/2 - tHeight/2)
		surface.DrawText("STAMINA")

		local tWidth, tHeight = surface.GetTextSize(stamina)
		surface.SetTextPos(self.barFillX + self.barWidth/2 - tWidth/2, self.staminaY + self.barHeight/2 - tHeight/2)
		surface.DrawText(stamina)

	/////////////////////////////////End Stamina/////////////////////////////////


end 