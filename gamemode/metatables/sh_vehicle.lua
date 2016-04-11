AddCSLuaFile()

local vehicle = FindMetaTable("Vehicle")

function vehicle:isChair()
	local model = self:GetModel()

	return arista.utils.isModelChair(model)
end

function vehicle:validDriver()
	local driver = self:GetDriver()

	return IsValid(driver)
end

function vehicle:isTouchable(ply)
	return (CLIENT or not self:validDriver()) and (ply:IsAdmin() or self:isChair())
end
