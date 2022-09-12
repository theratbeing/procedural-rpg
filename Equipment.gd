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
