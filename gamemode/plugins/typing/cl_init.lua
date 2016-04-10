include("sh_init.lua")

-- Called when the ESP is running
function PLUGIN:AdjustESPLines(lines, tent, pos, distance, lookingat)
	local player = tent:isPlayerRagdoll() and tent:getRagdollPlayer() or tent

	if player:IsPlayer() and player:GetNW2Bool("arista_typing") then
		lines:shiftWeightDown(1, 1) -- Make everything under the player's name drop by one
		lines:add("Typing", "Typing", color_white, 2)
	end
end

-- Called when a player starts typing.
function PLUGIN:StartChat()
	net.Start("arista_typing")
		net.WriteBool(true)
	net.SendToServer()
end

-- Called when a player finishes typing.
function PLUGIN:FinishChat()
	net.Start("arista_typing")
		net.WriteBool(false)
	net.SendToServer()
end
