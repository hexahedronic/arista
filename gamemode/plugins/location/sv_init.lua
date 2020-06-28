util.AddNetworkString("LocationData")
util.AddNetworkString("LocationHook")
arista.location = {}
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
    local text = table.concat(arguments, " ")
    table.insert(postable, 3, text)
    ply:notify("The location: " .. text .. " has been set.")
    locationdata = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"))
    OrderVectors(postable[1], postable[2])
    table.insert(locationdata, postable)
    file.Write("locations/" .. game.GetMap() .. ".txt", util.TableToJSON(locationdata, true))
    net.Start("LocationData")
    net.WriteTable(util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt")))
    net.Broadcast()
end, "AL_COMMAND_CAT_SADMIN")

function arista.location.deleteLocation()
    file.Write("locations/" .. game.GetMap() .. ".txt", util.TableToJSON(locationdata, true))
    net.Start("LocationData")
    net.WriteTable(util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt")))
    net.Broadcast()
    postable = {}
end

arista.command.add("dellocation", "s", 1, function(ply, arguments)
    local text = table.concat(arguments, " ")
    locationdata = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"))

    for k, v in pairs(locationdata) do
        if v[3] == text then
            table.remove(locationdata, k)
            arista.location.deleteLocation()
            ply:notify("Location deleted!")
        end
    end
end, "AL_COMMAND_CAT_SADMIN")

function arista.location.locationGet()
    local locationtable = util.JSONToTable(file.Read("locations/" .. game.GetMap() .. ".txt"))

    for _, p in ipairs(player.GetAll()) do
        p._OldLocation = p._Location or "Wilderness"
		print(p._OldLocation .. " test " .. p._Location)
        p._Location = nil

        for k, v in pairs(locationtable) do
            -- print(v[3] or "false" .. p:getAristaVar("Location") or "false2")
            if (p:GetPos():WithinAABox(v[1], v[2])) then
                if v[3] ~= p:getAristaVar("Location") then
                    p:setAristaVar("Location", v[3])
                    hook.Run("LocationChange", p, v[3], v[4] or false) -- ply, location string, display now entering
                    net.Start("LocationHook")
                    net.WriteString(v[3])
                    net.WriteBool(v[4] or false)
                    net.Send(p)
                end

                p._Location = v[3]
                break
            end
        end

        -- if not in a location, sets to wilderness
        if p._Location == nil and p._OldLocation ~= "Wilderness" then
            p:setAristaVar("Location", "Wilderness")
            p._Location = "Wilderness"
            hook.Run("LocationChange", p, "Wilderness", false) -- ply, location string, display now entering
            net.Start("LocationHook")
            net.WriteString("Wilderness")
            net.WriteBool(false)
            net.Send(p)
        end
    end
end

timer.Create("LocationTimer", 1, 0, arista.location.locationGet)