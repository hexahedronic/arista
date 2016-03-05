AddCSLuaFile()

---
-- Called when a player attempts to join a team (server) or the job list is updated (client)
-- @param ply The player in question
-- @param target The target team's ID
-- @return True if they can, False if they can't.
function GM:PlayerCanJoinTeamShared(ply, target)
	do return true end -- REEEEE
	local team = arista.team.get(target)

	-- Check if this is a valid team.
	if not team then return false end

	--VGUI nonsence
	if CLIENT then
		if ply:Team() == team.index then
			return true
		end
	end

	-- Begin groups shit
	local cteam = arista.team.get(ply:Team())
	if not cteam then return true end

	local aimlevel = arista.team.getGroupLevel(team.index)
	local mylevel = arista.team.getGroupLevel(cteam.index)

	local aimgroup = arista.team.getGroupByTeam(team.index)
	local mygroup = arista.team.getGroupByTeam(cteam.index)

	-- todo: language stuff below

	if aimlevel == 1 and aimgroup == mygroup then
		--You can reset yourself to your group's base class
		return true
	elseif aimgroup ~= mygroup then
		--We wish to swap groups
		if not aimlevel == 1 and mylevel == 1 then
			--You can only change groups via level 1
			if SERVER then ply:notify("You can only change groups via the base classes!") end

			return false
		end

		-- Check if we are using a master race
		if arista.config.useMasterGroup then
			if team.group.access:find("M", 1, true) or cteam.group.access:find("M", 1, true) then
				--They are moving to or from the master race
				return true
			else
				if SERVER then ply:notify("You cannot go straight to this group!") end

				return false
			end
		else
			--return true because there is no master race and the other requirements are met
			return true
		end
	elseif aimlevel == mylevel + 1 or aimlevel == mylevel - 1 then
		--All level changes must be in steps of one
		local cgang, egang = arista.team.getGang(cteam.index),arista.team.getGang(team.index)

		if egang == cgang then
			--not a problem, we're not moving gang
			return true
		elseif mylevel == 1 or aimlevel == 1 then
			--You can only leave/enter a gang via level 1
			return true
		else
			if SERVER then ply:notify("You can only change gangs via the base class!") end

		end
	else
		if SERVER then ply:notify("You cannot join that team!") end

		return false
	end
end
---
-- Called when a player attempts to demote another player.
-- @param ply The player attempting
-- @param target The intended victim
-- @return true if they can false if they can't
function GM:PlayerCanDemote(ply, target)
	local err = ""
	if target:Team() == TEAM_DEFAULT then
		if SERVER then
			ply:Notify("You cannot demote players from the default team!")
		end
		return false
	elseif (target:Arrested() or target:Tied()) then
		if SERVER then
			ply:Notify("You cannot demote %s right now!", target:Name())
		end
		return false
		-- todo: mod
	elseif --[[ply:IsModerator()]] arista.utils.isAdmin(ply) then
		return true
	end

	local tteam, mteam = target:Team(), ply:Team()
	local tlevel,mlevel,tgroup,mgroup,tgang,mgang =
			arista.team.getGroupLevel(tteam),
			arista.team.getGroupLevel(mteam),
			arista.team.getGroupByTeam(tteam),
			arista.team.getGroupByTeam(mteam),
			arista.team.getGang(tteam),
			arista.team.getGang(mteam)

	if tgroup ~= mgroup then
		err = "You cannot demote players in a different group!"
	elseif tlevel == 1 then
		err = "You cannot demote a player from the base class!"
	elseif tlevel > mlevel then
		err = "You cannot demote a player with a higer level than you!"
	elseif mlevel == tlevel and not arista.team.hasAccessGroup(mteam, "b") then
		err = "You do not have access to demote players at the same level as yourself!"
	elseif not arista.team.hasAccessGroup(mteam,"d") then
		err = "You do not have access to demote this player!"
	elseif tgang ~= mgang then
		err = "You cannot demote players in other gangs!"
	end

	if err == "" then
		return true
	else
		if SERVER then
			ply:notify(err)
		end

		return false
	end
end

-- Called when a player attempts to noclip.
function GM:PlayerNoClip(ply)
	if ply:useDisallowed() then
		return false
	end

	return arista.utils.isAdmin(ply)
end