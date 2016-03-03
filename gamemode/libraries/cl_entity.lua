arista.entity = {}
arista.entity.stored = {}

local poetic = CreateClientConVar("arista_poetic", "1", true)

-- Check if an entity is a door.
function arista.entity.isDoor(entity)
	if not entity or not IsValid(entity) then return false end

	local class = entity:GetClass()
	local model = entity:GetModel()

	-- Check if the entity is a valid door class.
	return entity._isDoor
		or class == "func_door"
		or class == "func_door_rotating"
		or class == "prop_door_rotating"
		or model
			and (model:find("gate", 1, true) or model:find("door", 1, true))
			and entity.LookupSequence
			and (entity:LookupSequence("open") or 0) > 0
			and (entity:LookupSequence("close") or 0) > 0
end

function arista.entity.isContainer(entity)
	return false
end

-- Check to see if an entity is owned
function arista.entity.isOwned(entity)
	local owner = arista.entity.getOwner(entity)
	local ownedByPly = entity:getAristaBool("ownedByPlayer")

	return owner and (ownedByPly or owner ~= "Nobody")
end

-- Get an entities status
function arista.entity.getStatus(entity)
	local status = ""
	local p = poetic:GetBool()

	if arista.entity.hasAccess(entity) then
		if p then
			status = "You have access to this"
		else
			status = "(Access)"
		end
	end

	if entity:isLocked() then
		if p then
			if status == "" then
				status = "This is locked"
			else
				status = status .. " and it is locked"
			end
		else
			status = status .. "(Locked)"
		end
	end

	if entity:isSealed() then
		if p then
			if status == "" then
				status = "This is sealed shut"
			elseif status:sub(-2,-1) == "ed" then
				status = status .. " and sealed shut"
			else
				status = status .. ". It is sealed shut"
			end
		else
			status = status .. "(Sealed)"
		end
	end

	if status ~= "" and p then
		status = status .. "."
	end

	return status
end

-- Check to see if an entity is ownable
function arista.entity.isOwnable(entity)
	return tobool(arista.entity.getOwner(entity))
end

-- Get the owner's name of an entity
function arista.entity.getOwner(entity)
	local name = entity:getAristaString("ownerName")

	if name and name ~= "" then
		return name
	end

	return nil
end

-- Does the local player have access to the entity?
function arista.entity.hasAccess(entity)
	return arista.entity.stored[entity]
end

/*
-- Called when the player's access to an entity is changed
local function incomingAccess(msg)
	local ent,access = msg:ReadEntity(),msg:ReadBool() or nil
	arista.entity.stored[ent] = access
	if GetConVarNumber"developer" > 0 and ValidEntity(ent) then
		local moneyAlert = {}

		-- Set some information for the money alert.
		local words = ent:GetNetworkedString("Name","Door")..","..tostring(arista.entity.getOwner(ent))
		moneyAlert.alpha = 255
		moneyAlert.add = 1

		-- Check to see if the amount is negative.
		if access then
			moneyAlert.color = color_white
			moneyAlert.text = "+ "..words
		else
			moneyAlert.color = color_black
			moneyAlert.text = "- "..words
		end
--		debugoverlay.Box(ent:GetPos(),ent:OBBMins(),ent:OBBMaxs(),20,moneyAlert.color,true)
		debugoverlay.Line(LocalPlayer():EyePos() + LocalPlayer():GetForward(),ent:GetPos(),20,moneyAlert.color,true)
		print("[DEBUG] Your access for "..tostring(ent).."['"..words.."'] has been set to '"..tostring(access).."'.")
		-- Insert the money alert into the table.
		table.insert(GAMEMODE.moneyAlerts, moneyAlert)
	end
end
usermessage.Hook("cider_IncomingAccess",incomingAccess)

local function wipeAccess(msg)
	arista.entity.stored = {}
	if GetConVarNumber"developer" > 0 then
		local moneyAlert = {};

		-- Set some information for the money alert.
		moneyAlert.alpha = 255;
		moneyAlert.add = 1;
		moneyAlert.color = color_black;
		moneyAlert.text = "ALL ACCESS WIPED"
		print"[DEBUG] Your access table has been wiped."

		-- Insert the money alert into the table.
		table.insert(GAMEMODE.moneyAlerts, moneyAlert);
	end
end
usermessage.Hook("cider_WipeAccess",wipeAccess)
local function massAccessSystem(msg)
	local len = msg:ReadShort()
	for i=1,len do
		local ent,access = msg:ReadEntity(),msg:ReadBool() or nil
		arista.entity.stored[ent] = access
	end
end
usermessage.Hook("cider_massAccessSystem",massAccessSystem)

timer.Create("keepAccessTableClean",GM.Config["Earning Interval"],0,function()
	for ent,access in pairs(arista.entity.stored) do
		if not ValidEntity(ent) or not access then
			arista.entity.stored[ent] = nil
		end
	end
end)
*/