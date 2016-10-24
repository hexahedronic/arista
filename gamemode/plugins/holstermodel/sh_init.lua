AddCSLuaFile()

PLUGIN.name = "Holster Models"
PLUGIN.weapons = {}

function PLUGIN:alias(wep)
	local ret = table.Copy(self.weapons[wep] or {})
	ret.Priority = wep
	
	return ret
end

--[[
How to add your own weapons:
Method A:
	Figure out your offsets and the bone you want it on and
	create an entry such as shown below.
Method B:
	Alias your weapon to an existing model such as:
	PLUGIN.weapons["weapon_somepistol"] = PLUGIN:alias"weapon_pistol"
	(If you do this it will need to be at the bottom of the list)
]]

PLUGIN.weapons["weapon_pistol"] = {}
PLUGIN.weapons["weapon_pistol"].Model = "models/weapons/w_pistol.mdl"
PLUGIN.weapons["weapon_pistol"].Bone = "ValveBiped.Bip01_Pelvis"
PLUGIN.weapons["weapon_pistol"].BoneOffset = {Vector(0, -8, 0), Angle(0, 90, 0)}
 
PLUGIN.weapons["weapon_357"] = {}
PLUGIN.weapons["weapon_357"].Model = "models/weapons/w_357.mdl"
PLUGIN.weapons["weapon_357"].Bone = "ValveBiped.Bip01_Pelvis"
PLUGIN.weapons["weapon_357"].BoneOffset = {Vector(-5, 8, 0), Angle(0, 270, 0)}
 
PLUGIN.weapons["weapon_frag"] = {}
PLUGIN.weapons["weapon_frag"].Model = "models/items/grenadeammo.mdl"
PLUGIN.weapons["weapon_frag"].Bone = "ValveBiped.Bip01_Pelvis"
PLUGIN.weapons["weapon_frag"].BoneOffset = {Vector(3, -5, 6), Angle(-95, 0, 0)}
 
PLUGIN.weapons["weapon_slam"] = {}
PLUGIN.weapons["weapon_slam"].Model = "models/weapons/w_slam.mdl"
PLUGIN.weapons["weapon_slam"].Bone = "ValveBiped.Bip01_Spine2"
PLUGIN.weapons["weapon_slam"].BoneOffset = {Vector(-9, 0, -7), Angle(270, 90, -25)}
 
PLUGIN.weapons["weapon_crowbar"] = {}
PLUGIN.weapons["weapon_crowbar"].Model = "models/weapons/w_crowbar.mdl"
PLUGIN.weapons["weapon_crowbar"].Bone = "ValveBiped.Bip01_Spine1"
PLUGIN.weapons["weapon_crowbar"].BoneOffset = {Vector(5, 0, 0), Angle(0, 0, 45)}
 
PLUGIN.weapons["weapon_stunstick"] = {}
PLUGIN.weapons["weapon_stunstick"].Model = "models/weapons/w_stunbaton.mdl"
PLUGIN.weapons["weapon_stunstick"].Bone = "ValveBiped.Bip01_Spine1"
PLUGIN.weapons["weapon_stunstick"].BoneOffset = {Vector(5, 0, 0), Angle(0, 0, -45)}
 
PLUGIN.weapons["weapon_shotgun"] = {}
PLUGIN.weapons["weapon_shotgun"].Model = "models/weapons/w_shotgun.mdl"
PLUGIN.weapons["weapon_shotgun"].Bone = "ValveBiped.Bip01_R_Clavicle"
PLUGIN.weapons["weapon_shotgun"].BoneOffset = {Vector(10, 5, 2), Angle(0, 90, 0)}
 
PLUGIN.weapons["weapon_rpg"] = {}
PLUGIN.weapons["weapon_rpg"].Model = "models/weapons/w_rocket_launcher.mdl"
PLUGIN.weapons["weapon_rpg"].Bone = "ValveBiped.Bip01_L_Clavicle"
PLUGIN.weapons["weapon_rpg"].BoneOffset = {Vector(-16, 5, 0), Angle(90, 90, 90)}
 
PLUGIN.weapons["weapon_smg1"] = {}
PLUGIN.weapons["weapon_smg1"].Model = "models/weapons/w_smg1.mdl"
PLUGIN.weapons["weapon_smg1"].Bone = "ValveBiped.Bip01_Spine1"
PLUGIN.weapons["weapon_smg1"].BoneOffset = {Vector(5, 0, -5), Angle(0, 0, 230)}
 
PLUGIN.weapons["weapon_ar2"] = {}
PLUGIN.weapons["weapon_ar2"].Model = "models/weapons/W_irifle.mdl"
PLUGIN.weapons["weapon_ar2"].Bone = "ValveBiped.Bip01_R_Clavicle"
PLUGIN.weapons["weapon_ar2"].BoneOffset = {Vector(-5, 0, 7), Angle(0, 270, 0)}
 
PLUGIN.weapons["weapon_crossbow"] = {}
PLUGIN.weapons["weapon_crossbow"].Model = "models/weapons/W_crossbow.mdl"
PLUGIN.weapons["weapon_crossbow"].Bone = "ValveBiped.Bip01_L_Clavicle"
PLUGIN.weapons["weapon_crossbow"].BoneOffset = {Vector(0, 5, -5), Angle(180, 90, 0)}

PLUGIN.weapons["arista_baton"] = PLUGIN:alias"weapon_stunstick"
PLUGIN.weapons["arista_repair"] = PLUGIN:alias"weapon_crowbar"
