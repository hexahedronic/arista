arista.lang:Add("AL_HUD_OXYGEN", {
	EN = "Oxygen: ",
})

-- Called when the bottom bars should be drawn.
function PLUGIN:DrawBottomBars(bar)
	local oxygen = arista.lp:getAristaInt("oxygen") or 100

	if oxygen < 100 and oxygen ~= -1 then
		GAMEMODE:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_lightgray, arista.lang:Get"AL_HUD_OXYGEN" .. oxygen .. "%", 100, oxygen, bar, "icon16/cd")
	end
end
