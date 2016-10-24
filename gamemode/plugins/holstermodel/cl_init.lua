function PLUGIN:getOffset(pos, ang, off)
	return pos + ang:Right() * off.x + ang:Forward() * off.y + ang:Up() * off.z
end

local nextUpdate = CurTime()
local attachedFlags = bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES)
function PLUGIN:Think()
	if nextUpdate > CurTime() then return end
	nextUpdate = CurTime() + 2
	
	for idx, ply in ipairs(player.GetAll()) do
		ply.cs_holster = {}
		if not ply:Alive() then continue end
		 
		for i, v in ipairs(ply:GetWeapons()) do
			if not IsValid(v) then continue end
			if ply.cs_holster[v:GetClass()] then continue end
			
			local tbl = self.weapons[v:GetClass()]
			if not tbl then continue end
			 
			local worldmodel = tbl.Model or v.WorldModelOverride or v.WorldModel
			if not worldmodel or worldmodel == "" then continue end
			
			ply.cs_holster[v:GetClass()] = ClientsideModel(worldmodel, RENDERGROUP_OPAQUE)
				ply.cs_holster[v:GetClass()]:SetNoDraw(true)
				ply.cs_holster[v:GetClass()]:SetSkin(tbl.Skin or v:GetSkin())
				ply.cs_holster[v:GetClass()]:SetColor(tbl.Color or v:GetColor())
			 
			if tbl.Scale then
				ply.cs_holster[v:GetClass()]:SetModelScale(tbl.Scale)
			end
			if tbl.BuildBonePositions then
				ply.cs_holster[v:GetClass()].BuildBonePositions = tbl.BuildBonePositions
			end
			if v.MaterialOverride or (v:GetMaterial() and v:GetMaterial() ~= "") then
				ply.cs_holster[v:GetClass()]:SetMaterial(v.MaterialOverride or v:GetMaterial())
			end
			
			ply.cs_holster[v:GetClass()].WModelAttachment = v.WModelAttachment
			ply.cs_holster[v:GetClass()].WorldModelVisible = v.WorldModelVisible
			
			local attachedwmodel = v.AttachedWorldModel
			if attachedwmodel then
				ply.cs_holster[v:GetClass()].AttachedModel = ClientsideModel(attachedwmodel, RENDERGROUP_OPAQUE)
					ply.cs_holster[v:GetClass()].AttachedModel:SetNoDraw(true)
					ply.cs_holster[v:GetClass()].AttachedModel:SetSkin(v:GetSkin())
					ply.cs_holster[v:GetClass()].AttachedModel:SetParent(ply.cs_holster[v:GetClass()])
					ply.cs_holster[v:GetClass()].AttachedModel:AddEffects(attachedFlags)
			end
		end
	end
end
 
function PLUGIN:PostPlayerDraw(ply)
	if not IsValid(ply) then return end
	if not ply.cs_holster then return end
	
	for k, v in pairs(ply.cs_holster) do
		local tbl = self.weapons[k]
		if not (tbl and ply:HasWeapon(k)
			and (not IsValid(ply:GetActiveWeapon()) or ply:GetActiveWeapon():GetClass() ~= k))
		then continue end
		
		if tbl.Priority then
			local priority = tbl.Priority
			
			if self.weapons[priority] and ply:HasWeapon(priority) and
				(IsValid(ply:GetActiveWeapon()) or ply:GetActiveWeapon():GetClass() ~= priority)
			then continue end
		end
		 
		local wep = ply:GetWeapon(k)
		
		local bone = ply:LookupBone(tbl.Bone or "")
		if not bone then continue end
		
		local matrix = ply:GetBoneMatrix(bone)
		if not matrix then continue end
		
		local pos = matrix:GetTranslation()
		local ang = matrix:GetAngles()
		
		local pos = self:getOffset(pos, ang, tbl.BoneOffset[1])
		v:SetRenderOrigin(pos)
		
		ang:RotateAroundAxis(ang:Forward(), tbl.BoneOffset[2].p)
		ang:RotateAroundAxis(ang:Up(), tbl.BoneOffset[2].y)
		ang:RotateAroundAxis(ang:Right(), tbl.BoneOffset[2].r)
		
		v:SetRenderAngles(ang)
		
		if v.WorldModelVisible ~= false then
			v:DrawModel()
		end
		if IsValid(v.AttachedModel) then
			v.AttachedModel:DrawModel()
		end
		
		if v.WModelAttachment and multimodel then
			multimodel.Draw(v.WModelAttachment, wep, {origin = pos, angles = ang})
			multimodel.DoFrameAdvance(v.WModelAttachment, CurTime(), wep)
		end
		
		if tbl.DrawFunction then
			tbl.DrawFunction(v, ply)
		end
	end
end
