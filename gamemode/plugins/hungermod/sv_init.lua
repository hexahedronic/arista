function PLUGIN:PostPlayerSpawn(ply, lightSpawn, changeTeam)
	if not lightSpawn then
		ply:networkAristaVar("hunger", 100)
		-- Make the hunger save and load from previous session?
	end
end

function PLUGIN:PlayerTenthSecond(ply)
	local hunger = ply:getAristaVar("hunger")
	hunger = math.Clamp(hunger - 1, 0, 100)
	ply:setAristaVar("hunger", hunger)
end

function PLUGIN:StaminaAdjustPlayerSpeed(ply, run, walk)
	local hunger = ply:getAristaVar("hunger")
	
	if hunger <= 10 then
		run = walk
		return run, walk
	end
end

function PLUGIN:StaminaAdjustDrain(ply, amt)
	local hungry = ply:getAristaVar("hunger") <= 10
	if hungry then 
		amt = amt * 1.5 
		return amt 
	end
end