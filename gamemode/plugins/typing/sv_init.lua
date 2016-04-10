include("sh_init.lua")

util.AddNetworkString("arista_typing")

-- A console command to tell all players that a player has finished typing.
net.Receive("arista_typing", function(len, player)
	local bool = net.ReadBool() or false

	player:SetNW2Bool("arista_typing", bool)
end)
