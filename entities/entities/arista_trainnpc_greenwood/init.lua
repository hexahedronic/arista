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
	print(ply:getMoney());
	if(ply:getMoney() >= 0.25) then
		ply:giveMoney(-0.25);
		ply:ChatPrint("You ride the train to Fillcum Ridge...");
		ply:SetPos(Vector(7273.56, -7210.74, 208.03));
	else
		ply:ChatPrint("You have insufficient funds!")
	end
end);

function ENT.PhysgunPickup(ply)
	return true;
end