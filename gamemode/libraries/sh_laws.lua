arista.laws = {}
arista.laws.stored = {
	"No Running",
	"No Throwing",
	"No Pushing",
	"No Shouting",
	"No Jumping",
	"No Splashing",
	"No Bombing",
	"No Ducking",
	"No Petting",
	"No Armbands Beyond This Point" -- I love how surreal this is, but no one ever comments on it. *SIGH*
}

if SERVER then
	function arista.laws.update(laws)
		--[[local updated = false
		--Laws can only be a table of strings with #=10. Let's make damn sure of this
		for i = 1,10 do
			laws[i] = laws[i] or ""
			if laws[i] ~= cider.laws.stored[i] then
				updated = true
				cider.laws.stored[i] = tostring(laws[i])
			end
		end
		if updated then
			datastream.StreamToClients(player.GetAll(), "cider_Laws",cider.laws.stored)
		end
	end
	--Updates the city laws
	local function getLaws( ply, handler, id, encoded, decoded )
		ply._NextLawUpdate = ply._NextLawUpdate or CurTime()
		if ply._NextLawUpdate > CurTime() then
			ply:Notify("You must wait another "..string.ToMinutesSeconds(ply._NextLawUpdate - CurTime()).." minute(s) to update the laws!",1)
			return
		end
		ply._NextLawUpdate = CurTime() + 120
		if !hook.Call("PlayerCanChangeLaws",GAMEMODE, ply) then
			ply:Notify("You may not change the laws.",1)
			return
		end
		cider.laws.update(decoded)
		player.NotifyAll(ply:GetName().." just updated the city laws",0)]]
	end
else
	arista.laws.update = true

	local function getLaws()
		arista.laws.stored = net.ReadTable()
		arista.laws.update = true
	end
	net.Receive("arista_laws",  getLaws)

	net.Receive("arista_lawsUpdate", function(msg)
		arista.laws.stored = {}

		local length = msg:ReadInt(8)

		for i = 1, length do
			table.insert(arista.laws.stored, net.ReadString())
		end

		arista.laws.update = true
	end)
end
