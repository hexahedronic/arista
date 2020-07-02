surface.CreateFont( "TangoBtn", {
	font = "Texas Tango BOLD PERSONAL USE", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 30,
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

function TeleportPlayer()
	net.Start("Train_Journey");
	net.SendToServer();
end

opened = false;

net.Receive("Open_Train_Vgui", function(len)
	if(opened == false) then
		opened = true;
		BGPanel = vgui.Create("DPanel");
		BGPanel:SetSize(600, 410);
		BGPanel:Center();
		BGPanel:SetDrawBackground(false);
		BGPanel:MakePopup();
		BGPanel:DockPadding(50, 25, 50, 35);

		local BGImage = vgui.Create("DImage", BGPanel);
		BGImage:SetSize(BGPanel:GetSize());
		BGImage:SetImage("\\GUI Parts\\Backgrounds\\Background.png");

		local embelishment = vgui.Create("DImage", BGPanel);
		embelishment:SetSize(0, 35);
		embelishment:SetImage("/GUI Parts/Headers_and_Footers/MenuFooter.png");
		embelishment:Dock(BOTTOM);

		local btnPanel = vgui.Create("DPanel", BGPanel);
		btnPanel.Paint = nil;
		btnPanel:SetSize(0, 50);
		btnPanel:Dock(BOTTOM);

		local closeBtn = vgui.Create("DImageButton", btnPanel);
		closeBtn:SetFont("TangoBtn");
		closeBtn:SetText("NO");
		closeBtn:SetSize(230, 0);
		closeBtn:Dock(RIGHT);
		closeBtn:SetImage( "/GUI Parts/Buttons/SmallButtonStatic.png" )
		closeBtn:SetTextColor(Color(255, 255, 255));

		closeBtn.DoClick = function()
			BGPanel:Hide();
			opened = false;
		end;

		closeBtn.Paint = function(s, w, h)
			if (s:IsHovered()) then
				closeBtn:SetImage( "/GUI Parts/Buttons/SmallButtonActivated.png" );
			else
				closeBtn:SetImage( "/GUI Parts/Buttons/SmallButtonStatic.png" );
			end
		end;

		local okayBtn = vgui.Create("DImageButton", btnPanel);
		okayBtn:SetFont("TangoBtn");
		okayBtn:SetText("YES");
		okayBtn:SetSize(230, 0);
		okayBtn:Dock(LEFT);
		okayBtn:SetImage( "/GUI Parts/Buttons/SmallButtonStatic.png" )
		okayBtn:SetTextColor(Color(255, 255, 255));

		okayBtn.DoClick = function()
			BGPanel:Hide();
			TeleportPlayer();
			opened = false;
		end;

		okayBtn.Paint = function(s, w, h)
			if (s:IsHovered()) then
				okayBtn:SetImage( "/GUI Parts/Buttons/SmallButtonActivated.png" );
			else
				okayBtn:SetImage( "/GUI Parts/Buttons/SmallButtonStatic.png" );
			end
		end;

		local title = vgui.Create("DLabel", BGPanel);
		title:SetFont("TangoTitle");
		title:SetText("Train Journey");
		title:Dock(TOP);
		title:SizeToContents();
		title:SetContentAlignment(5);
		title:DockMargin(0, 0, 0, 70);

		local body = vgui.Create("DLabel", BGPanel);
		body:SetFont("TangoBtn");
		body:Dock(TOP);
		body:SetText("Take Train to Fillcum Ridge?");
		body:SizeToContents();
		body:SetContentAlignment(5);

		local cost = vgui.Create("DLabel", BGPanel);
		cost:SetFont("CopperNums");
		cost:Dock(TOP);
		cost:SetText("Costs $0.25");
		cost:SizeToContents();
		cost:SetContentAlignment(5);
	end
end)





