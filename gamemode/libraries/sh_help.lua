AddCSLuaFile()

arista.help = {}
arista.help.stored = {}

function arista.help.add(cat, help, tip, command)
	arista.help.stored[cat] = arista.help.stored[cat] or {}

	table.insert(arista.help.stored[cat], {text = help, tip = tip, command = command})

	if CLIENT and arista.help.panel then
		arista.help.panel:Reload()
	end
end

if CLIENT then
	net.Receive("arista_helpReplace", function()
		local data = net.ReadTable()

		arista.help.stored = data

		if arista.help.panel then
			arista.help.panel:Reload()
		end
	end)
else
	-- todo: lang
	arista.help.add("General", "For more information, hover your mouse over entries")
	arista.help.add("General", "Using any exploits will get you banned permanently")
	arista.help.add("General", "Put // before your message to talk in global OOC")
	arista.help.add("General", "Put .// before your message to talk in local OOC")
	arista.help.add("General", "Press F1 to see the main menu")
	arista.help.add("General", "Press F2 to see the ownership menu")

	hook.Add("PlayerInitialized", "Arista Help", function(ply)
		net.Start("arista_helpReplace")
			net.WriteTable(arista.help.stored)
		net.Send(ply)
	end)
end
