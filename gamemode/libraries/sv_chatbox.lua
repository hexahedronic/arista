arista.chatbox = {}

-- Add a new line.
function arista.chatbox.add(receivers, player, filter, text)
	if player then
		net.Start("arista_chatboxPlayerMessage")
			net.WriteEntity(player)
			net.WriteString(filter)
			net.WriteString(text)
		net.Send(receivers)
	else
		net.Start("arista_chatboxMessage")
			net.WriteString(filter)
			net.WriteString(text)
		net.Send(receivers)
	end
end

-- Add a new line to players within the radius of a position.
function arista.chatbox.addInRadius(player, filter, text, position, radius, ignore)
	local radius = radius or arista.config.vars.talkRadius
	local doit, receivers = false, {}

	for k, v in ipairs(player.GetAll()) do
		if not ignore or not ignore[v] then
			-- Radius unknown, can't use DistToSqr
			if v:GetPos():Dist(position) <= radius then
				receivers[#receivers+1] = v

				doit = true
			end
		end
	end

	if doit then
		arista.chatbox.add(receivers, player, filter, text)
	end
end
