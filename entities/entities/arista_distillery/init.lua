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

function ENT:Use(ply)
    if ply ~= self:CPPIGetOwner() or not IsValid(ply) or not ply:IsPlayer() then return end

    -- Pickup the entity to put in your inventory
    if ply:KeyDown(IN_WALK) then
        if self:GetNWBool("startedDistilling") then
            ply:notify("Your distillery is currently distilling! Wait until it has finished.")

            return
        else
            if arista.inventory.canFit(ply, 1) and self:GetNWBool("hasPotato") then
                self:SetNWBool("hasPotato", false)
                arista.inventory.update(ply, "potato", 1, false)
                ply:notify("Returned potatoes to your inventory.")
            elseif self:GetNWBool("hasPotato") then
                ply:notify("There is not enough room to return the potatoes to your inventory!")

                return
            end

            if arista.inventory.canFit(ply, 1) and self:GetNWBool("hasCoal") then
                self:SetNWBool("hasCoal", false)
                arista.inventory.update(ply, "coal", 1, false)
                ply:notify("Returned coal to your inventory.")
            elseif self:GetNWBool("hasCoal") then
                ply:notify("There is not enough room to return the coal to your inventory!")

                return
            end

            if arista.inventory.canFit(ply, 5) then
                arista.inventory.update(ply, "distillery", 1, false)
                self:Remove()
                ply:notify("Returned your distillery to your inventory.")
            else
                ply:notify("There is not enough room to return your distillery to your inventory!")

                return
            end

            return
        end
    elseif self:GetNWBool("hasPotato") and self:GetNWBool("hasCoal") then
        self:SetNWBool("startedDistilling", true)
        self.distillingTime = 20 * 60
        self:SetNWInt("finishedDistillingTime", self.distillingTime)
        local distillingSound = CreateSound(self, Sound("ambient/creatures/leech_water_churn_loop2.wav"))
        distillingSound:SetSoundLevel(50)
        distillingSound:Play()
        timer.Create("SteamEffectDistillery", 4, math.Round(self.distillingTime / 4, 0), function()
            if self then
                local vPoint = self:LocalToWorld(Vector( 1.827606, -16.102484, 69.929749 ))
                ParticleEffect( "generic_smoke", vPoint, Angle(0,0,0), self )
            end
        end)
        timer.Simple(self.distillingTime, function()
            distillingSound:Stop()
            self:SetNWBool("startedDistilling", false)
            self:SetNWBool("finishedDistilling", true)
        end)
    end
end