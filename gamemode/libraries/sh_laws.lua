AddCSLuaFile()

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
		local updated = false

		-- Laws can only be a table of strings with #=10. Let's make damn sure of this
		for i = 1, 10 do
			laws[i] = laws[i] or ""

			if laws[i] ~= arista.laws.stored[i] then
				updated = true
				arista.laws.stored[i] = tostring(laws[i])
			end
		end

		if updated then
			net.Start("arista_laws")
				net.WriteTable(arista.laws.stored)
			net.Broadcast()
		end
	end

	--Updates the city laws
	local function getLaws(_, ply)
		local laws = net.ReadTable()
		if not (laws and istable(laws)) then return end

		local nextLawUpdate = ply:getAristaVar("nextLawUpdate") or 0

		if nextLawUpdate > CurTime() then
			ply:notify("AL_YOU_WAIT_LAWS", math.ceil((nextLawUpdate - CurTime()) / 60))

			return
		end

		if gamemode.Call("PlayerCanChangeLaws", ply) == false then
			ply:notify("AL_CANNNOT_LAWS_CHANGE")

			return
		end

		ply:setAristaVar("nextLawUpdate", CurTime() + 120)

		arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") updated the laws.")

		arista.laws.update(laws)
		arista.player.notifyAll("AL_PLAYER_UPDATELAWS", ply:GetName())
	end
	net.Receive("arista_laws", getLaws)
else
	arista.laws.update = true

	local function getLaws()
		arista.laws.stored = net.ReadTable()
		arista.laws.update = true
	end
	net.Receive("arista_laws",  getLaws)

	net.Receive("arista_lawsUpdate", function(msg)
		arista.laws.stored = {}

		local length = net.ReadInt(8)

		for i = 1, length do
			table.insert(arista.laws.stored, net.ReadString())
		end

		arista.laws.update = true
	end)
end
