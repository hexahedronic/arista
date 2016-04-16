arista.lang:Add("AL_HUD_HUNGER", {
	EN = "Hunger: ",
})

arista.lang:Add("AL_HUNGER_STARVE", {
	EN = "You are starving!",
})

-- Called when the bottom bars should be drawn.
function PLUGIN:DrawBottomBars(bar)
	local hunger = arista.lp:getAristaInt("hunger") or 100

	-- Check if the hunger is smaller than 100.
	if hunger < 100 then
		GAMEMODE:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_purpleblue, arista.lang:Get"AL_HUD_HUNGER" .. 100 - hunger .. "%", 100, hunger, bar, "icon16/cake")
	end
end

surface.CreateFont("arista_starve", {
	font = "akbar",
	weight = 400,
	size = 42,
})

function PLUGIN:HUDPaint()
	local hunger = arista.lp:getAristaInt("hunger") or 100
	if hunger > arista.config.plugins.hungerStarve or not arista.lp:Alive() then return end

	surface.SetFont("arista_starve")

	local txt = arista.lang:Get"AL_HUNGER_STARVE"
	local w, h = surface.GetTextSize(txt)

	local color = HSVToColor(0.5, math.abs(math.sin(RealTime())) % 1, 1)
	local x, y = ScrW() / 2 - w / 2, ScrH() / 2 - h / 2

	surface.SetTextPos(x + 2, y + 2)
	surface.SetTextColor(color_black)
	surface.DrawText(txt)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color)
	surface.DrawText(txt)
end
