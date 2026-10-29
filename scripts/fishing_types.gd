class_name FishingTypes

enum Discipline {
	SPINNING,      # Open face, bail flip, smooth cast
	BAITCASTING,   # Revolving spool, requires thumb brake, high distance/accuracy
	SPINCAST,      # Push-button beginner friendly, cannot birds-nest
	FLY_FISHING,   # Rhythm false cast, weightless fly carried by fly line
	CONVENTIONAL   # Heavy drag clicker, deep trolling
}

static func get_discipline_name(d: Discipline) -> String:
	match d:
		Discipline.SPINNING: return "Spinning Reel"
		Discipline.BAITCASTING: return "Baitcasting Reel"
		Discipline.SPINCAST: return "Spincast Reel"
		Discipline.FLY_FISHING: return "Fly Fishing Setup"
		Discipline.CONVENTIONAL: return "Conventional / Trolling"
		_: return "Unknown"
