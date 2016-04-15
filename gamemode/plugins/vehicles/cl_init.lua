arista.lang:Add("AL_HUD_PETROL", {
	EN = "Petrol: ",
})

arista.lang:Add("AL_HUD_VEHICLEHP", {
	EN = "Vehicle HP: ",
})

arista.lang:Add("AL_VEHICLES_MUSTLOCK", {
	EN = "This car must be locked before it can be flipped.",
})

arista.lang:Add("AL_VEHICLES_FLIP", {
	EN = "Press 'use' to flip this car.",
})

arista.lang:Add("AL_COMMAND_ENGINE", {
	EN = "Start or stop your car's engine.",
})

arista.lang:Add("AL_COMMAND_ENGINE_HELP", {
	EN = "<on|off>",
})

function PLUGIN:PlayerBindPress(ply, bind, pressed)
	if not ply:InVehicle() then return end

	local cmd
	if bind == "+reload" then
		cmd = "honkhorn"
	elseif bind == "+attack2" then
		cmd = "unlockcar"
	elseif bind == "+attack" then
		cmd = "lockcar"
	end

	if cmd then
		RunConsoleCommand(cmd)
	end
end

function PLUGIN:AdjustESPLines(lines, tent, pos, distance, lookingat)
	if tent:GetClass() == "prop_vehicle_jeep" and not arista.lp:InVehicle() then
		local name, text = tent:getAristaString("displayName"), ""

		if not name or name == "" then
			name = "car"
		end

		if arista.entity.isOwned(tent) then
			text = arista.entity.getOwner(tent) .. "'s "
		else
			text = "AL_A"
		end

		-- Draw the information and get the new y position.
		lines:add("Name", arista.lang:Get(text) .. name, color_purple, 1)

		if lookingat then
			local status = arista.entity.getStatus(tent)
			if status ~= "" then
				lines:add("Status", status, color_yellow, 2)
			end

			local ang = tent:GetAngles()
			local text = ""

			if ang.r > 10 or ang.r < -10 then
				if tent:isLocked() then
					text = "AL_VEHICLES_FLIP"
				else
					text = "AL_VEHICLES_MUSTLOCK"
				end

				lines:add("FlipStatus", arista.lang:Get(text), color_orange, 3)
			end
		end
	end
end

local function getFlagColor(var)
	if var >= 66 then
		return "icon16/flag_green"
	elseif var > 33 then
		return "icon16/flag_orange"
	else
		return "icon16/flag_red"
	end
end

local multMph = 15 / 320
local multKph = multMph * 1.609344
function PLUGIN:DrawBottomBars(bar)
	if not arista.lp:InVehicle() then return end

	local vehicle = arista.lp:GetVehicle()
	if vehicle:GetClass() == "prop_vehicle_prisoner_pod" then return end

	local length = vehicle:GetVelocity():Length()
	local speedkph = math.floor(length * multKph)
	local speedmph = math.floor(length * multMph)

	local petrol = math.floor((vehicle:getAristaInt("petrol") or 100) + 0.5) -- Round is a bit less efficent but it's more appropriate here
	local hp = vehicle:Health() -- Why network something that allready gets sorted by source?

	-- Draw the stamina bar.
	GAMEMODE:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_red_alpha, arista.lang:Get"AL_HUD_PETROL" .. petrol .. " %", 100, petrol, bar, getFlagColor(petrol))
	GAMEMODE:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_darkgreen, arista.lang:Get"AL_HUD_VEHICLEHP" .. hp .. " %", 100, hp, bar, "icon16/car")
	GAMEMODE:DrawBar("arista_hudSmall", bar.x, bar.y, bar.width, bar.height, color_alpha, speedmph .. " MPH / " .. speedkph .. " KPH", 100, 100, bar, "icon16/arrow_up")
end
