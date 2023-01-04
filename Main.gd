extends Node2D

const OFS_X = 32.0
const OFS_Y = 32.0
const TILE_SIZE = 64.0
const FIELD_WIDTH = 4
const FIELD_HEIGHT = 4

class Array2D:
	var _pool = []
	func _init(w:int, h:int):
		for i in range(w):
			for j in range(h):
				_pool.append(0)
		
	func get_v(i:int, j:int) -> int:
		var idx = i + (j * FIELD_WIDTH)
		return _pool[idx]
	func set_v(i:int, j:int, v:int) -> void:
		var idx = i + (j * FIELD_WIDTH)
		_pool[idx] = v

var _arr:Array2D = Array2D.new(FIELD_WIDTH, FIELD_HEIGHT)
var _font = null
var _mouse = Vector2.ZERO

func _ready() -> void:
	_font = Control.new().get_font("default")
	
	var l = []
	for i in range(16):
		l.append(i)
	l.shuffle()
	
	var idx = 0
	for v in l:
		var i = idx%FIELD_WIDTH
		var j = idx/FIELD_HEIGHT
		_arr.set_v(i, j, v)
		idx += 1

func _process(delta: float) -> void:
	_mouse = get_viewport().get_mouse_position()
	
	update()
	

func to_world_x(i:float) -> float:
	return OFS_X + (TILE_SIZE * i)
func to_world_y(j:float) -> float:
	return OFS_Y + (TILE_SIZE * j)
func to_idx_x(x:float) -> float:
	var i = int((x - OFS_X) / TILE_SIZE)
	return i
func to_idx_y(y:float) -> float:
	var j = int((y - OFS_Y) / TILE_SIZE)
	return j

func _draw() -> void:
	var mx = to_idx_x(_mouse.x)
	var my = to_idx_y(_mouse.y)
	
	# タイルの描画.
	for j in range(FIELD_HEIGHT):
		for i in range(FIELD_WIDTH):
			var v = _arr.get_v(i, j)
			if v == 0:
				continue
			var x = to_world_x(i)
			var y = to_world_y(j)
			var pos = Vector2(x, y) + Vector2(32, 32)
			var rect = Rect2(x, y, TILE_SIZE, TILE_SIZE)
			var color = Color.gainsboro
			if i == mx and j == my:
				color = Color.yellow
			draw_rect(rect, color)
			draw_string(_font, pos, str(v), Color.black)
	# グリッドの描画.
	_draw_grid()
	
func _draw_grid() -> void:
	var ofs = Vector2(OFS_X, OFS_Y)
	var w = FIELD_WIDTH
	var h = FIELD_HEIGHT
	var size = TILE_SIZE
	for i in range(w + 1):
		var y = h * size
		var v1 = Vector2(i * size, 0) + ofs
		var v2 = Vector2(i * size, y) + ofs
		draw_line(v1, v2, Color.white, 1)
	for j in range(h + 1):
		var x = w * size
		var v1 = Vector2(0, j * size) + ofs
		var v2 = Vector2(x, j * size) + ofs
		draw_line(v1, v2, Color.white, 1)
