extends Area2D
class_name BombItem

@export var item_type: Item.TYPE = Item.TYPE.BOMB


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: PlayerEntity) -> void:
	if body.is_in_group("player"):
		body.add_bomb_to_inventory()
		queue_free()
