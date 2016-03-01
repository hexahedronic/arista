-- arista: RolePlay FrameWork --
include("sh_init.lua")

net.Receive("arista_sendMapEntities", function()
	local amt = net.ReadUInt(8)

	for i = 1, amt do
		local ent = net.ReadEntity()

		arista._internaldata.entities[ent] = ent
	end
end)
