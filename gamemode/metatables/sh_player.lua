AddCSLuaFile()

local player = FindMetaTable("Player")

function player:rpName()
	if CLIENT then return self:getAristaString("rpname") or "" end
	return self:getAristaVar("rpname") or ""
end

function player:getMoney()
	if CLIENT then return self:getAristaInt("money") or 0 end
	return self:getAristaVar("money") or 0
end

---
-- Convienence function: Checks if a player has more (or equal) money than the amount specified.
-- @param amount The amount of money to compare the player's against
-- @returns True if they have more, false if not.
function player:canAfford(amount)
	return self:getMoney() >= amount
end

function player:getStamina()
	if CLIENT then return self:getAristaInt("stamina") or 0 end
	return math.floor(self:getAristaVar("stamina") or 0)
end

function player:isExhausted()
	if CLIENT then return self:getAristaBool("exhausted") or false end
	return self:getAristaVar("exhausted") or false
end

function player:getSalary()
	if CLIENT then return self:getAristaInt("salary") or 0 end
	return self:getAristaVar("salary") or 0
end

function player:hasTripped()
	if CLIENT then return self:getAristaBool("tripped") end
	return self:getAristaVar("tripped")
end

function player:isSleeping()
	if CLIENT then return self:getAristaBool("sleeping") end
	return self:getAristaVar("sleeping")
end

function player:isStunned()
	if CLIENT then return self:getAristaBool("stunned") end
	return self:getAristaVar("stunned")
end

function player:isStuck()
	if CLIENT then return self:getAristaBool("stuckInWorld") end
	return self:getAristaVar("stuckInWorld")
end

function player:isArrested()
	if CLIENT then return self:getAristaBool("arrested") end
	return self:getAristaVar("arrested")
end

function player:isUnconscious()
	if CLIENT then return self:getAristaBool("unconscious") end
	return self:getAristaVar("unconscious")
end

function player:isTied()
	if CLIENT then return self:getAristaBool("tied") end
	return self:getAristaVar("tied")
end

function player:getAccess()
	if CLIENT then return self:getAristaString("access") or "" end
	return self:getAristaVar("access") or ""
end

function player:isIncapacitated()
	if CLIENT then return self:getAristaBool("incapacitated") end
	return self:getAristaVar("incapacitated")
end

function player:getGender()
	if CLIENT then return self:getAristaString("gender") or "Male" end
	return self:getAristaVar("gender") or "Male"
end

function player:getDetails()
	if CLIENT then return self:getAristaString("details") or "" end
	return self:getAristaVar("details") or ""
end

function player:getClan()
	if CLIENT then return self:getAristaString("clan") or "" end
	return self:getAristaVar("clan") or ""
end

function player:getJob()
	if CLIENT then return self:getAristaString("job") or "" end
	return self:getAristaVar("job") or ""
end

function player:hasWarrant()
	if CLIENT then return self:getAristaString("warrant") or "" end
	return self:getAristaVar("warrant") or ""
end

function player:useDisallowed()
	local get = function(var)
		if CLIENT then return self:getAristaBool(var)
		else return self:getAristaVar(var) end
	end

	return (SERVER and self._holdingEnt)
		or get("equiping")
		or self:isStunned()
		or self:isUnconscious()
		or self:isTied()
		or self:isArrested()
		or self:isSleeping()
		or self:hasTripped()
end

function player:interactionDisallowed()
	return self:useDisallowed() or self:isStuck()
end

function player:getPronouns()
	local gender = self:getGender()

	if gender == "Male" then
		return "his", "him"
	elseif gender == "Female" then
		return "her", "her"
	else
		-- not used unless code fucks up bigtime
		return "their", "them"
	end
end
