function PLUGIN:getNewPos(pos, ang, apos)
	return pos + ang:Forward() * apos.x + ang:Right() * apos.y + ang:Up() * apos.z
end

local vu_enablehorn = CreateConVar("arista_enable_horn", "1")
function PLUGIN:makeVehicle(player, pos, ang, model, class, vname, vtable)
	local ent = ents.Create(class)
	if not IsValid(ent) then
		error("["..os.date().."] Vehicles Plugin: could not spawn a " .. class .. "!")
	end

	ent:SetModel(model)
	ent:SetAngles(ang)
	ent:SetPos(pos)

	if vtable and vtable.KeyValues then
		for k, v in pairs(vtable.KeyValues) do
			ent:SetKeyValue(k, v)
		end
	end

	if vtable.Members then
		table.Merge(ent, vtable.Members)
		duplicator.StoreEntityModifier(ent, "VehicleMemDupe", vtable.Members)
	end

	ent:Spawn()
	ent:Activate()

	local p = ent:GetPhysicsObject()
	if not IsValid(p) then
		ent:Remove()
		player:notify("You cannot spawn that car at this time.")

		return NULL
	elseif false then--p:IsPenetrating() then
		ent:Remove()
		player:notify("You cannot spawn your car there!")

		return NULL
	end

	ent.VehicleName  = vname
	ent.VehicleTable = vtable
	ent.NoClear		 = true

	-- We need to override the class in the case of the Jeep, because it
	-- actually uses a different class than is reported by GetClass
	ent.ClassOverride = class

	gamemode.Call("PlayerSpawnedVehicle", player, ent)

	return ent
end

local sky, ang, spawnstep = Vector(0, 0, 100000), Angle(0, 0, 0), Vector(0,0,20)
local toolfunc = function(self, ply, trace, mode)
	return ply:IsAdmin()
end
function PLUGIN:SpawnCar(ply, item)
	if item.canSpawn and not item:canSpawn(ply) then
		return false
	end

	if IsValid(ply._vehicle) then
		ply:notify("You may not have two cars out at once. Go find your %s!", ply._vehicle.DisplayName)

		return false
	elseif (ply._nextVehicleSpawn or 0) > CurTime() then
		ply:notify("You must wait another %s minutes before you can spawn your car again.", string.ToMinutesSeconds(ply._nextVehicleSpawn - CurTime()))
	return false end

	local car = list.Get("Vehicles")[item.vehicleName]
	if not car then
		ply:notify("Invalid car referenced!")
		error("["..os.date().."] Vehicles Plugin: Error spawning a "..item.name..": Invalid vehicle type specified: '"..item.vehicleName.."'.")
	end

	local name = car.RPName or car.Name
 	local tr = ply:GetEyeTraceNoCursor()
 	local trace = util.QuickTrace(tr.HitPos, sky)

	if trace.Hit and not trace.HitSky then
		ply:notify("You must spawn your %s under open sky!", name)
	return false end

	ang.yaw = ply:GetAngles().yaw + 180

	local ent = self:makeVehicle(ply, tr.HitPos + spawnstep, ang, car.Model, car.Class, item.vehicleName, car)
	if (not IsValid(ent)) then return end
	ent:CPPISetOwner(ply)

	ent.CanTool = toolfunc
	ent:lock()

	ply._vehicle = ent

	return ent
end

-- Setup some stuff and passenger seats
function PLUGIN:PlayerSpawnedVehicle(ply, car)
	local pos, ang = car:GetPos(), car:GetAngles()
	car:SetUseType(SIMPLE_USE)

	local tab = car.VehicleTable
	if not tab then return end

	if tab.Ownable then
		arista.entity.makeOwnable(car)
		arista.entity.setOwnerPlayer(car, ply)
	end

	if tab.Skin then
		car:SetSkin(tab.Skin)
	end

	car.DisplayName = tab.RPName or tab.Name
	car:networkAristaVar("displayName", car.DisplayName)
	car:networkAristaVar("vehicleName", car.VehicleName)

	car:networkAristaVar("petrol", 100)
	car:SetHealth(100)

	if tab.Passengers then
		local data = list.Get("Vehicles")[tab.SeatType]
		if not data then
			arista.logs.log(arista.logs.E.ERROR, "Vehicles: Cannot get passenger seat data!")
		return end

		for i, v in pairs(tab.Passengers) do
			local seat = ents.Create("prop_vehicle_prisoner_pod")
				if not IsValid(seat) then
					arista.logs.log(arista.logs.E.ERROR, "Vehicles: Cannot spawn passenger seat entity!")
				continue end
				seat:SetModel(data.Model)
				seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
				seat:SetAngles(ang + v.Ang)
				seat:SetPos(self:getNewPos(pos, ang, v.Pos))
			seat:Spawn()
			seat:Activate()

			seat:SetParent(car)

			seat:Fire("lock", "", 0)
			seat:SetCollisionGroup(COLLISION_GROUP_WORLD)

			if tab.HideSeats then
				seat:SetRenderMode(RENDERMODE_TRANSALPHA)
				seat:SetColor(color_transparent)
			end

			if data.Members then
				table.Merge(seat, data.Members)
			end

			if data.KeyValues then
				for k, v in pairs(data.KeyValues) do
					seat:SetKeyValue(k, v)
				end
			end

			seat.VehicleName = "Seat"
			seat.VehicleTable = data
			seat._isSeat = true

			seat.ClassOverride = "prop_vehicle_prisoner_pod"

			seat:DeleteOnRemove(car)
			tab.Passengers[i].Ent = seat
		end
	end

	car:networkAristaVar("engineOn", false)
	car:Fire('turnoff', '', 0)
end

function PLUGIN:CanManufactureCar(ply, item)
	local inv = ply:getAristaVar("inventory")
	if (inv[item.uniqueID] or 0) >= 1 then
		ply:notify("You cannot own more than 1 %s!", item.name)
	elseif not arista.inventory.canFit(ply, item.size) then
		ply:notify("You do not have enough inventory space to buy this!")
	else
		return true
	end

	return false
end

function PLUGIN:ManufactureCar(ply, ent, item)
	arista.inventory.update(ply, item.uniqueID, 1)
	ply:notify("Your %s has been delivered to your inventory.", item.name)

	-- Don't let this drop on floor.
	ent:Remove()
end

function PLUGIN:SellCar(ply, item)
	if IsValid(ply._vehicle) and ply._vehicle.VehicleName == item.vehicleName then
		ply:notify("You cannot sell your %s while it is still spawned!", item.name)
	return false end

	return true
end

function PLUGIN:damageCar(car, dmg, entity)
	local hp = car:Health()
		hp = math.Clamp(hp - math.floor(dmg:GetDamage() * 4), 0, 100)
	car:SetHealth(hp)

	if hp <= 0 and not (car._fire and IsValid(car._fire)) then
		car:Fire('turnoff', '', 0)
		car:setAristaVar("engineOn", false)

		local fire = ents.Create("arista_fire")
		if fire and fire:IsValid() then
				fire:SetPos(car:GetPos())
			fire:Spawn()
			fire:Activate()

			fire:SetPos(car:GetPos())
			fire:SetParent(car)

			car:DeleteOnRemove(fire)
			car._fire = fire
		end

		local effectData = EffectData()
			effectData:SetStart(car:GetPos())
			effectData:SetOrigin(car:GetPos())
			effectData:SetScale(3)
		util.Effect("Explosion", effectData)

		dmg:SetDamage(10)
		if not entity then return end

		entity:ExitVehicle()
		entity:notify("Your car has been destroyed.")

		timer.Simple(0, function()
			if not (entity and entity:IsValid()) then return end
			entity:knockOut(20)
		end)
	end
end

function PLUGIN:EntityTakeDamage(entity, dmg)
	if entity:IsVehicle() then
		local tbl = entity.VehicleTable

		if tbl then
			if tbl.Windowlevel then
				if entity:GetDriver():IsPlayer() then
					local damageheight = entity:WorldToLocal(dmg:GetDamagePosition())

					if damageheight.z >= tbl.Windowlevel then
						if dmg:IsBulletDamage() and dmg:GetDamage() < 0.01 then
							dmg:SetDamage(dmg:GetDamage() * 10000)
						end
					end
				end
			end

			self:damageCar(entity, dmg)
		end
	elseif entity:IsPlayer() then
		if entity:InVehicle() then
			if entity:getAristaVar("hunger") == 0 then return end

			local car = entity:GetVehicle()
			local attacker = dmg:GetAttacker()

			if car.VehicleTable then
				local damageheight = car:WorldToLocal(dmg:GetDamagePosition())

				if car.VehicleTable.Windowlevel and damageheight and damageheight.z >= car.VehicleTable.Windowlevel then
					dmg:SetDamage(dmg:GetDamage() * 10)
				else
					self:damageCar(car, dmg, entity)
				end
			end
		end
	end
end

function PLUGIN:PickupCar(ply, item)
	if arista.config.plugins.vehiclePickupZone then
		-- todo: this
		-- arista.config.plugins.vehiclePickupZone = {mins = vec, maxs = vec}
		-- if car:isintheregion then continue with this, else return false end
		return false
	end

	if not (ply:InVehicle() and ply:GetVehicle() == ply._vehicle) then
		ply:notify("You must be in your %s to pick it up!", item.name)
	return false end

	ply:ExitVehicle()

	ply._vehicle:Remove()
	ply._nextVehicleSpawn = CurTime() + 300

	arista.logs.event(arista.logs.E.LOG, arista.logs.E.COMMAND, ply:Name(), "(", ply:SteamID(), ") picked up their vehicle (", item.name, ").")

	return true
end

local ignores	= {
	predicted_viewmodel = true,
	physgun_beam = true,
	keyframe_rope = true,
}
function PLUGIN:checkPos(ply, car, pos)
	local enttab = ents.FindInSphere(pos, 16)

	for k, ent in ipairs(enttab) do
		if ent:IsWeapon() or ignores[ent:GetClass()] or ent:GetSolid() == SOLID_NONE then
			enttab[k] = nil
		end
	end

	if table.Count(enttab) == 0 and util.IsInWorld(pos) and car:VisibleVec(pos) then
		return pos
	end
end

local exits	= {"exit1", "exit2", "exit3", "exit4", "exit5", "exit6"}
function PLUGIN:doExit(ply, _car)
	local car = _car or ply:GetVehicle()
	if not IsValid(car) then
		-- We might potentially have been passed a null for icar.
		if not IsValid(_car) and IsValid(ply:GetVehicle()) then
			car = ply:GetVehicle()
		else -- ok, something's gone wrong. Bail out.
			return
		end
	end

	local par = car:GetParent()
	if IsValid(par) and par:IsVehicle() then
		car = par
	end

	if car:isLocked() then
		return
	end

	if ply:InVehicle() then
		ply:ExitVehicle()
	end

	if ply:InVehicle() then -- You'd think this was unnecessary, but shit happens. :/
		arista.utils.nextFrame(self.doExit, self, ply, car)
	return end

	local tab = car.VehicleTable
	if not tab then return end

	local exitpos
	if tab.Customexits then
		local pos, ang = car:GetPos(), car:GetAngles()

		for i, v in ipairs(tab.Customexits) do
			exitpos = self:getNewPos(pos, ang, v)
			exitpos = self:checkPos(ply, car, exitpos)

			if exitpos then
				ply:SetPos(exitpos)
			return end
		end
	end

	for _,v in ipairs(exits) do
		exitpos = car:GetAttachment(car:LookupAttachment(v))

		if exitpos and exitpos.Pos then
			exitpos = self:checkPos(ply, car, exitpos.Pos)

			if exitpos then
				ply:SetPos(exitpos)
			return end
		end
	end
end

function PLUGIN:PlayerUse(ply, ent)
	if not ent:IsVehicle() then
		return
	elseif ply:isUnconscious() then
		return false
	elseif ply:isBlacklisted("cat", CATEGORY_VEHICLES) > 0 then
		ply:blacklistAlert("cat", CATEGORY_VEHICLES, GAMEMODE:GetCategory(CATEGORY_VEHICLES).name)
	return false end

	local ang = ent:GetAngles()
	if ent:isLocked() then
		if math.abs(ang.r) > 10 then
			ang.r, ang.p = 0, 0

			ent:SetAngles(ang)
			ent:Spawn() -- The legendary car flip fix!!1111
		end

		return false
	end

	local tab = ent.VehicleTable
	if not tab then return end

	if tab.Doors then
		local pos = ent:WorldToLocal(ply:GetEyeTrace().HitPos)
		local success

		for _, door in ipairs(tab.Doors) do
			local a, b, c = door.topleft, door.bottomright, pos
			if not (c.z < math.min(a.z,b.z) or c.z > math.max(a.z,b.z) or
					c.x < math.min(a.x,b.x) or c.x > math.max(a.x,b.x) or
					c.y < math.min(a.y,b.y) or c.y > math.max(a.y,b.y)) then
				success = true

				break
			end
		end

		if not success then
			return false
		end
	end

	if tab.Passengers then
		if not IsValid(ent:GetDriver()) then
			if not ent:getAristaVar("engineOn") then
				ply:notify("Type '/engine on' to start the car's engine!")
			end

			return true -- No one's driving? Let's get in!
		end

		for _, v in pairs(tab.Passengers) do
			if IsValid(v.Ent) and not IsValid(v.Ent:GetDriver()) then
				v.Ent:Fire("unlock", "", 0)
					ply:EnterVehicle(v.Ent)
				v.Ent:Fire("lock", "", 10)

				return true -- odd shit happens if we don't do this. :/
			end
		end

		return false -- It seems all the seats are occupied.
	end
end

function PLUGIN:PlayerTenthSecond(player, item)
	if not player:InVehicle() then return end

	-- Check if the player is in a vehicle.
	if player:InVehicle() then
		local vehicle = player:GetVehicle()

		if vehicle:GetClass() == "prop_vehicle_prisoner_pod" then return end

		local petrol = vehicle:getAristaVar("petrol") or 0
		if petrol > 0 then
			if vehicle:getAristaVar("engineOn") then
				if vehicle:GetVelocity():Length() <= 0 then
					petrol = math.Clamp(petrol - 0.0015, 0, 100)
				else
					petrol = math.Clamp(petrol - 0.01, 0, 100)
				end

				vehicle:setAristaVar("petrol", petrol)
			end
		else
			if vehicle:getAristaVar("engineOn") then
				vehicle:Fire('turnoff', '', 0)
				vehicle:setAristaVar("engineOn", false)

				player:notify("This vehicle has run out of petrol!")
			end
		end
	end
end

arista.command.add("engine", "", 1, function(player, toggle)
	local vehicle = player:GetVehicle()

	if player:InVehicle() then
		if vehicle.VehicleTable and vehicle.VehicleTable.Passengers then -- Security first
			if toggle == "on" then
				if vehicle:Health() <= 0 then
					player:notify("Engine can't start due to damage")

					return false
				elseif vehicle:getAristaVar("petrol") <= 0 then
					player:notify("Engines can't start without petrol.")

					return false
				elseif player:isArrested() or player:isTied() then
					player:notify("Unable to start engine when your hands are handcuffed/tied-up!")

					return false
				else
					vehicle:Fire('turnon', '', 0);
					vehicle:setAristaVar("engineOn", true)

					player:emote("started the engine.")
				end
			end

			if toggle == "off" then
				if vehicle:getAristaVar("engineOn") then
					vehicle:Fire('turnoff', '', 0)
					vehicle:setAristaVar("engineOn", false)

					player:emote("turned the engine off.")
				else
					player:notify("The engine is already turned off!")
				end
			end
		else
			player:notify("You need to drive a car!")
		end
	else
		player:notify("You need to be inside a car!")
	end;
end, "AL_COMMAND_CAT_COMMANDS", true)

function PLUGIN:KeyPress(ply, key)
	if key == IN_USE and ply:InVehicle() then
		self:doExit(ply)

		return false -- Waiting for source to do this is unreliable. I will do the exit myself.
	end
end

function PLUGIN:PlayerDisconnected(ply)
	if ply._vehicle and IsValid(ply._vehicle) then
		ply._vehicle:Remove()
	end
end

concommand.Add("honkhorn", function(ply)
	local vehicle = ply:GetVehicle()
	if not (vehicle and vehicle:IsValid()) then return end

	ply._nextHonk = ply._nextHonk or CurTime()

	if ply._nextHonk > CurTime() then
		return false
	elseif not ply:IsSuperAdmin() then
		ply._nextHonk = CurTime() + 5
	end

	if ply:InVehicle() and vu_enablehorn:GetBool() then
		local car = ply:GetVehicle()

		if car.VehicleTable and car.VehicleTable.Horn then
			car:EmitSound(car.VehicleTable.Horn.Sound, 100, car.VehicleTable.Horn.Pitch)
		end
	end
end)

concommand.Add("lockcar", function(ply)
	local vehicle = ply:GetVehicle()

	if vehicle and arista.entity.hasAccess(vehicle, ply) then
		vehicle:lock()
		ply:EmitSound("doors/door_latch3.wav")
	end
end)

concommand.Add("unlockcar", function(ply)
	local vehicle = ply:GetVehicle()

	if vehicle and arista.entity.hasAccess(vehicle, ply) then
		vehicle:unLock()
		ply:EmitSound("doors/door_latch3.wav")
	end
end)
