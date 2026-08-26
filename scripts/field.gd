extends Node2D

const SLOT_WIDTH = 120.0
const SLOT_HEIGHT = 160.0
const SPACING = 20.0

var owner_id: int = 0
var slots: Array[Area2D] = []
var occupied: Dictionary = {}

func _ready() -> void:
	_create_slots(4)

func _create_slots(count: int) -> void:
	var total_width = (SLOT_WIDTH + SPACING) * count
	var start_x = -total_width / 2.0
	for i in count:
		var slot = Area2D.new()
		slot.add_to_group("play_area")
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
		shape.shape = rect
		slot.add_child(shape)
		var outline = ColorRect.new()
		outline.size = Vector2(SLOT_WIDTH + 4.0, SLOT_HEIGHT + 4.0)
		outline.position = Vector2(-SLOT_WIDTH / 2.0 - 2.0, -SLOT_HEIGHT / 2.0 - 2.0)
		outline.color = Color(0, 0, 0, 1)
		slot.add_child(outline)
		var border = ColorRect.new()
		border.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
		border.position = Vector2(-SLOT_WIDTH / 2.0, -SLOT_HEIGHT / 2.0)
		border.color = Color(0.05, 0.1, 0.3, 0.9)
		slot.add_child(border)
		slot.position = Vector2(start_x + i * (SLOT_WIDTH + SPACING), 0)
		add_child(slot)
		slots.append(slot)

func is_slot_free(slot: Area2D) -> bool:
	return not occupied.get(slot, false)

func occupy_slot(slot: Area2D) -> void:
	occupied[slot] = true

func free_slot_by_index(index: int) -> void:
	if index >= 0 and index < slots.size():
		occupied[slots[index]] = false

func occupy_slot_by_index(index: int) -> void:
	if index >= 0 and index < slots.size():
		occupied[slots[index]] = true
