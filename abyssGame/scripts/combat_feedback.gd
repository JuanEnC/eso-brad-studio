class_name CombatFeedback
extends Node2D

signal sound_played(kind: String, critical: bool)

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var priority_voice: AudioStreamPlayer
var effects: Array[Dictionary] = []
var screen_flash: float = 0.0
var screen_color := Color("75f6d0")
var clock: float = 0.0
var priority_until: float = 0.0
var priority_level: int = 0
var voice_index: int = 0
var font: Font = ThemeDB.fallback_font
const SOUND_VARIANTS := {
	"prepare": ["warning", 0.65, -23.0],
	"strike": ["hit", 0.74, -21.0],
	"armor": ["hit", 1.35, -20.0],
	"ricochet": ["hit", 1.85, -21.0],
	"critical_shot": ["shot", 0.72, -15.0],
	"laser_fire": ["warning", 0.48, -13.0],
	"shield_break": ["frequency_break", 1.18, -8.0],
	"boss_phase": ["frequency_break", 0.63, -8.0],
}
const SOUND_PRIORITY := {
	"parry_success": 80, "frequency_break": 100, "hurt": 60,
	"shield_break": 110, "boss_phase": 120,
}

func _ready() -> void:
	for sound in ["shot", "hit", "hurt", "parry_success", "warning", "dash", "frequency_break"]:
		streams[sound] = load("res://assets/audio/" + sound + ".wav")
	priority_voice = AudioStreamPlayer.new()
	priority_voice.name = "ResonanceVoice"
	priority_voice.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(priority_voice)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		voices.append(voice)

func _exit_tree() -> void:
	priority_voice.stop()
	priority_voice.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null

func _physics_process(delta: float) -> void:
	clock += delta
	screen_flash = maxf(0.0, screen_flash - delta * 3.0)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= delta
		if effects[i].life <= 0:
			effects.remove_at(i)
	queue_redraw()

func burst(where: Vector2, color: Color, radius: float = 50.0, text: String = "") -> void:
	effects.append({"position": where, "color": color, "radius": radius, "life": 0.5, "text": text})
	queue_redraw()

func trigger(kind: String, where: Vector2) -> void:
	match kind:
		"parry_success":
			burst(where, Color("75f6d0"), 105.0, "RESONANCIA")
			screen_color = Color("75f6d0")
			screen_flash = 0.28
		"frequency_break":
			for effect in effects:
				if effect.text == "RESONANCIA":
					effect.text = ""
			burst(where, Color("a7faff"), 125.0, "RUPTURA · DAÑO x2")
			screen_color = Color("a7faff")
			screen_flash = 0.4
		"hurt":
			burst(where, Color("ff728b"), 38.0, "IMPACTO")
			screen_color = Color("ff728b")
			screen_flash = 0.25
		"dash": burst(where, Color("70b8ff"), 38.0)
		"hit": burst(where, Color("ffba69"), 16.0)
		"armor": burst(where, Color("b4a0ca"), 22.0)
		"ricochet": burst(where, Color("ffbf82"), 18.0)
		"strike": burst(where, Color("ff728b"), 62.0)
		"destroyed": burst(where, Color("ffba69"), 45.0)
		"shield_break": burst(where, Color("b7e7ff"), 98.0, "ESCUDO ROTO")
		"boss_phase":
			burst(where, Color("ff768e"), 135.0, "FASE II")
			screen_color = Color("ff768e")
			screen_flash = 0.45
	play_sound(kind)

func play_sound(kind: String) -> void:
	var cue: Array = SOUND_VARIANTS.get(kind, [kind, 1.0, -19.0 if kind == "shot" else -14.0])
	var stream: AudioStream = streams.get(cue[0])
	if stream == null:
		return
	var level: int = SOUND_PRIORITY.get(kind, 0)
	if level > 0:
		if clock < priority_until and level < priority_level:
			return
		priority_level = level
		priority_until = clock + stream.get_length() / float(cue[1])
		priority_voice.stream = stream
		priority_voice.pitch_scale = cue[1]
		priority_voice.volume_db = -8.0
		priority_voice.play()
		for voice in voices:
			voice.volume_db = minf(voice.volume_db, -26.0)
		sound_played.emit(kind, true)
		return
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = stream
	voice.pitch_scale = cue[1]
	voice.volume_db = -26.0 if clock < priority_until else cue[2]
	voice.play()
	sound_played.emit(kind, false)

func _draw() -> void:
	for effect in effects:
		var t := 1.0 - float(effect.life) / 0.5
		var color: Color = effect.color
		color.a = 1.0 - t
		var radius: float = effect.radius * t
		draw_arc(effect.position, maxf(1.0, radius), 0, TAU, 48, color, 2, true)
		for i in range(12):
			var direction := Vector2.from_angle(i * TAU / 12.0)
			draw_line(effect.position + direction * radius * 0.65, effect.position + direction * (radius + 5), color, 2, true)
		if not effect.text.is_empty():
			draw_string(font, effect.position + Vector2(-85, -76 - 20 * t), effect.text, HORIZONTAL_ALIGNMENT_CENTER, 170, 14, color)
