arista.chatbox = {}

-- Create some client convars that we'll need.
local ooc = CreateClientConVar("arista_chatbox_filter_ooc", "0", true, true)
local ic = CreateClientConVar("arista_chatbox_filter_ic", "0", true, true)
local joinleave = CreateClientConVar("arista_chatbox_filter_joinleave", "0", true, true)

-- Hook into when a player message is sent from the server.
net.Receive("arista_chatboxPlayerMessage", function()
	local player = net.ReadEntity()
	local filter = net.ReadString()
	local text = net.ReadString()

	-- Check to see if the player is a player.
	if player:IsPlayer() then
		arista.chatbox.chatText(player:EntIndex(), player:rpName(), text, filter)
	end
end)

-- Hook into when a message is sent from the server.
net.Receive("arista_chatboxMessage", function()
	local filter = net.ReadString()
	local text = net.ReadString()

	-- Chat Text.
	arista.chatbox.chatText(nil, nil, text, filter)
end)

-- Return a table of wrapped text (thanks to SamuraiMushroom for this function).
function arista.chatbox.wrapText(text, font, width, overhead, base)
	surface.SetFont(font)

	-- Save the original width for the next line and take the overhead from the width.
	local original = width
	width = width - (overhead or 0)

	-- Check to see if the width of the text is greater than the width we specified.
	if surface.GetTextSize(string.gsub(text, "&", "U")) > width then
		local length = 0
		local exploded = {}
		local seperator = ""

		-- Check if the text has any spaces in it.
		if string.find(text, " ") then
			exploded = string.Explode(" ", text)
			seperator = " "
		else
			exploded = string.ToTable(text)
			seperator = ""
		end

		-- Create a variable to store the current position of the text.
		local i = 1

		-- Keep looping while the length of the text is smaller than our specified width.
		while length < width do
			local block = table.concat(exploded, seperator, 1, i)

			-- Set the length to be the length of this block of text.
			length = surface.GetTextSize(string.gsub(block, "&", "U"))

			-- Increase the iterator so that we can move on to the next block of text.
			i = i + 1
		end

		-- Insert the first line into our out table.
		table.insert(base, table.concat(exploded, seperator, 1, i - 2))

		-- Get the second line of the text which we may need to wrap again.
		text = table.concat(exploded, seperator, i - 1)

		-- Check to see if the size of the second line is greater than our specified width.
		if surface.GetTextSize(string.gsub(text, "&", "U")) > original then
			arista.chatbox.wrapText(text, font, original, nil, base)
		else
			table.insert(base, text)
		end
	else
		table.insert(base, text)
	end
end

-- Explode a string by tags.
function arista.chatbox.explodeByTags(variable, seperator, open, close)
	local results = {}
	local current = ""
	local tag = false

	-- Loop through each individual character of the string.
	for i = 1, string.len(variable) do
		local character = variable[i]

		-- Check to see if we're currently handling a tag.
		if not tag then
			if character == open then
				current = current .. character
				tag = true
			elseif character == seperator then
				results[#results + 1] = current
				current = ""
			else
				current = current .. character
			end
		else
			current = current .. character

			-- Check to see if this character is the close tag.
			if character == close then tag = false end
		end
	end

	-- Check to see if the current current is not an empty string.
	if current ~= "" then results[#results + 1] = current end

	-- Return our new exploded results as a table.
	return results
end

-- Called when a player says something or a message is received from the server.
function arista.chatbox.chatText(index, name, text, filter)
	local class = filter
	local filtered = false

	-- Check if it is a valid filter.
	if filter == "arrested" or filter == "yell"
	 or filter == "whisper" or filter == "me"
	 or filter == "advert" or filter == "request"
	 or filter == "radio" or filter == "loudradio"
	 or filter == "tied" or filter == "action"
	 or filter == "gaction" then
		filter = "ic"
	elseif filter == "ooc" or filter == "looc" or filter == "pm" or filter == "notify" or filter == "achat" or filter == "mchat" then
		filter = "ooc"
	end

	-- Check if a convar exists for this filter.
	if ConVarExists("arista_chatbox_filter_" .. filter) and GetConVar("arista_chatbox_filter_" .. filter):GetBool() then
		filtered = true
	elseif filter == "ic" and not (arista.lp:Alive() or arista.lp:isSleeping()) then -- Kant stop the music.
		return
	end

	-- Get a player by the index.
	local player = player.GetByID(index)

	-- Fix Valve's errors.
	text = text:gsub(" ' ", "'")

	-- Check if the player is a valid entity.
	if IsValid(player) then
		local teamIndex = player:Team()
		local teamColor = team.GetColor(teamIndex)
		local icon = nil

		if filter == "ooc" then name = player:Name() end

		-- Check if the player is a super admin.
		if player:IsSuperAdmin() then
			icon = {"icon16/shield.png", "^"}
		elseif player:IsAdmin() then
			icon = {"icon16/star.png", "*"}
		elseif player:IsAdmin() then
			-- todo: mod
			icon = {"icon16/emoticon_smile.png", ":)"}
		elseif player:getAristaBool("donator") then
			icon = {"icon16/heart.png", "<3"}
		end

		-- Check if the class is valid.
		if class == "chat" then
			arista.chatbox.messageAdd(nil, {name, teamColor}, {text}, filtered)
		elseif class == "ic" then
			arista.chatbox.messageAdd(nil, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "me" then
			arista.chatbox.messageAdd(nil, nil, {"*** " .. name .. " " .. text, color_cream}, filtered)
		elseif class == "action" and name == nil then
			arista.chatbox.messageAdd(nil, nil, {"*** " .. text, color_cream}, filtered)
		elseif class == "action" then
			arista.chatbox.messageAdd({"(Action: " .. name .. ")", color_highred}, nil, {"*** " .. text, color_cream}, filtered)
		elseif class == "gaction" then
			arista.chatbox.messageAdd({"(Global)", color_highred}, nil, {"*** " .. text, color_cream}, filtered)
		elseif class == "advert" then
			arista.chatbox.messageAdd({"(Advert)"}, nil, {name .. ": " .. text, color_highpink}, filtered)
		elseif class == "yell" then
			arista.chatbox.messageAdd({"(Yell)"}, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "whisper" then
			arista.chatbox.messageAdd({"(Whisper)"}, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "looc" then
			arista.chatbox.messageAdd({"(Local OOC)", color_highred}, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "arrested" then
			arista.chatbox.messageAdd({"(Arrested)"}, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "tied" then
			arista.chatbox.messageAdd({"(Tied)"}, nil, {name .. ": " .. text, color_cream}, filtered)
		elseif class == "broadcast" then
			arista.chatbox.messageAdd({"(Broadcast)"}, nil, {name .. ": " .. text, color_highred}, filtered)
		elseif class == "request" then
			arista.chatbox.messageAdd({"(Request)"}, nil, {name .. ": " .. text, color_highblue}, filtered)
		elseif class == "radio" then
			arista.chatbox.messageAdd({"(Radio)"}, nil, {name .. ": " .. text, color_highgreen}, filtered)
		elseif class == "loudradio" then
			arista.chatbox.messageAdd(nil, nil, {"*** " .. name .. " radios in: " .. text, color_cream}, filtered)
		elseif class == "pm" then
			arista.chatbox.messageAdd({"(PM)", color_highred}, {name, color_cream}, {text, color_white}, filtered)
		elseif class == "achievement" then
			arista.chatbox.messageAdd({"(Achievement)", color_highred}, {name, teamColor}, {"just earned the achievement '" .. text .. "'!", color_redorange}, filtered)
		elseif class == "ooc" then
			arista.chatbox.messageAdd({"(OOC)", color_highred}, {name, teamColor}, {text, color_white}, filtered, icon)
		elseif class == "achat" then
			arista.chatbox.messageAdd({"(@Admins)", color_highred}, {name, teamColor}, {text, color_white}, filtered, icon)
		elseif class == "mchat" then
			arista.chatbox.messageAdd({"(@Mods)", color_highred}, {name, teamColor}, {text, color_white}, filtered, icon)
		end
	else
		if name == "Console" and class == "chat" then
			arista.chatbox.messageAdd({"(OOC)"}, {"Console", color_lightgray}, {text}, filtered)
		elseif class == "notify" then
			arista.chatbox.messageAdd(nil, nil, {text, color_pink}, filtered)
		else
			arista.chatbox.messageAdd(nil, nil, {text, color_cream}, filtered)
		end
	end
end

-- Add a new message to the message queue.
function arista.chatbox.messageAdd(title, name, text, filtered, icon)
	local res = gamemode.Call("ChatboxMessageHandle", title, name, text, filtered, icon)
	if res == true then return end

	local tc, tt, nc, nm, xc, tx
	if title then
		tc = title[2] or color_white
		tt = title[1] .. " "
	end

	if name then
		nc = name[2] or color_green
		nm = name[1]
	end

	if text then
		xc = text[2] or color_cream
		tx = ((nm and ": ") or "") .. text[1]
	end

	if not filtered then
		local ic = (icon and chathud and "<texture=" .. icon[1] .. ">") or ""
		chat.AddText(tc, tt, color_white, ic, nc, nm, xc, tx)
	else
		MsgN("FILTERED - ", icon and icon[2] .. " " or "", tt or "", nm  or "", tx  or "")
	end
end
