extends Control

@onready var cards_container: HBoxContainer = $Panel/VBox/ScrollContainer/CardsContainer
@onready var close_button: Button = $Panel/VBox/close_button

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	_populate_cards()


func _populate_cards() -> void:
	# Limpa qualquer nó filho existente
	for child in cards_container.get_children():
		child.queue_free()

	for card_id in CardDatabase.CARDS.keys():
		var card_data = CardDatabase.CARDS[card_id]
		var card_card = _create_card_widget(card_data)
		cards_container.add_child(card_card)


func _create_card_widget(data: Dictionary) -> Control:
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(240, 480)

	# Estilização visual do card
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.5, 0.9, 0.6)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	card_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_panel.add_child(vbox)

	# Imagem / Sprite da carta
	var sprite_path = data.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var texture_rect = TextureRect.new()
		texture_rect.texture = load(sprite_path)
		texture_rect.custom_minimum_size = Vector2(160, 200)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(texture_rect)

	# Nome da carta
	var name_label = Label.new()
	name_label.text = data.get("name", "Sem Nome")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4)) # Amarelo/Dourado
	vbox.add_child(name_label)

	# Linha de Custos (Invocar PP / Ativar PP)
	var costs_hbox = HBoxContainer.new()
	costs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	costs_hbox.add_theme_constant_override("separation", 12)

	var cost_label = Label.new()
	cost_label.text = "⚡ Invocar: %d PP" % data.get("cost", 0)
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5)) # Verde

	var activate_label = Label.new()
	activate_label.text = "🔥 Ativar: %d PP" % data.get("activate_cost", 0)
	activate_label.add_theme_font_size_override("font_size", 13)
	activate_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0)) # Azul

	costs_hbox.add_child(cost_label)
	costs_hbox.add_child(activate_label)
	vbox.add_child(costs_hbox)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Descrição
	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	return card_panel


func _on_close() -> void:
	queue_free()
