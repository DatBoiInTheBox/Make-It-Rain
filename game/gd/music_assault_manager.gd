extends Node

enum MusicState { STEALTH, CONTROL, ANTICIPATION, ASSAULT }

@export var use_stealth2 := false
@export var use_assault2 := false

var state: MusicState = MusicState.STEALTH

@onready var stealth1 = $AudioPlayer_Stealth1
@onready var stealth2 = $AudioPlayer_Stealth2
@onready var control = $AudioPlayer_Control
@onready var anticipation = $AudioPlayer_Anticipation
@onready var assault1 = $AudioPlayer_Assault1
@onready var assault2 = $AudioPlayer_Assault2

@onready var phase_ui = $CanvasLayer/PhaseBanner

func _ready():
	play_stealth()

func _process(_delta):
	if Input.is_action_just_pressed("debug_restart"):
		print("DEBUG: Restart to stealth")
		restart_to_stealth()
	elif Input.is_action_just_pressed("debug_fail_stealth"):
		print("DEBUG: Trigger fail stealth → control")
		to_control()
	elif Input.is_action_just_pressed("debug_end_track_early"):
		print("DEBUG: Jump to 5 seconds before end")
		jump_to_end()

func play_stealth() -> void:
	stop_all()
	state = MusicState.STEALTH
	print("DEBUG: Playing STEALTH 1")
	phase_ui.show_phase("stealth")
	stealth1.play()
	if use_stealth2:
		_play_stealth_sequence()

func _play_stealth_sequence() -> void:
	await stealth1.finished
	print("DEBUG: STEALTH 1 finished, switching to STEALTH 2")
	stealth2.play()

func to_control() -> void:
	stop_all()
	print("DEBUG: Switching from %s to CONTROL" % [state])
	state = MusicState.CONTROL
	control.play()

	# Start a countdown timer for 30 seconds
	var control_duration := 30.0
	var start_time := Time.get_ticks_msec() / 1000.0

	# Show the UI immediately
	phase_ui.show_phase("control")

	# Run the timer with live UI updates
	while (Time.get_ticks_msec() / 1000.0) - start_time < control_duration:
		var remaining = int(control_duration - ((Time.get_ticks_msec() / 1000.0) - start_time))
		phase_ui.set_banner_text("// CONTROL – RESPONDERS COMING – %02d:%02d //" % [remaining / 60, remaining % 60])
		await get_tree().create_timer(1.0).timeout

	to_anticipation()

func to_anticipation() -> void:
	stop_all()
	print("DEBUG: Switching from CONTROL to ANTICIPATION (45s)")
	state = MusicState.ANTICIPATION
	phase_ui.show_phase("anticipation")
	anticipation.play()
	await get_tree().create_timer(45.0).timeout
	to_assault()

func to_assault() -> void:
	stop_all()
	print("DEBUG: Switching from ANTICIPATION to ASSAULT")
	state = MusicState.ASSAULT
	phase_ui.show_phase("assault")
	if use_assault2:
		print("DEBUG: ASSAULT 1 + 2 sequence starting")
		_play_assault_sequence()
	else:
		var s = assault1.stream
		if s and s is AudioStream:
			s.loop = true
		print("DEBUG: Playing ASSAULT 1 in loop mode")
		assault1.play()

func _play_assault_sequence() -> void:
	if assault1.stream:
		assault1.stream.loop = false
	print("DEBUG: Playing ASSAULT 1 (non-looping)")
	assault1.play()
	await assault1.finished
	if assault2.stream:
		assault2.stream.loop = false
	print("DEBUG: ASSAULT 1 finished, switching to ASSAULT 2")
	assault2.play()
	await assault2.finished
	print("DEBUG: ASSAULT 2 finished, restarting assault sequence")
	to_assault()

func end_assault() -> void:
	stop_all()
	print("DEBUG: Ending ASSAULT, returning to CONTROL")
	to_control()

func restart_to_stealth() -> void:
	stop_all()
	print("DEBUG: Restarting music cycle from STEALTH")
	play_stealth()

func jump_to_end() -> void:
	var current_player = get_current_player()
	if current_player and current_player.stream:
		var end_time = current_player.stream.get_length() - 5.0
		print("DEBUG: Jumping current track to %.2f seconds (5s before end)" % end_time)
		current_player.play(end_time)

func get_current_player() -> AudioStreamPlayer:
	match state:
		MusicState.STEALTH:
			return stealth2 if (use_stealth2 and not stealth1.playing) else stealth1
		MusicState.CONTROL:
			return control
		MusicState.ANTICIPATION:
			return anticipation
		MusicState.ASSAULT:
			if use_assault2 and not assault1.playing:
				return assault2
			return assault1
	return null

func stop_all() -> void:
	for player in get_children():
		if player is AudioStreamPlayer:
			player.stop()
