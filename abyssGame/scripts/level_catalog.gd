extends RefCounted

# The approach and three combat rooms share the arena's 1280 x 800 coordinates.
const ROOMS := [
	{
		"name": "UMBRAL",
		"color": Color("0c1724"),
		"cover": [Rect2(570, 294, 44, 86), Rect2(570, 496, 44, 86)],
		"spawns": [],
	},
	{
		"name": "I · LABORATORIO",
		"color": Color("121824"),
		"speed_scale": 1.0,
		"cover": [Rect2(505, 225, 46, 128), Rect2(748, 447, 46, 128)],
		"spawns": [Vector2(797, 266), Vector2(956, 516)],
	},
	{
		"name": "II · GALERÍA",
		"color": Color("171724"),
		"speed_scale": 1.35,
		"attack_delay_scale": 0.86,
		"cover": [Rect2(445, 150, 50, 196), Rect2(445, 454, 50, 196), Rect2(749, 335, 52, 130)],
		"spawns": [Vector2(690, 238), Vector2(945, 545), Vector2(700, 575)],
		"laser_spawns": [Vector2(968, 400)],
	},
	{
		"name": "III · DESCENSO",
		"color": Color("1a1520"),
		"speed_scale": 1.62,
		"attack_delay_scale": 0.74,
		"cover": [Rect2(382, 260, 170, 42), Rect2(382, 498, 170, 42),
			Rect2(745, 132, 54, 178), Rect2(745, 490, 54, 178)],
		"spawns": [Vector2(633, 170), Vector2(943, 258), Vector2(961, 548), Vector2(625, 635)],
		"laser_spawns": [Vector2(936, 163), Vector2(971, 655)],
	},
	{
		"name": "NÚCLEO",
		"color": Color("201521"),
		"cover": [Rect2(407, 175, 56, 130), Rect2(407, 495, 56, 130),
			Rect2(827, 175, 56, 130), Rect2(827, 495, 56, 130)],
		"spawns": [Vector2(920, 400)],
		"boss": true,
	},
]
