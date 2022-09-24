extends Item
class_name Equipment

enum Slot {
	WEAPON,
	HEAD,
	BODY,
	LEGS,
	RING,
	SIZE
}

enum Subtype {
	MELEE,
	RANGED,
	MAGIC,
	LIGHT_ARMOR,
	HEAVY_ARMOR,
	ACCESSORY
}

export(Slot)	var slot
export(Subtype) var subtype

# Format:
# "base:STAT_NAME" : float -> base value
# "mult:STAT_NAME" : float -> multiplier (+/-)

export(Dictionary) var stats
export(String) var passive_ability
