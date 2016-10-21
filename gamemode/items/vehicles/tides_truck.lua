ITEM.name					= "Truck"
ITEM.cost					= 150000
ITEM.model				= "models/tideslkw.mdl"
ITEM.store				= true
ITEM.plural				= "Trucks"
ITEM.description	= "A large truck that can move a lot of stuff."
ITEM.vehicleName	= "tideslkw" -- It's vehicle script.
ITEM.base					= "vehicle"

local v = {
	Name = ITEM.name,
	Class = "prop_vehicle_jeep",
	Category = "Vehicles",
	Author = arista.gamemode.author,
	Information = ITEM.description,
	Model = ITEM.model,

	Windowlevel = 53,

	Passengers  = {
		passenger1 = {
			Pos = Vector(21,-78,40), Ang = Angle(0,0,0)
		},
	},

	Customexits = {Vector(-90, -78, 40),Vector(90, -78, 40), Vector(0, 0, 90)},
	HideSeats = true,

	Horn = {
		Sound = "vu_horn_simple.wav",
		Pitch = 90,
	},

	SeatType = "Seat_Jeep",
	ModView = 12,
	KeyValues = {
		vehiclescript	=	"scripts/vehicles/" .. ITEM.vehicleName .. ".txt"
	},

	Ownable = true,
}
list.Set("Vehicles", ITEM.vehicleName, v)
