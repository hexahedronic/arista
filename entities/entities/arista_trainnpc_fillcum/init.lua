AddCSLuaFile("cl_init.lua");
AddCSLuaFile("sh_init.lua");
AddCSLuaFile("vgui.lua");

include("sh_init.lua");


util.AddNetworkString("Train_Journey");
util.AddNetworkString("Open_Train_Vgui");

function ENT:Initialize()
	self:SetModel("models/hosti/cowboy_01.mdl");
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);

	local phys = self:GetPhysicsObject();

	if phys and phys:IsValid() then
		phys:Wake();
		phys:EnableMotion(true)
	end
end

function ENT:Use(ply)
	net.Start("Open_Train_Vgui");
	net.Send(ply);
end

net.Receive("Train_Journey", function(len, ply)
	if(ply:getMoney() >= 0.25) then
		ply:giveMoney(-0.25);
		ply:ChatPrint("You ride the train to Greenwood Ridge...");
		ply:SetPos(Vector(-12125.03, -5315.12, 112.03));
	else
		ply:ChatPrint("You have insufficient funds!")
	end
end);

function ENT.PhysgunPickup(ply)
	return true;
end