arista.entity = {}
arista._internaldata.entity_stored = {}

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
	return entity:getAristaBool("container")
end

-- Check to see if an entity is owned
function arista.entity.isOwned(entity)
	local owner = arista.entity.getOwner(entity)
	local ownedByPly = entity:getAristaBool("ownedByPlayer")

	return owner and (ownedByPly or (owner ~= "Nobody" and owner ~= ""))
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
	--local name = entity:getAristaString("ownerName")
	return entity:getAristaString("ownerName")
end

-- Does the local player have access to the entity?
function arista.entity.hasAccess(entity)
	return arista._internaldata.entity_stored[entity:EntIndex()]
end

-- Called when the player's access to an entity is changed
local function incomingAccess(msg)
	local ent = net.ReadUInt(16)
	local access = net.ReadBool()

	arista._internaldata.entity_stored[ent] = access
end
net.Receive("arista_incomingAccess", incomingAccess)

local function wipeAccess(msg)
	arista._internaldata.entity_stored = {}
end
net.Receive("arista_wipeAccess", wipeAccess)

function arista.entity.cleanTable()
	for entidx, access in pairs(arista._internaldata.entity_stored) do
		if not access then
			arista._internaldata.entity_stored[entidx] = nil
		end
	end
end
timer.Create("keepAccessTableClean", arista.config.vars.earningInterval, 0, arista.entity.cleanTable)
