class_name FishDatabase

class FishData:
	var name: String
	var description: String
	var rarity: String
	var difficulty: int
	var min_weight: float
	var max_weight: float
	var texture_path: String
	var model_path: String
	var preferred_baits: Array[String]

	func _init(n: String, desc: String, r: String, diff: int, min_w: float, max_w: float, tex: String, model: String = "", baits: Array[String] = []):
		name = n
		description = desc
		rarity = r
		difficulty = diff
		min_weight = min_w
		max_weight = max_w
		texture_path = tex
		model_path = model
		preferred_baits = baits

static var catalog: Array[FishData] = [
	FishData.new("Sunfish", "A small, peaceful fish that glints in the sunlight.", "Common", 1, 0.3, 1.2, "res://assets/fish/sunfish.png", "res://models/fish/bluegill.glb", ["Worms", "Corn"]),
	FishData.new("Bass", "A common freshwater game fish with an aggressive strike.", "Common", 2, 1.5, 6.5, "res://assets/fish/bass.png", "res://models/fish/large_mouth_bass.glb", ["Minnows", "Worms"]),
	FishData.new("Trout", "A beautiful freshwater river fish with speckled sides.", "Uncommon", 2, 1.0, 4.2, "res://assets/fish/trout.png", "res://models/fish/rainbow_trout.glb", ["Corn", "Minnows"]),
	FishData.new("Catfish", "A heavy bottom feeder with whiskers and a strong pull.", "Uncommon", 3, 3.0, 15.0, "res://assets/fish/catfish.png", "res://models/fish/catfish.glb", ["Cheese", "Worms"]),
	FishData.new("Golden Carp", "A rare, shimmering golden carp said to bring good fortune.", "Rare", 4, 4.5, 12.0, "res://assets/fish/golden_carp.png", "res://models/fish/Carp.glb", ["Corn", "Cheese"]),

	# =========================================================================
	# NIGHT / DEEP CRYPTIDS (Temporarily commented out per request)
	# =========================================================================
	# FishData.new("Pale Crawler", "A mysterious pale cryptid fish that only bites in deep waters.", "Uncommon", 3, 2.0, 5.5, "res://assets/fish/pale_crawler.png"),
	# FishData.new("Bleeding Carp", "An unusual carp with strange, pulsing crimson markings.", "Rare", 5, 6.0, 18.0, "res://assets/fish/bleeding_carp.png"),
	# FishData.new("Whispering Eel", "A long, slender eel that seems to move with intelligent purpose.", "Rare", 5, 2.5, 9.0, "res://assets/fish/whispering_eel.png"),
	# FishData.new("Fishman", "Something that shouldn't exist... but does.", "Legendary", 6, 40.0, 75.0, "res://assets/fish/fishman.png")
]

static func roll_random_fish(selected_bait: String = "") -> Dictionary:
	var pool: Array[FishData] = []
	for fish in catalog:
		pool.append(fish)
		# If the player is using this fish's favorite bait, increase its spawn weight
		if selected_bait != "" and selected_bait in fish.preferred_baits:
			pool.append(fish)
			pool.append(fish)
	
	var chosen: FishData = pool.pick_random()
	var weight: float = snappedf(randf_range(chosen.min_weight, chosen.max_weight), 0.1)
	
	return {
		"name": chosen.name,
		"description": chosen.description,
		"rarity": chosen.rarity,
		"difficulty": chosen.difficulty,
		"weight": weight,
		"texture_path": chosen.texture_path,
		"model_path": chosen.model_path
	}
