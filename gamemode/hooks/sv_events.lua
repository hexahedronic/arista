arista.eventHooks = {}

-- todo: language?

local function succeed(ply, ent)
	if IsValid(ply) then
		ply:emote("somehow manages to cut through the rope and puts <P> knife away, job done.")

		ply._unTying = false
	end

	if IsValid(ent) then
		ent:emote("shakes the remains of the rope from <P> wrists and rubs them.")
		ent:unTie()

		ent._beUnTied = false
	end

	gamemode.Call("PlayerUnTied", ply, ent)
end

local function fail(ply, ent)
	if IsValid(ent) and ent:Alive() then
		ent._beUnTied = false
	end

	if IsValid(ply) and ply:Alive() then
		ply:emote("swears and gives up.")

		ply._unTying = false
	end
end

local function test(ply, ent, plystart, entstart)
	return IsValid(ply) and ply:Alive() and ply:GetPos() == plystart and IsValid(ent) and ent:Alive() and ent:GetPos() == entstart
end

-- Called when a player presses a key.
function arista.eventHooks.keyPress(ply, key)
	if key == IN_USE then
		-- Grab what's infront of us.
		local ent = ply:GetEyeTraceNoCursor().Entity

		if not IsValid(ent) then
			return
		elseif ent:isPlayerRagdoll() then
			ent = ent:getRagdollPlayer()
		end

		-- 200 ^ 2, more efficent
		if ent:IsPlayer() and ply:KeyDown(IN_SPEED) and gamemode.Call("PlayerCanUntie", ply, ent) and ent:GetPos():DistToSqr(ply:GetPos()) < 40000 then
			ply:emote("starts ineffectively sawing at <N>'s bonds with a butter knife.", ent)

			arista.timer.conditional(ply:UniqueID() .. " untying timer", arista.config.vars.untyingTime, test, succeed, fail, ply, ent, ply:GetPos(), ent:GetPos())

			ply._unTying = true
			ent._beUnTied = true
		end
	end
end
hook.Add("KeyPress", "arista.eventHooks.keyPress", arista.eventHooks.keyPress)

function arista.eventHooks.playerChangedTeams(ply)
	if not IsValid(ply) then return end

	net.Start("arista_wipeAccess")
	net.Send(ply)

	timer.Simple(1, function()
		if not IsValid(ply) then return end
		arista.entity.updatePlayerAccess(ply)
	end)
end
hook.Add("PlayerChangedTeams", "arista.eventHooks.playerChangedTeams", arista.eventHooks.playerChangedTeams)

function arista.eventHooks.clearTables()
	for index, ent in pairs(arista.entity.stored) do
		if not IsValid(ent) then
			arista.entity.stored[index] = nil
		end
	end
end
timer.Create("arista_clearTables", 30, 0, arista.eventHooks.clearTables)

function arista.eventHooks.earning()
	--[[local contratypes = {}
	for key in pairs(GM.Config["Contraband"]) do
		contratypes[key] = true
	end
	local cplayers = {}
	local dplayers = {}

	for _, ent in ipairs(ents.GetAll()) do
		if contratypes[ent:GetClass()] then
			local ply = ent:GetPlayer();
			-- Check if the ply is a valid entity,
			if ( ValidEntity(ply) ) then
				cplayers[ply] = cplayers[ply] or {refill = 0, money = 0}

				-- Decrease the energy of the contraband.
				ent.dt.energy = math.Clamp(ent.dt.energy - 1, 0, 5)

				-- Check the energy of the contraband.
				if (ent.dt.energy == 0) then
					cplayers[ply].refill = cplayers[ply].refill + 1
				else
					cplayers[ply].money = cplayers[ply].money + GM.Config["Contraband"][ ent:GetClass() ].money
				end
			end
		elseif arista.entity.isDoor(ent) and arista.entity.isOwned(ent) then
			local o = arista.entity.getOwner(ent)
			if type(o) == "Player" and ValidEntity(o) then
				dplayers[o] = dplayers[o] or { 0, {} }
				-- Increase the amount of tax this player must pay.
				dplayers[o][1] = dplayers[o][1] + GM.Config["Door Tax Amount"]
				-- Insert the door into the player's door table.
				table.insert(dplayers[o][2], ent)
			end
		end
	end
	-- Loop through our players list.
	for k, v in pairs(cplayers) do
		if ( IsValid(k) and k:IsPlayer() and hook.Call("PlayerCanEarnContraband",GAMEMODE, k) ) then
			if (v.refill > 0) then
				k:Notify(v.refill.." of your contraband need refilling!", 1)
			end
			if (v.money > 0) then
				k:Notify("You earned $"..v.money.." from contraband.", 0)

				-- Give the player their money.
				k:GiveMoney(v.money)
			end
		end
	end]]

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and not ply:isArrested() then
			local salary = ply:getSalary()
			ply:giveMoney(salary)

			-- Print a message to the player letting them know they received their salary.
			ply:notify("You received $%d salary.", salary)
		end
	end

	--[[if ( GM.Config["Door Tax"] ) then
		-- Loop through our players list.
		for k, v in pairs(dplayers) do
			if ( k:CanAfford(v[1] ) ) then
				k:Notify("You have been taxed $"..v[1].." for your doors.", 0)
			else
				k:Notify("You can't pay your taxes. Your doors were removed.", 1)

				-- Loop through the doors.
				for k2, v2 in pairs( v[2] ) do
					if v2._Removeable then
						v2:Remove()
					else
						k:TakeDoor(v2, true)
					end
				end
			end

			-- Take the money from the player.
			k:GiveMoney(-v[1] )
		end
	end]]

	arista.player.saveAll()
end
timer.Create("arista_earning", arista.config.vars.earningInterval, 0, arista.eventHooks.earning)

local trup, trdown = Vector(0,0,10), Vector(0,0,-2147483648)
local nextsec = CurTime()
function arista.eventHooks.dataUpdate()
	local second = nextsec <= CurTime()
	if second then
		nextsec = CurTime() + 1
	end

	for _, ply in ipairs(player.GetAll()) do
		if ply._inited and ply._updateData then
			gamemode.Call("PlayerTenthSecond", ply)

			if not second then return end
			gamemode.Call("PlayerSecond", ply)

			-- Check if the player is stuck in the world or over open sky (stuck behind world) and disable them.
			--[[if (ply:Alive() and not ply:KnockedOut() and ply:GetMoveType() == MOVETYPE_WALK  and (not ply:IsInWorld() or util.QuickTrace(ply:GetPos() + trup, trdown, ply).HitSky)) then
				ply._StuckInWorld = true;
			else
				ply._StuckInWorld = false;
			end]]

			-- Kick idles
			--[[if (not ply:IsBot() and ply._IdleKick < CurTime()) then
				ply:Kick("AFK for " .. string.ToMinutesSeconds(GM.Config["Autokick time"]).." minutes.");
			end]]
			-- todo: stuff

			-- Disable paracetamol if yer over 50HP
			if ply:Health() > 50 then
				ply:setAristaVar("hideHealthEffects", false)
			end

			-- Give sleeping people a health regen.
			if ply:isSleeping() and ply:Health() < 100 and ply:Alive() then
				-- It seems the game doesn't like fractions. Let's make this only happen once every 2 seconds then.
				if not ply._healthtick then
					ply._healthtick = true
				else
					ply._Healthtick = false

					ply:SetHealth(ply:Health() + 1)
					ply.ragdoll.health = ply:Health()
				end
			end
		end
	end
end
timer.Create("Player Update Timer", 0.1, 0, arista.eventHooks.dataUpdate)

