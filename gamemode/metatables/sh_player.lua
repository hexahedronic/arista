AddCSLuaFile()

local player = FindMetaTable("Player")

function player:hasTripped()
	if CLIENT then return self:getAristaString("tripped") end
	return self:getAristaVar("tripped")
end

function player:isStunned()
	if CLIENT then return self:getAristaString("stunned") end
	return self:getAristaVar("stunned")
end

function player:isStuck()
	if CLIENT then return self:getAristaString("stuckInWorld") end
	return self:getAristaVar("stuckInWorld")
end

function player:isArrested()
	if CLIENT then return self:getAristaString("arrested") end
	return self:getAristaVar("arrested")
end

function player:isUnconscious()
	if CLIENT then return self:getAristaString("unconscious") end
	return self:getAristaVar("unconscious")
end

function player:isTied()
	if CLIENT then return self:getAristaString("tied") end
	return self:getAristaVar("tied")
end

function player:getGender()
	if CLIENT then return self:getAristaString("gender") end
	return self:getAristaVar("gender")
end

function player:isWarranted()
	if CLIENT then return self:getAristaString("warrant") end
	return self:getAristaVar("warrant")
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
