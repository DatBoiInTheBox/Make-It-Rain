extends Control

@onready var text1 = $BannerBG/BannerText1
@onready var text2 = $BannerBG/BannerText2
@onready var banner_bg = $BannerBG

var scroll_speed := 60.0 # pixels per second

func _ready():
	reset_scroll_positions()
	text1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text2.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _process(delta):
	text1.position.x += scroll_speed * delta
	text2.position.x += scroll_speed * delta

	# Reset a label if it's fully off to the right
	if text1.position.x > banner_bg.size.x:
		text1.position.x = text2.position.x - text1.size.x
	if text2.position.x > banner_bg.size.x:
		text2.position.x = text1.position.x - text2.size.x

func show_phase(phase: String) -> void:
	match phase:
		"stealth":
			set_banner("// STEALTH IN PROGRESS //", Color.CYAN)
		"control":
			set_banner("// //", Color.YELLOW)
		"anticipation":
			set_banner("// ASSAULT STARTING - BE READY //", Color.ORANGE)
		"assault":
			set_banner("// ASSAULT IN PROGRESS //", Color.RED)

func set_banner(text: String, color: Color) -> void:
	text1.text = text
	text2.text = text
	banner_bg.modulate = color
	reset_scroll_positions()

func reset_scroll_positions():
	text1.position.x = 0
	text2.position.x = -text2.size.x

func set_banner_text(new_text: String):
	if text1.text == new_text:
		return # avoid unnecessary updates

	text1.text = new_text
	text2.text = new_text

	# Do NOT reset scroll positions
	# Keeps scrolling smooth
