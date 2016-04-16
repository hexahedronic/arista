arista.content = {}

function arista.content.addFiles(path)
	if not path then
		arista.logs.log(arista.logs.E.LOG, "Setting up FastDL files.")
	end

	local path = path or "content"
	local _, paths = arista.file.find(path .. "/*")

	for k, v in pairs(paths) do
		local files, dirs = arista.file.find(path .. "/" .. v .. "/*")

		for _, f in pairs(files) do
			if f ~= ".svn" and f:sub(-4, -1) ~= ".git" then
					local fpath = path .. "/" .. v .. "/" .. f
					fpath = fpath:gsub("content/", "")

					arista.logs.logNoPrefix(arista.logs.E.DEBUG, "Adding '" .. fpath .. "' to download.")
					resource.AddSingleFile(fpath)
			end
		end

		for _, d in pairs(dirs) do
			local fpath = path .. "/" .. v .. "/" .. d

			arista.content.addFiles(fpath)
		end
	end
end
