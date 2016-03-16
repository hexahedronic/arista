-- Called when a player spawns.
function PLUGIN:PostPlayerSpawn(player, light)
	if not light then
		player:networkAristaVar("oxygen", 100)
	end
end

-- Called when a player switches their flashlight on or off.
function PLUGIN:PlayerSwitchFlashlight(player, on)
	local oxygen = player:getAristaVar("oxygen")

	if on and oxygen < 10 and oxygen ~= -1 then
		return false
	end
end

-- Called every tenth of a second that a player is on the server.
function PLUGIN:PlayerTenthSecond(player)
	local oxygen = player:getAristaVar("oxygen")

	if oxygen ~= -1 and player:Alive() then
		if player:WaterLevel() > 2 then
			if oxygen > 0 then
				oxygen = oxygen - 0.4

				player:setAristaVar("oxygen", oxygen)
			end
		elseif oxygen < 100 then
			player:setAristaVar("oxygen", math.min(oxygen + 1.5, 100))
		end
	end
end

function PLUGIN:PlayerSecond(player)
	local oxygen = player:getAristaVar("oxygen")

	if player:Alive() and oxygen < 0 then
		player:ScreenFade(SCREENFADE.IN, color_black, 0.18, 0.05)
		player:TakeDamage(5, player, game.GetWorld())
	end
end
