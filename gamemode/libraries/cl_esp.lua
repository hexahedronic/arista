-- Called when shit should be drawn.
arista.esp = {lines = {}}
arista.esp.__index = arista.esp

function arista.esp:new()
	local ret = {lines = {}}
	setmetatable(ret, self)

	return ret
end

function arista.esp:add(lineID, lineText, lineColour, lineWeight)
	if not (lineID and lineText and lineColour and lineWeight) then
		arista.logs.log(arista.logs.E.WARNING, "ESP: Incorrectly formatted esp line!")

		return
	elseif lineWeight < 1 then
		arista.logs.log(arista.logs.E.WARNING, "ESP: Line weight cannot be below 1!")

		return
	end

	self.lines[lineID] = {text = lineText, color = lineColour, weight = lineWeight}
end

function arista.esp:remove(lineID)
	self.lines[lineID] = nil
end

function arista.esp:get(lineID)
	return self.lines[lineID]
end

function arista.esp:adjustWeight(lineID, lineWeight)
	self.lines[lineID].weight = lineWeight
end

function arista.esp:shiftWeightDown(amount, threshhold)
	if amount <= 0 then
		arista.logs.log(arista.logs.E.WARNING, "ESP: shifting down with <= 0!")

		return
	end

	for id, line in pairs(self.lines) do
		if line.weight > threshhold then
			line.weight = line.weight + amount
		end
	end
end

function arista.esp:getAll()
	local weightadd = 0
	local weighted = {}

	for id, line in pairs(self.lines) do
		if weighted[line.weight] then
			weightadd = weightadd + 1
		end

		weighted[line.weight+weightadd] = {text = line.text, color = line.color}
	end

	return weighted
end

local fadeDistance = arista.config.vars.talkRadius^2
local fadeDiv = 255 / fadeDistance

function GM:DrawESPLine(ent, tent, ply)
	local class = tent:GetClass() -- Get the entity's class (like prop_physics)
	local pos = tent:GetPos() -- Get the entities position in the world

	pos = self:AdjustPosForStupidEnts(tent, pos)

	local screenpos = pos:ToScreen() -- Translate the world position into a screen X, Y screen position
	local dist = pos:DistToSqr(ply:GetPos()) -- Caclulate the (square) distance we are away from the entity for quicker usage later

	if not (screenpos.visible and (dist <= fadeDistance or self:IsUsingCamera())) then return end

	local tr, lookingat = {}

	if ent == tent then
		screenpos.x, screenpos.y = self:GetScreenCenterBounce() -- Get the bouncing up and down text

		lookingat = true
	elseif tent == ply and EyePos() == ply:EyePos() then
		tr.Hit = true
		tr.HitWorld = true
	else
		tr = {
			start  = EyePos(),
			endpos = pos, -- End at the position of the entity we want
			filter = ply, -- Make sure it doesn't hit us on the way there
			mask   = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER
		}
		tr.filter = table.Add({tr.filter}, arista.client.vehiclelist) -- make sure players are visable in cars
		tr = util.TraceLine(tr) -- Run the trace and get some results
	end

	-- Calculate the alpha from the distance. (Used a lot later)
	local alpha = math.Clamp(255 - (fadeDiv * (dist)), 0, 255)

	-- Get the x and y position.
	local x, y = screenpos.x, screenpos.y -- Also used a lot later.

	if lookingat or not (tr.Hit and (tr.HitWorld or tr.Entity ~= tent)) then
		local lines = arista.esp:new()

		local rag = tent:getAristaEntity("ragdoll")
		local tar = tent:getAristaEntity("player")

		-- Check if the entity is a player.
		if (tent:IsPlayer() and tent:Alive() and not IsValid(rag)) or (IsValid(tar) and tar ~= ply) then
			local player = tent

			if IsValid(tar) then
				player = tar
			end

			-- Draw for player.
			self:DrawPlayerESP(player, lines, pos, distance, lookingat)
		elseif tent.espPaint then
			tent:espPaint(lines, pos, distance, lookingat)
		elseif arista.entity.isContainer(tent) and lookingat then
			lines:add("Name", arista.lang:Get"AL_A" .. tent:getTitle(), color_purpleblue, 1)

			local status = arista.entity.getStatus(tent)

			if status ~= "" then
				lines:add("Status", status, color_yellow, 2)
			end
		elseif arista.entity.isDoor(tent) and lookingat then
			local owner = arista.entity.getOwner(tent)

			if owner then
				local name = tent:getTitle()

				if not name or name == "" then
					name = "Door"
				end

				if not arista.entity.isOwned(tent) then -- Door is for sale
					owner = arista.lang:Get"AL_DOOR_SALE"
				end

				lines:add("Name", name, color_purpleblue, 1)

				local status = arista.entity.getStatus(tent)

				if status ~= "" then
					lines:add("Status", status, color_yellow, 2)
				end

				lines:add("Owner", owner, color_white, 2 + (#status ~= 0 and 1 or 0))
			end
		--[[elseif ( class == "cider_note" ) then
			local wrapped = {};
			if lookingat then
				local text = "";
				for i = 1, 10 do
					local line = tent:GetNetworkedString("cider_Text_"..i);

					-- Check if this line exists.
					if (line ~= "") then
						line = string.Replace(line, " ' ", "'");
						line = string.Replace(line, " : ", ":");

						-- Add the line to our text.
						text = text..line;
					end
				end
				-- Wrap the text into our table.
				cider.chatBox.wrapText(text, "ChatFont", 256, nil, wrapped);
				-- todo: note
			end

			lines:add("Name","Note",color_lightblue,1)

			if lookingat then
				-- Loop through our text
				local i = 0
				for k, v in ipairs(wrapped) do
					lines:add("text"..i,v,color_white,2+i)
					i = i + 1
				end
			end]]
			-- todo: note
		elseif class == "C_BaseEntity" and lookingat then -- func_buttons show up as C_BaseEntity for some reason.
			local name = tent:getTitle()

			if not name or name == "" then
				name = arista.lang:Get"AL_A_BUTTON"
			end

			lines:add("Name", name, color_purpleblue, 1)
		end

		gamemode.Call("AdjustESPLines", lines, tent, pos, distance, lookingat)

		local parsed = lines:getAll()
		for _, line in pairs(parsed) do
			y = self:DrawInformation(line.text, "ChatFont", x, y, line.color, alpha)
		end
	end
end

function GM:DrawPlayerESP(player, lines, pos, distance, lookingat)
	if player == arista.lp then return end
	-- Draw the player's name.
	local addon = ""

	if player:getAristaBool("corpse") then
		addon = arista.lang:Get"AL_X_CORPSE"
	elseif not player:Alive() then
		addon = arista.lang:Get("AL_X_DEAD")
	end

	lines:add("RPName", player:rpName() .. addon .. " (" .. player:UserID() .. ")", team.GetColor(player:Team()), 1)

	local statuslines = 0

	if player:isArrested() then
		lines:add("Status" .. statuslines, arista.lang:Get"AL_STATE_ARRESTED", color_red, 2 + statuslines)
		statuslines = statuslines + 1
	elseif player:isTied() then
		local useKey = input.LookupBinding("+use"):upper()
		local speedKey = input.LookupBinding("+speed"):upper()

		lines:add("Status" .. statuslines, arista.lang:Get"AL_STATE_TIED", color_lightblue, 2 + statuslines)
		statuslines = statuslines + 1

		if lookingat then
			lines:add("Status" .. statuslines, arista.lang:Get("AL_X_PLUS_X_TO_X", useKey, speedKey, arista.lang:Get"AL_UNTIE"), color_white, 2 + statuslines)

			statuslines = statuslines + 1
			end
	end

	local warrant = player:hasWarrant()

	if warrant ~= "" then
		-- Check the class of the warrant.
		if warrant == "search" then
			lines:add("Status" .. statuslines, arista.lang:Get"AL_STATE_SEARCH", color_lightblue, 2 + statuslines)
		elseif warrant == "arrest" then
			lines:add("Status" .. statuslines, arista.lang:Get"AL_STATE_ARREST", color_red, 2 + statuslines)
		end

		statuslines = statuslines + 1
	end

	if lookingat then
		lines:add("Name", player:Name(), color_highpink, 2 + statuslines)
		statuslines = statuslines + 1

		local details = player:getDetails()

		-- Check if they have details set
		if details ~= "" then
			lines:add("Status" .. statuslines, arista.lang:Get"AL_HUD_DETAILS" .. details, color_white, 2 + statuslines)
			statuslines = statuslines + 1
		end

		-- Check if the player is in a clan.
		local clan = player:getClan()

		if clan ~= "" then
			lines:add("Status" .. statuslines, arista.lang:Get"AL_HUD_CLAN" .. clan, color_white, 2 + statuslines)
			statuslines = statuslines + 1
		end

		local job = player:getJob()

		-- Draw the player's job.
		lines:add("Status" .. statuslines, arista.lang:Get"AL_HUD_JOB" .. job, color_white, 2 + statuslines)
		statuslines = statuslines + 1
	end
end

function GM:HUDPaintESP()
	-- The original comments made this 1000x harder to read
	local ply = arista.lp

	if ply:Alive() and not ply:isSleeping() then
		local trace = ply:GetEyeTrace()
		local ent

		if trace.Hit and not trace.HitWorld then
			ent = trace.Entity
		end

		local y = 0
		for _, tent in ipairs(ents.GetAll()) do
			-- We are now in a loop, and there is only one entity handled at a time.
			self:DrawESPLine(ent, tent, ply, y)
		end
	end
end
