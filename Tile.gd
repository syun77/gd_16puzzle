extends Area2D

class_name Tile

const MOVE_SPEED = 10.0

onready var _spr = $Sprite
onready var _frame = $Frame
onready var _label = $Label

# 数値
var _number = 0
# 位置.
var _x:float= 0
var _y:float = 0
var _xnext:float = 0
var _ynext:float = 0
# 点滅.
var _is_blink = false
var _timer = 0.0

## セットアップ.
func setup(i:int, j:int, num:int) -> void:
	#print(num, " i:", i, " j:", j)
	
	# 画像変更.
	_spr.texture = Common.get_image()
	
	# スプライトフレーム数変更.
	_spr.hframes = Common.width()
	_spr.vframes = Common.height()
	
	set_number(num)
	set_grid_pos(i, j)
	
	# 開始時は非表示にしておく.
	_spr.visible = false
	
	# 番号を表示するかどうか.
	_label.visible = Common.is_display_number()
	
	# フレームをリサイズする.
	var sc = 4.0 / Common.width()
	_frame.scale = Vector2(sc, sc)
	
## 移動中かどうか.
func is_moving() -> bool:
	var dx = _xnext - _x
	var dy = _ynext - _y
	return dx + dy > 1.0

## 数値を設定.
func set_number(num:int) -> void:
	_number = num
	_spr.frame = num - 1 # 0始まりに戻す.
	_label.text = str(num)

## 数値を取得する.
func get_number() -> int:
	return _number

## 指定の位置にワープする.
func set_grid_pos(i:int, j:int) -> void:
	_x = i
	_y = j
	move_to(i, j)
	
	# 開始位置を少しずらす.
	_x += rand_range(-1, 1)
	_y += rand_range(-1, 1)

## 指定の位置に移動する.
func move_to(i:int, j:int) -> void:
	_xnext = i
	_ynext = j
	
func set_blink(b:bool) -> void:
	_is_blink = true

## 更新.
func _process(delta: float) -> void:
	_timer += delta
	
	# 番号を表示するかどうか.
	_label.visible = Common.is_display_number()
	
	_spr.visible = true
	
	_x += (_xnext - _x) * delta * MOVE_SPEED
	_y += (_ynext - _y) * delta * MOVE_SPEED
	position.x = Common.to_world_x(_x, true)
	position.y = Common.to_world_y(_y, true)
	
	# 点滅.
	_frame.modulate = Color.gray
	if _is_blink:
		_is_blink = false
		var rate = abs(sin(_timer * 4))
		_frame.modulate = Color.red.linear_interpolate(Color.yellow, rate)
