extends Resource
class_name Item

enum Type {
	BASIC,
	CONSUMABLE,
	EQUIP,
}

export(String) var name		= "Item"
export(int)    var price	= 1
export(Type)   var type		= Type.BASIC
export(bool)   var can_sell = true
