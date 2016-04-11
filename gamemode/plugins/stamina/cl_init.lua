arista.lang:Add("AL_HUD_STAMINA", {
	EN = "Stamina: ",
})

-- Called when the bottom bars should be drawn.
function PLUGIN:DrawBottomBars(bar)
	local stamina = arista.lp:getAristaInt("stamina") or 100

	-- Check if the stamina is smaller than 100.
	if stamina < 100 then
		GAMEMODE:DrawBar("Default", bar.x, bar.y, bar.width, bar.height, color_lightblue, arista.lang:Get"AL_HUD_STAMINA" .. stamina .. "%", 100, stamina, bar, "icon16/cup_go")
	end
end

-- Called when the local player presses a bind.
function PLUGIN:PlayerBindPress(player, bind, pressed)
	local stamina = arista.lp:getAristaInt("stamina") or 100

	-- Check if the stamina is smaller than 10.
	if not player:isUnconscious() and player:isExhausted() and bind:find("+jump", 1, true) then
		return true
	end
end
