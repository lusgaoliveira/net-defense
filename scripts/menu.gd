extends Control

const HELP_GUIDE = preload("res://scenes/help_guide.tscn")
const CARD_VIEWER = preload("res://scenes/card_viewer.tscn")

func _on_search_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_match.tscn")


func _on_view_cards_pressed() -> void:
	var viewer = CARD_VIEWER.instantiate()
	add_child(viewer)


func _on_help_pressed() -> void:
	var guide = HELP_GUIDE.instantiate()
	add_child(guide)


func _on_exiit_pressed() -> void:
	get_tree().quit()
