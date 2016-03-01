arista.math = {}

function arista.math.decimalPlaces(num, places)
	return math.Round(num * 10^places) / 10^places
end
