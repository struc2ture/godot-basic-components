extends Node

@onready var PLAYER: Player = get_parent()

func _ready():
	assert(PLAYER)
	
	PLAYER.player_stepped.connect(_on_player_stepped)
	PLAYER.player_jumped.connect(_on_player_jumped)
	PLAYER.player_landed.connect(_on_player_landed)
	PLAYER.player_body_entered_water.connect(_on_player_body_entered_water)
	PLAYER.player_body_left_water.connect(_on_player_body_left_water)
	
func _on_player_stepped():
	$Step.play()


func _on_player_jumped():
	$Jump.play()


func _on_player_landed():
	$Land.play()


func _on_player_body_entered_water():
	$WaterSplash.play()


func _on_player_body_left_water():
	$WaterLeave.play()
