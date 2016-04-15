-- Called when a player spawns.
function PLUGIN:PostPlayerSpawn(player, lightSpawn, changeTeam)
	if not lightSpawn then
		player:networkAristaVar("stamina", 100)
	end
end

-- Called when a player presses a key.
function PLUGIN:KeyPress(player, key)
	if not (player:isArrested() or player:isTied() or player._holdingEnt or player:isExhausted() or player:InVehicle()) then
		if player:Alive() and not player:isUnconscious() then
			if player:IsOnGround() and key == IN_JUMP then
				local stamina = player:getAristaVar("stamina")

				local drain = arista.config.plugins.staminaJump
				drain = hook.Run("StaminaAdjustDrain", player, drain) or drain

				stamina = math.Clamp(stamina - drain, 0, 100)

				player:setAristaVar("stamina", stamina)
			end
		end
	end
end

-- Called every tenth of a second that a player is on the server.
function PLUGIN:PlayerTenthSecond(player)
	local stamina = player:getAristaVar("stamina") or 100

	if not (player:isArrested() or player:isTied() or player._holdingEnt or player:GetMoveType() == MOVETYPE_NOCLIP) then
		if player:KeyDown(IN_SPEED) and player:Alive() and not player:isUnconscious() and not player:getAristaVar("exhaustedCooldown") and not player:isExhausted() and player:GetVelocity():Length() > 1 and player:IsOnGround() then
			local drain = arista.config.plugins.staminaDrain
			drain = hook.Run("StaminaAdjustDrain", player, drain) or drain

			if player:Health() < 50 then
				stamina = math.Clamp(stamina - (drain + ((50 - player:Health()) * 0.05)), 0, 100)
			else
				stamina = math.Clamp(stamina - drain, 0, 100)
			end
		elseif not player:getAristaVar("exhaustedCooldown") then
			local restore = arista.config.plugins.staminaRestore
			restore = hook.Run("StaminaAdjustRestore", player, restore) or restore

			if player:Health() < 50 then
				stamina = math.Clamp(stamina + (restore - ((50 - player:Health()) * 0.0025)), 0, 100)
			else
				stamina = math.Clamp(stamina + restore, 0, 100)
			end
		end

		player:setAristaVar("stamina", stamina)

		if player:getAristaVar("exhaustedTime") and player:getAristaVar("exhaustedTime") + 3 < CurTime() then
			player:setAristaVar("exhaustedCooldown", false)
		end

		-- Check the player's stamina to see if it's at it's maximum.
		if stamina <= 1 and not player:isExhausted() then
			player:incapacitate()
			player:setAristaVar("exhausted", true)

			player:setAristaVar("exhaustedCooldown", true)
			player:setAristaVar("exhaustedTime", CurTime())
		elseif stamina <= 50 and player:isExhausted() then
			-- If you get exhausted, it takes a while to wear off. ;)
		elseif stamina < 100 then
			local r = stamina / 100
			player:setAristaVar("exhausted", false)
			player:recapacitate()

			local run = (arista.config.vars.runSpeed - arista.config.vars.walkSpeed) * r + arista.config.vars.walkSpeed
			local walk = (arista.config.vars.walkSpeed - arista.config.vars.incapacitatedWalkSpeed) * r + arista.config.vars.incapacitatedWalkSpeed

			local retRun, retWalk = hook.Run("StaminaAdjustPlayerSpeed", player, run, walk)

			player:SetRunSpeed(retRun or run)
			player:SetWalkSpeed(retWalk or walk)
		end
	end
end

function PLUGIN:PlayerCanBeRecapacitated(ply)
	if ply:isExhausted() then
		return false
	end
end
