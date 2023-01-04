extends Node

# 左上のオフセット
const OFS_X = 32.0
const OFS_Y = 32.0

enum eMode {
	NONE,
	TILE_3x3,
	TILE_4x4,
}

var _mode = eMode.TILE_3x3
var _is_display_number = false
var _image_number = 1

## モードを設定.
func set_mode(mode:int) -> void:
	_mode = mode
func get_mode() -> int:
	return _mode
	
## 数字表示切り替え.
func set_display_number(b:bool) -> void:
	_is_display_number = b
func is_display_number() -> bool:
	return _is_display_number
	
## 画像番号を設定.
func set_image_number(n:int) -> void:
	_image_number = n
func get_image_number() -> int:
	return _image_number
func get_image_path() -> String:
	return "res://assets/puzzle/puzzle%03d.png"%_image_number
func get_image():
	return load(get_image_path())

func width() -> int:
	match _mode:
		eMode.TILE_3x3:
			return 3
		_: #eMode.TILE_4x4:
			return 4

func height() -> int:
	match _mode:
		eMode.TILE_3x3:
			return 3
		_: #eMode.TILE_4x4:
			return 4

func tile_size() -> float:
	return 512.0 / width()

## 2次元配列のユーティリティ.
class Array2D:
	const EMPTY = 0 # 0を空とする.
	const OUT_OF_RANGE = -1 # -1を領域外とする.
	var width = 0
	var height = 0
	var _pool = []
	
	## コンストラクタ.
	func _init(w:int, h:int):
		create(w, h)
	
	## 生成.
	func create(w:int, h:int) -> void:
		_pool = []
		for i in range(w):
			for j in range(h):
				_pool.append(EMPTY)
		width = w
		height = h
	
	## コピー
	func copy(src:Array2D) -> void:
		create(src.w, src.h)
		for i in range(src.w):
			for j in range(src.h):
				var v = src.get_v(i, j)
				set_v(i, j, v)
	
	## 値をクリア.
	func clear() -> void:
		_pool.clear()
		
	func get_v(i:int, j:int) -> int:
		if i < 0 or i >= width:
			return OUT_OF_RANGE
		if j < 0 or j >= height:
			return OUT_OF_RANGE
		var idx = i + (j * width)
		return _pool[idx]
	func set_v(i:int, j:int, v:int) -> void:
		if i < 0 or i >= width:
			return
		if j < 0 or j >= height:
			return
		var idx = i + (j * width)
		set_from_idx(idx, v)
	
	func set_from_idx(idx:int, v:int) -> void:
		_pool[idx] = v
	
	## 値を入れ替える.
	func swap(i1:int, j1:int, i2:int, j2:int) -> void:
		var n1 = get_v(i1, j1)
		var n2 = get_v(i2, j2)
		if n1 == OUT_OF_RANGE or n2 == OUT_OF_RANGE:
			var buf = "(i1,j1):(%d,%d)=%d (i2,j2):(%d,%d)=%d"%[i1, j1, n1, i2, j2, n2]
			push_error("領域外の位置を指定しました " + buf)
			return # 領域外の場合は何もしない.
		set_v(i1, j1, n2)
		set_v(i2, j2, n1)

## グリッド座標系をワールド座標系に変換する (X).
func to_world_x(i:float, is_center:bool=false) -> float:
	var wx = OFS_X + (tile_size() * i)
	if is_center:
		wx += tile_size() / 2.0
	return wx

## グリッド座標系をワールド座標系に変換する (Y).
func to_world_y(j:float, is_center:bool=false) -> float:
	var wy = OFS_Y + (tile_size() * j)
	if is_center:
		wy += tile_size() / 2.0
	return wy

## ワールド座標系をグリッド座標系に変換する (X).
func to_grid_x(x:float) -> float:
	var i = int((x - OFS_X) / tile_size())
	return i

## ワールド座標系をグリッド座標系に変換する (Y).
func to_grid_y(y:float) -> float:
	var j = int((y - OFS_Y) / tile_size())
	return j

## インデックス座標をグリッドX座標に変換する.
func idx_to_grid_x(idx:int) -> int:
	return idx % width()

## インデックス座標をグリッドY座標に変換する.
func idx_to_grid_y(idx:int) -> int:
	return idx / width()

## グリッド座標をインデックス座標に変換する.
func grid_to_idx(i:int, j:int) -> int:
	return (j * width()) + i
