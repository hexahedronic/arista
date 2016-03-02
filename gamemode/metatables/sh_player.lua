AddCSLuaFile()

local player = FindMetaTable("Player")

function player:getMoney()
	if CLIENT then return self:getAristaInt("money") end
	return self:getAristaVar("money")
end

---
-- Convienence function: Checks if a player has more (or equal) money than the amount specified.
-- @param amount The amount of money to compare the player's against
-- @returns True if they have more, false if not.
function player:canAfford(amount)
	return self:getMoney() >= amount
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

function player:isIncapacitated()
	if CLIENT then return self:getAristaBool("incapacitated") end
	return self:getAristaVar("incapacitated")
end

function player:getGender()
	if CLIENT then return self:getAristaString("gender") end
	return self:getAristaVar("gender")
end

function player:getDetails()
	if CLIENT then return self:getAristaString("details") end
	return self:getAristaVar("details")
end

function player:isWarranted()
	if CLIENT then return self:getAristaString("warrant") end
	return self:getAristaVar("warrant")
end

function player:useDisallowed()
	local get = function(var)
		if CLIENT then return self:getAristaBool(var)
		else return self:getAristaVar(var) end
	end

	return get("holdingEnt")
		or get("equiping")
		or self:isStunned()
		or self:isUnconscious()
		or self:isTied()
		or self:isArrested()
		or self:isSleeping()
		or self:hasTripped()
end

function player:interactionDisallowed()
	return self:useDisallowed() or self:isStuck() or self:InVehicle()
end

function player:getPronouns()
	local gender = self:getGender()

	if gender == "Male" then
		return "his", "him"
	elseif gender == "Female" then
		return "her", "her"
	else
		return "their", "them"
	end
end
