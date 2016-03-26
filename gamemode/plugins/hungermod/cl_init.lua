arista.lang:Add("AL_HUD_HUNGER", {
	EN = "Hunger: ",
})

-- Called when the bottom bars should be drawn.
function PLUGIN:DrawBottomBars(bar)
	local hunger = arista.lp:getAristaInt("hunger") or 100

	-- Check if the hunger is smaller than 100.
	if hunger < 100 then
		GAMEMODE:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_darkgreen, arista.lang:Get"AL_HUD_HUNGER" .. hunger .. "%", 100, hunger, bar)
	end
end
