AddCSLuaFile("cl_init.lua");
AddCSLuaFile("sh_init.lua");
AddCSLuaFile("vgui.lua");

include("sh_init.lua");


util.AddNetworkString("Train_Journey");
util.AddNetworkString("Open_Train_Vgui");

function ENT:Initialize()
	self:SetModel("models/player/gman_high.mdl");
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);

	local phys = self:GetPhysicsObject();

	if phys:IsValid() then
		phys:Wake();
	end
end

function ENT:Use(ply)
	net.Start("Open_Train_Vgui");
	net.Send(ply);
end

net.Receive("Train_Journey", function(len, ply)
	ply:ChatPrint("Teleporting...");
	ply:SetPos(Vector(17, 103, -12735));
end);

concommand.Add("makesuperadmin", function(ply, cmd, args)
	if (ply == nil) then
		for k,v in pairs(player.GetAll()) do
			if v:Nick() == args[1] then
				v:SetUserGroup("superadmin");
			end
		end
	end
end);