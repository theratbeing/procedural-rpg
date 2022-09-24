extends Resource
class_name Item

enum Type {
	BASIC,
	CONSUMABLE,
	EQUIPMENT,
}

export(String) var name		= "Item"
export(Type)   var type		= Type.BASIC
export(bool)   var can_sell = true
export(int)    var price	= 1

export(Texture) var icon
