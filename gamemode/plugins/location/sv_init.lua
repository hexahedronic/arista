util.AddNetworkString("LocationData")

local postable = {}

arista.command.add("pos1", "s", 0, function(ply)
	postable = {}
	ply:notify("Position 1 has been set.")
	table.insert(postable, 1, ply:GetPos())
end, "AL_COMMAND_CAT_SADMIN", true)

arista.command.add("pos2", "s", 0, function(ply)
	ply:notify("Position 2 has been set.")
	table.insert(postable, 2, ply:GetPos())
end, "AL_COMMAND_CAT_SADMIN", true)

arista.command.add("setlocation", "s", 1, function(ply, arguments)
	local text = table.concat(arguments, " ");
	table.insert(postable, 3, text)
	ply:notify("The location: "..text.." has been set.")

	locationdata = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"))
	OrderVectors(postable[1], postable[2])
	table.insert(locationdata, postable)
	file.Write("locations/" .. game.GetMap() .. ".txt", util.TableToJSON(locationdata, true))
	net.Start("LocationData")
		net.WriteTable(util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt")))
	net.Broadcast()
end, "AL_COMMAND_CAT_SADMIN")

local function deleteLocation()
	file.Write("locations/" .. game.GetMap() .. ".txt", util.TableToJSON(locationdata, true))
	net.Start("LocationData")
		net.WriteTable(util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt")))
	net.Broadcast()

	postable = {}
end

arista.command.add("dellocation", "s", 1, function(ply, arguments)
	local text = table.concat(arguments, " ");
	locationdata = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"))

	for k, v in pairs(locationdata) do
		if v[3] == text then
			table.remove(locationdata, k)
			deleteLocation()
			ply:notify("Location deleted!")
		end
	end
end, "AL_COMMAND_CAT_SADMIN")

local function LocationGet()
        local locationtable = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"));

        for _, p in ipairs(player.GetAll()) do
            for k, v in pairs(locationtable) do
                if (p:GetPos():WithinAABox(v[1], v[2])) and v[3] != p:getAristaVar("Location") then
                    p:setAristaVar("Location", v[3])
                    p._Location = v[3];
                    hook.Run( "LocationChange", p, v[3], v[4] or false ) // ply, location string, display now entering
                    //break
                //else
                //	p:SetNWString("Location", "GPS Signal Lost")
                //	p._Location = "GPS Signal Lost";
                end
            end
        end
end

timer.Create("LocationTimer", 1, 0, LocationGet)