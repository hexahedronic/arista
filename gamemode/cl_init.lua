-- arista: RolePlay FrameWork --
include("sh_init.lua")

net.Receive("arista_sendMapEntities", function()
	local amt = net.ReadUInt(16)

	for i = 1, amt do
		local ent = net.ReadEntity()

		arista._internaldata.entities[ent] = ent
	end
end)

net.Receive("arista_notify", function()
	local form = net.ReadString()
	local amt = net.ReadUInt(8)

	local args = {}
	for i = 1, amt do
		args[i] = net.ReadString(v)
	end

	form = arista.lang:Get(form)

	local msg = form:format(unpack(args))

	chat.AddText(color_white, msg)
end)
