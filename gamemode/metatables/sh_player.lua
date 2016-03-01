AddCSLuaFile()

local player = FindMetaTable("Player")

function player:getGender()
	if CLIENT then return self:getAristaString("gender") end
	return self:getAristaVar("gender")
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

function player:isWarranted()
	return self:getAristaVar("warranted")
end
