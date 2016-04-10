function PLUGIN:PostPlayerSpawn(ply, lightSpawn, changeTeam)
	if not lightSpawn then
		ply:networkAristaVar("hunger", 100)
		-- todo: Make the hunger save and load from previous session?
	end
end

function PLUGIN:PlayerSecond(ply)
	local drain = arista.config.plugins.hungerDrain
	drain = hook.Run("HungerAdjustDrain") or drain

	local hunger = ply:getAristaVar("hunger") or 100
	hunger = math.Clamp(hunger - arista.config.plugins.hungerDrain, 0, 100)

	ply:setAristaVar("hunger", hunger)

	if hunger <= arista.config.plugins.hungerStarve and ply:Alive() then
		ply:TakeDamage(arista.config.plugins.hungerDamage, ply, game.GetWorld())
	end
end

function PLUGIN:StaminaAdjustPlayerSpeed(ply, run, walk)
	local hungry = (ply:getAristaVar("hunger") or 100) <= arista.config.plugins.hungerHungry

	if hungry then
		run = walk

		return run, walk
	end
end

function PLUGIN:StaminaAdjustDrain(ply, amt)
	local hungry = (ply:getAristaVar("hunger") or 100) <= arista.config.plugins.hungerHungry

	if hungry then
		amt = amt * 1.5

		return amt
	end
end
