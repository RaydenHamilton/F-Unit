local class = {}

class.AR = {
	["Cost"] = 25,
	["Bloom"] = 15,
	["ClipSize"] = 12,
	["Damage"] = 30,
	["FiringRate"] = 0.5,
	["Range"] = 200,
	["ReloadTime"] = 1,
}

class.SMG = {
	["Cost"] = 25,
	["Bloom"] = 5,
	["ClipSize"] = 6,
	["Damage"] = 75,
	["FiringRate"] = 0.5,
	["Range"] = 200,
	["ReloadTime"] = 1,
}

class.Sniper = {
	["Cost"] = 0,
	["Bloom"] = 1,
	["ClipSize"] = 6,
	["Damage"] = 85,
	["FiringRate"] = 2.75,
	["Range"] = 200,
	["ReloadTime"] = 6,
}

class.LMG = {
	["Cost"] = 25,
	["Bloom"] = 5,
	["ClipSize"] = 40,
	["Damage"] = 24,
	["FiringRate"] = 0.25,
	["Range"] = 200,
	["ReloadTime"] = 4,
}

class.Rifle = {
	["Cost"] = 25,
	["Bloom"] = 5,
	["ClipSize"] = 6,
	["Damage"] = 75,
	["FiringRate"] = 2.75,
	["Range"] = 200,
	["ReloadTime"] = 6,
}

class.Shotgun = {
	["Cost"] = 25,
	["Bloom"] = 20,
	["ClipSize"] = 2,
	["Damage"] = 90,
	["FiringRate"] = 1,
	["Range"] = 50,
	["ReloadTime"] = 3,
}

class.tankoperator = {
	["Cost"] = 100,
	["Speed"] = 50,
	["Health"] = 500,
	["Damage"] = 100,
	["ReloadTime"] = 5,
}

return class
