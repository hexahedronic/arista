arista.lang:Add("AL_HUD_FLASHLIGHT", {
	EN = "Flashlight: ",
})

-- Called when the bottom bars should be drawn.
function PLUGIN:DrawBottomBars(bar)
	local flashlight = arista.lp:getAristaInt("flashlight") or 100

	if flashlight < 100 and flashlight ~= -1 then
		GAMEMODE:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_pink, arista.lang:Get"AL_HUD_FLASHLIGHT" .. flashlight .. "%", 100, flashlight, bar, "icon16/lightbulb")
	end
end
