class_name TackleBox
extends RefCounted

class BaitData:
	var id: String
	var name: String
	var description: String
	var icon_path: String
	var bite_speed_multiplier: float
	var target_species: String

	func _init(i: String, n: String, desc: String, icon: String, speed_mult: float, species: String):
		id = i
		name = n
		description = desc
		icon_path = icon
		bite_speed_multiplier = speed_mult
		target_species = species

static var available_baits: Array[BaitData] = [
	BaitData.new("worms", "Worms", "Classic wriggling earthworms. Good all-around bait, especially for Bass and Sunfish.", "res://assets/bait/worms.png", 1.0, "Bass, Sunfish"),
	BaitData.new("corn", "Sweet Corn", "Bright sweet corn kernels. High attraction for Golden Carp and Trout.", "res://assets/bait/corn.png", 1.1, "Golden Carp, Trout"),
	BaitData.new("minnows", "Minnows", "Live silvery minnows. Irresistible to aggressive predators like Bass and Trout.", "res://assets/bait/minnows.png", 1.25, "Bass, Trout"),
	BaitData.new("cheese", "Stinky Cheese", "Pungent aged cheese cubes. Bottom-feeders like Catfish can smell it from afar.", "res://assets/bait/cheese.png", 1.15, "Catfish, Golden Carp"),
	BaitData.new("rotten_meat", "Rotten Offal", "Necrotic meat pulled from the tide. Attracts the unmentionable.", "res://assets/bait/rotten_meat.png", 1.8, "Catfish"),
]

static func get_bait_by_id(bait_id: String) -> BaitData:
	for b in available_baits:
		if b.id == bait_id or b.name == bait_id:
			return b
	return available_baits[0]
