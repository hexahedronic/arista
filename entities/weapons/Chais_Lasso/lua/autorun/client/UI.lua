AddCSLuaFile();
surface.CreateFont( "TangoTitle", {
	font = "Texas Tango BOLD PERSONAL USE", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 50,
	weight = 1000,
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

surface.CreateFont( "CopperNums", {
	font = "Copperplate Bold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 40,
	weight = 1000,
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


local lassoed = false;
local mat, _ = Material("bg.png", "noclamp smooth" );
local lassoTime = 0;
print(mat); 
hook.Add("HUDPaint", "DrawLassoHUD", function()
	if not lassoed then return end;
	surface.SetFont( "CopperNums" );
	surface.SetTextColor(Color(255, 255, 255));
	x, y = surface.GetTextSize("You are lassoed for ".. math.Round(20 - (CurTime() - lassoTime), 0) .. " seconds.");
	surface.SetDrawColor(0, 0, 0, 255);
	surface.SetMaterial(mat);	
	surface.DrawTexturedRect((ScrW() / 2) - 400, (ScrH() / 2) - 25, 800, 100);
	surface.SetTextPos((ScrW() / 2) - (x / 2), ScrH() / 2)
	surface.DrawText("You are lassoed for ".. math.Round(20 - (CurTime() - lassoTime), 0) .. " seconds.");
end) 

net.Receive("LassoHUD", function()
	lassoed = not lassoed;
	lassoTime = CurTime();
end)