arista.lang = {}

arista.lang.EN = {
}

-- todo: go find all the 'todo: language' shit and replace here.
function arista.lang:Get(str)
	return arista.lang.EN[str] or str or ""
	-- todo: language selection
end
