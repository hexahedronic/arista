arista.eventHooks = {}

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
	for index, ent in pairs(arista._internaldata.entity_stored) do
		if not IsValid(ent) then
			arista._internaldata.entity_stored[index] = nil
		end
	end
end
timer.Create("arista_clearTables", 30, 0, arista.eventHooks.clearTables)

function arista.eventHooks.earning()
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and not ply:isArrested() then
			local salary = ply:getSalary()
			salary = hook.Run("AdjustSalaryEarning", ply, salary) or salary or 100
			ply:giveMoney(salary)

			-- Print a message to the player letting them know they received their salary.
			ply:notify("AL_X_SALARY", salary)
		end
	end

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

			if not second then continue end
			gamemode.Call("PlayerSecond", ply)

			-- Disable paracetamol if yer over 50HP
			if ply:Health() > 50 then
				ply:setAristaVar("hideHealthEffects", false)
			end

			local donator = ply:getAristaVar("donator")

			if donator and donator > 0 then
				local expire = math.max(donator - os.time(), 0)

				if expire <= 0 then
					arista.player.expireDonator(ply)
				end
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

