AddCSLuaFile("cl_init.lua")
AddCSLuaFile("sh_init.lua")
include("sh_init.lua")

function ENT:Initialize()
    self:SetModel("models/oldprops/distillery.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()

    if phys and phys:IsValid() then
        phys:Wake()
        phys:EnableMotion(true)
    end

    -- Initialise the various variables for the distillery
    timer.Simple(1, function() 
        self:SetNWBool("hasCoal", false)
        self:SetNWBool("hasPotato", false)
        self:SetNWBool("startedDistilling", false)
    end)
end