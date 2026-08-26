extends Node2D
class_name Card

signal card_played(card_id)
signal card_discarded(card_id)
signal card_activated(card_id)

var in_field: bool = false
var card_id: int
var slot_index: int = -1
var owner_index: int = -1
var original_position: Vector2
var dragging := false
var face_down: bool = false          
@export var back_texture: Texture2D 
@onready var card_image: Sprite2D = $CardImage
@onready var area: Area2D = $Area2D
var original_scale: Vector2
var original_z: int
var preview: Node2D = null

func _ready() -> void:
	area.input_event.connect(_on_area_input)

func _input(event: InputEvent) -> void:
	if not in_field:
		return
	# Garante que só o jogador do turno dono da carta possa interagir no campo
	if GameManager.network_mode:
		var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id())
		if owner_index != local_index or not GameManager.is_my_turn():
			return
	else:
		if owner_index != GameManager.current_index:
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var half = Vector2(120.0, 160.0) / 2.0
		var rect = Rect2(global_position - half, Vector2(120.0, 160.0))
		if rect.has_point(get_global_mouse_position()):
			_show_field_menu()
			get_viewport().set_input_as_handled()

func _on_area_input(_viewport, event, _shape_idx) -> void:
	if in_field:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if face_down:
				return
			# Impede de arrastar a mão se não for seu turno
			if GameManager.network_mode and not GameManager.is_my_turn():
				return
			dragging = true
			original_position = global_position
			z_index = 100
		else:
			dragging = false
			z_index = 0
			if not face_down:
				_check_drop()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_show_details()
		else:
			_hide_details()

func _show_field_menu() -> void:
	var existing = get_node_or_null("/root/FieldMenu")
	if existing:
		existing.queue_free()
	var menu = PopupMenu.new()
	menu.name = "FieldMenu"
	var activate_cost = CardDatabase.get_card(card_id).get("activate_cost", 0)
	var server = GameManager.servers[owner_index]
	var can_afford = server.can_afford(activate_cost)
	menu.add_item("Ativar poder (%d PP)" % activate_cost, 0)
	menu.set_item_disabled(0, not can_afford)
	menu.add_item("Descartar", 1)
	get_tree().root.add_child(menu)
	var screen_pos = get_viewport().get_canvas_transform() * global_position
	menu.position = Vector2i(screen_pos)
	menu.popup()
	menu.id_pressed.connect(func(id):
		if id == 0:
			GameManager.activate_card(slot_index)
		else:
			GameManager.discard_card(slot_index)
		menu.queue_free()
	)
	menu.popup_hide.connect(func():
		if is_instance_valid(menu):
			menu.queue_free()
	)

func _show_details() -> void:
	if face_down:
		return
	preview = duplicate()
	get_tree().root.add_child(preview)
	preview.scale = Vector2(3, 3)
	preview.global_position = get_viewport().get_visible_rect().size / 2
	preview.z_index = 200

func _hide_details() -> void:
	if preview:
		preview.queue_free()
		preview = null

func _process(_delta: float) -> void:
	if dragging and not in_field and not face_down:
		global_position = get_global_mouse_position()

func flip(_face_down: bool) -> void:
	face_down = _face_down
	if face_down:
		card_image.texture = back_texture
	else:
		var data = CardDatabase.get_card(card_id)
		if data.get("sprite", "") != "":
			card_image.texture = load(data["sprite"])
			card_image.scale = Vector2(
				120.0 / card_image.texture.get_size().x,
				160.0 / card_image.texture.get_size().y
			)

func setup(_card_id: int, _face_down: bool = false) -> void:
	card_id = _card_id
	face_down = _face_down
	if face_down:
		card_image.texture = back_texture
		return
	var data = CardDatabase.get_card(card_id)
	if data.get("sprite", "") != "":
		card_image.texture = load(data["sprite"])
		card_image.scale = Vector2(
			120.0 / card_image.texture.get_size().x,
			160.0 / card_image.texture.get_size().y
		)
		
func _on_activated() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	
func _check_drop() -> void:
	var overlapping = area.get_overlapping_areas()
	for other_area in overlapping:
		if other_area.is_in_group("play_area"):
			var field = other_area.get_parent()
			
			# Em rede: só pode jogar no seu próprio turno
			if GameManager.network_mode and not GameManager.is_my_turn():
				global_position = original_position
				return
				
			# Só pode jogar no seu próprio campo
			var local_index = GameManager.peer_ids.find(multiplayer.get_unique_id()) if GameManager.network_mode else GameManager.current_index
			if field.owner_id != local_index:
				global_position = original_position
				return
				
			var slot_idx = field.slots.find(other_area)
			if slot_idx == -1 or not field.is_slot_free(other_area):
				global_position = original_position
				return
				
			var cost = CardDatabase.get_card(card_id).get("cost", 0)
			if not GameManager.servers[local_index].can_afford(cost):
				global_position = original_position
				return
				
			# Envia requisição para jogar e retorna visualmente para a mão
			# (será reposicionado quando o servidor autorizar e emitir o sinal correspondente)
			GameManager.play_card(card_id, slot_idx)
			global_position = original_position
			dragging = false
			return
	global_position = original_position

func get_sprite_size() -> Vector2:
	if card_image.texture:
		return card_image.texture.get_size() * card_image.scale
	return Vector2(100.0, 140.0)
