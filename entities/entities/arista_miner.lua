-- Paste from BaseWars (https://github.com/hexahedronic/basewars)
local fontName = "Arista.MoneyPrinter"
ENT.Base 	= "arista_base_contra"

ENT.Model = "models/props_lab/reciever_cart.mdl"
ENT.Skin 	= 0

ENT.Capacity 				= 1000
ENT.Money 					= 0
ENT.PrintInterval 	= 1
ENT.PrintAmount			= 2
ENT.MaxLevel 				= 3
ENT.UpgradeCost 		= 5000

ENT.PrintName 			= "Bitcoin Miner"

ENT.IsPrinter 			= true

local format = string.Comma
local Clamp = math.Clamp
function ENT:GSAT(slot, name,  min, max)
	self:NetworkVar("Int", slot, name)

	local getVar = function(minMax)
		if self[minMax] and isfunction(self[minMax]) then return self[minMax](self) end
		if self[minMax] and isnumber(self[minMax]) then return self[minMax] end

		return minMax or 0
	end

	self["Add" .. name] = function(_, var)
			local Val = self["Get" .. name](self) + var

			if min and max then
				Val = Clamp(tonumber(Val) or 0, getVar(min), getVar(max))
			end

			self["Set" .. name](self, Val)
	end

	self["Take" .. name] = function(_, var)
		local Val = self["Get" .. name](self) - var

		if min and max then
			Val = Clamp(tonumber(Val) or 0, getVar(min), getVar(max))
		end

		self["Set" .. name](self, Val)
	end
end

function ENT:StableNetwork()
	self:GSAT(0, "Capacity")

	self:GSAT(1, "Money", 0, "GetCapacity")
	self:GSAT(2, "Level", 0, "MaxLevel")
end

if SERVER then
	AddCSLuaFile()

	function ENT:Init()
		self.time = CurTime()
		self.time_p = CurTime()

		self:SetCapacity(self.Capacity)

		self:SetHealth(self.PresetMaxHealth or 100)

		self.rtb = 0

		self.FontColor = color_white
		self.BackColor = color_black

		self:SetNWInt("UpgradeCost", self.UpgradeCost)
		self:SetLevel(1)
	end

	function ENT:SetUpgradeCost(val)
		self.UpgradeCost = val
		self:SetNWInt("UpgradeCost", val)
	end

	function ENT:Upgrade(ply)
		if ply then
			local lvl = self:GetLevel()
			local plyM = ply:getMoney()
			local calcM = self:GetNWInt("UpgradeCost") * lvl

			if plyM < calcM then
				ply:notify("You don't have enough money!")
			return end

			if lvl >= self.MaxLevel then
				ply:notify("This printer is at its maximum level.")
			return end

			ply:giveMoney(-calcM)
			self.CurrentValue = (self.CurrentValue or 0) + calcM
		end

		self:AddLevel(1)
		self:EmitSound("replay/rendercomplete.wav")
	end

	function ENT:ThinkFunc()
		if self.Disabled or self:BadlyDamaged() then return end
		local added

		local level = self:GetLevel() ^ 1.1

		if CurTime() >= self.PrintInterval + self.time then
			local m = self:GetMoney()
			self:AddMoney(math.Round(self.PrintAmount * level))
			self.time = CurTime()
			added = m ~= self:GetMoney()
		end

		if CurTime() >= self.PrintInterval * 2 + self.time_p and added then
			self.time_p = CurTime()
		end
	end

	function ENT:PlayerTakeMoney(ply)
		local money = self:GetMoney()

		local Res, Msg, b, c = hook.Run("PlayerCanEmptyPrinter", ply, self, money)
		if Res == false then

			if Msg then
				ply:notify(Msg, b, c)
			end
		return end

		self:TakeMoney(money)

		ply:giveMoney(money)
		ply:EmitSound("mvm/mvm_money_pickup.wav")

		hook.Run("PlayerEmptyPrinter", ply, self, money)
	end

	function ENT:UseFuncBypass(activator, caller, usetype, value)
		if self.Disabled then return end

		if activator:IsPlayer() and caller:IsPlayer() and self:GetMoney() > 0 then
			self:PlayerTakeMoney(activator)
		end
	end

	function ENT:SetDisabled(a)
		self.Disabled = a and true or false
		self:SetNWBool("printer_disabled", a and true or false)
	end

else

	function ENT:Initialize()
		if not self.FontColor then self.FontColor = color_white end
		if not self.BackColor then self.BackColor = color_black end
	end

	surface.CreateFont(fontName, {
		font = "Roboto",
		size = 20,
		weight = 800,
	})

	surface.CreateFont(fontName .. ".Huge", {
		font = "Roboto",
		size = 64,
		weight = 800,
	})


	surface.CreateFont(fontName .. ".Big", {
		font = "Roboto",
		size = 32,
		weight = 800,
	})

	surface.CreateFont(fontName .. ".MedBig", {
		font = "Roboto",
		size = 24,
		weight = 800,
	})

	surface.CreateFont(fontName .. ".Med", {
		font = "Roboto",
		size = 18,
		weight = 800,
	})


	if CLIENT then
		function ENT:DrawDisplay(pos, ang, scale)
			local w, h = 216 * 2, 136 * 2
			local disabled = self:GetNWBool("printer_disabled")
			local Lv = self:GetLevel()
			local Cp = self:GetCapacity()

			draw.RoundedBox(4, 0, 0, w, h, Pw and self.BackColor or color_black)

			if disabled then
				draw.DrawText("This printer has been", fontName, w / 2, h / 2 - 48, self.FontColor, TEXT_ALIGN_CENTER)
				draw.DrawText("DISABLED", fontName .. ".Huge", w / 2, h / 2 - 32, Color(255,0,0), TEXT_ALIGN_CENTER)
			return end

			draw.DrawText(self.PrintName, fontName, w / 2, 4, self.FontColor, TEXT_ALIGN_CENTER)

			if disabled then return end

			--Level
			surface.SetDrawColor(self.FontColor)

			surface.DrawLine(0, 30, w, 30)
			draw.DrawText("LEVEL: " .. Lv, fontName .. ".Big", 4, 32, self.FontColor, TEXT_ALIGN_LEFT)

			surface.DrawLine(0, 68, w, 68)
			draw.DrawText("CASH", fontName .. ".Big", 4, 72, self.FontColor, TEXT_ALIGN_LEFT)

			draw.DrawText("HP", fontName .. ".Big", 4, 220, self.FontColor, TEXT_ALIGN_LEFT)

			local money = tonumber(self:GetMoney()) or 0
			local cap = tonumber(Cp) or 0

			local moneyPercentage = math.Round( money / cap * 100, 1)
			--Percentage done
			draw.DrawText( moneyPercentage .."%" , fontName .. ".Big",	w - 4, 71, self.FontColor, TEXT_ALIGN_RIGHT)

			local healthPercentage = math.Round( self:Health() / self:GetMaxHealth() * 100, 1)
			--Percentage done
			draw.DrawText( healthPercentage .."%" , fontName .. ".Big",	w - 4, 219, self.FontColor, TEXT_ALIGN_RIGHT)

			--Money/Maxmoney
			local currentMoney = arista.lang.currency .. format(money)
			local maxMoney = arista.lang.currency .. format(cap)
			local font = fontName .. ".Big"
			if #currentMoney > 16 then
				font = fontName .. ".MedBig"
			end
			if #currentMoney > 20 then
				font = fontName .. ".Med"
			end
			local fh = draw.GetFontHeight(font)

			local StrW,StrH = surface.GetTextSize(" / ")
			draw.DrawText(" / " , font,
				w/2 - StrW/2 , (font == fontName .. ".Big" and 106 or 105 + fh / 4), self.FontColor, TEXT_ALIGN_LEFT)

			local moneyW,moneyH = surface.GetTextSize(currentMoney)
			draw.DrawText(currentMoney , font,
				w/2 - StrW/2 - moneyW , (font == fontName .. ".Big" and 106 or 105 + fh / 4), self.FontColor, TEXT_ALIGN_LEFT)

			draw.DrawText( maxMoney, font,
				w/2 + StrW/2 , (font == fontName .. ".Big" and 106 or 105 + fh / 4), self.FontColor, TEXT_ALIGN_Right)

			local NextCost = arista.lang.currency .. format(self:GetLevel() * self:GetNWInt("UpgradeCost"))

			if self:GetLevel() >= self.MaxLevel then

				NextCost = "!Max Level!"

			end

			surface.DrawLine(0, 142 + 25, w, 142 + 25)--draw.RoundedBox(0, 0, 142 + 25, w, 1, self.FontColor)
			draw.DrawText("NEXT UPGRADE: " .. NextCost, fontName .. ".MedBig", 4, 84 + 78 + 10, self.FontColor, TEXT_ALIGN_LEFT)
			surface.DrawLine(0, 176 + 25, w, 176 + 25)--draw.RoundedBox(0, 0, 142 + 55, w, 1, self.FontColor)

			--Time remaining counter
			local timeRemaining = 0
			timeRemaining = math.Round( (cap - money) / (self.PrintAmount * Lv / self.PrintInterval) )

			if timeRemaining > 0 then

				local PrettyHours = math.floor(timeRemaining/3600)
				local PrettyMinutes = math.floor(timeRemaining/60) - PrettyHours*60
				local PrettySeconds = timeRemaining - PrettyMinutes*60 - PrettyHours*3600
				local PrettyTime = (PrettyHours > 0 and PrettyHours.."h" or "") .. (PrettyMinutes > 0 and PrettyMinutes.."m" or "") .. PrettySeconds .."s"

				draw.DrawText(PrettyTime .. " until full", fontName .. ".Big", w-4 , 32, self.FontColor, TEXT_ALIGN_RIGHT)
			else
				draw.DrawText("Full", fontName .. ".Big", w-4 , 32, self.FontColor, TEXT_ALIGN_RIGHT)
			end

			--Money bar BG
			local BoxX = 88
			local BoxW = 265
			draw.RoundedBox(0, BoxX, 74, BoxW , 24, self.FontColor)

			--Money bar gap
			if cap > 0 and cap ~= math.huge then
				local moneyRatio = money / cap
				local maxWidth = math.floor(BoxW - 6)
				local curWidth = maxWidth * (1-moneyRatio)

				draw.RoundedBox(0, w - BoxX - curWidth + 6 , 76, curWidth , 24 - 4, self.BackColor)
			end

			local BoxX = 88
			local BoxW = 265
			draw.RoundedBox(0, BoxX, 224, BoxW, 24, color_red)

			local healthRatio = self:Health() / self:GetMaxHealth()
			local maxWidth = math.floor(BoxW - 6)
			local curWidth = maxWidth * (1-healthRatio)

			draw.RoundedBox(0, w - BoxX - curWidth + 6 , 226, curWidth , 24 - 4, self.BackColor)
		end

		function ENT:Calc3D2DParams()
			local pos = self:GetPos()
			local ang = self:GetAngles()

			pos = pos + ang:Up() * 17.25
			pos = pos + ang:Forward() * 13.25
			pos = pos + ang:Right() * 6.5

			ang:RotateAroundAxis(ang:Up(), 90)
			ang:RotateAroundAxis(ang:Forward(), 90)

			return pos, ang, 0.1 / 2
		end
	end

	function ENT:Draw()
		self:DrawModel()

		if CLIENT then
			local pos, ang, scale = self:Calc3D2DParams()

			cam.Start3D2D(pos, ang, scale)
				pcall(self.DrawDisplay, self, pos, ang, scale)
			cam.End3D2D()
		end
	end
end
