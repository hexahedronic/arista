local displayLocationHUD = false
local locationToDisplay = ""
local HUDMaterial = Material("materials/derma/general_store_menu_background.png")

net.Receive( "LocationHook", function( len )
    local location = net.ReadString()
    local displayHUD = net.ReadBool()
    hook.Run("LocationChange", LocalPlayer(), location, displayHUD)
end)


surface.CreateFont( "CopperplateNow", {
	font = "Copperplate Bold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 22,
	weight = 300,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont( "Copperplate", {
	font = "Copperplate Bold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 35,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local function locationDisplay(location)
	surface.SetFont("CopperplateNow")
    local widthtop = surface.GetTextSize("Now Entering:")
    local xt = ScrW()/2 - widthtop/2
	surface.SetFont("Copperplate")
    local width = surface.GetTextSize(location)
    local height = 160
    local x = ScrW()/2 - width/2
    local y = ScrH() * 0.1
    surface.SetMaterial(HUDMaterial)
    surface.SetDrawColor( 255, 255, 255 )
    surface.DrawTexturedRect(x - 50, y, width + 100, height)
    surface.SetFont("CopperplateNow")
    surface.SetTextPos(xt , y * 1.2)
    surface.DrawText("Now Entering:")
    surface.SetFont("Copperplate")
    surface.SetTextPos(x , y * 1.4)
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