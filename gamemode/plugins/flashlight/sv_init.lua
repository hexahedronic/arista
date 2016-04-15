-- Called when a player spawns.
function PLUGIN:PostPlayerSpawn(player, light)
	if not light then
		player:networkAristaVar("flashlight", 100)
	end
end

-- Called when a player switches their flashlight on or off.
function PLUGIN:PlayerSwitchFlashlight(player, on)
	local flash = player:getAristaVar("flashlight")

	if on and flash < 10 and flash ~= -1 then
		return false
	end
end

-- Called every tenth of a second that a player is on the server.
function PLUGIN:PlayerTenthSecond(player)
	local flash = player:getAristaVar("flashlight") or 100

	if not (player:isArrested() or player:isTied()) and flash ~= -1 then
		if player:FlashlightIsOn() then
			flash = flash - 0.3

			if flash < 0 then
				player:Flashlight(false)
			end

			player:setAristaVar("flashlight", flash)
		elseif flash < 100 then
			player:setAristaVar("flashlight", math.min(flash + 0.15, 100))
		end
	end
end
