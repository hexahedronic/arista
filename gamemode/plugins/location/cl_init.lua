local displayLocationHUD = false
local locationToDisplay = ""
local HUDMaterial = Material("materials/derma/general_store_menu_background.png")

net.Receive( "LocationHook", function( len )
    local location = net.ReadString()
    local displayHUD = net.ReadBool()
    hook.Run("LocationChange", LocalPlayer(), location, displayHUD)
end)


local function locationDisplay(location)
    local ply = LocalPlayer()
    surface.SetFont("Trebuchet24")
    surface.SetMaterial(HUDMaterial)
    local width = surface.GetTextSize(location)
    local height = 300
    local x = ScrW() - (width/2)
    local y = ScrH() * 0.3
    surface.DrawTexturedRect(x, y, width, height)
    surface.SetTextPos((ScrW() / 2) - (width / 2), y * 1.1)
    surface.DrawText(location)
end



hook.Add("LocationChange", "TriggerLocationHUD", function(ply, location, displayHUD)
    displayLocationHUD = true
    locationToDisplay = location
    timer.Simple(5, function()
        displayLocationHUD = false
    end)
end)

hook.Add("HUDPaint", "DisplayLocationHUD", function()
    if displayLocationHUD then
        locationDisplay(locationToDisplay)
    end
end)