extends Node2D

const TileObj = preload("res://Tile.tscn")
const SHUFFLE_CNT = 30 # シャッフル回数.

enum eState {
	MAIN,
	WAIT, # 正解待ち.
	COMPLETED, # 正解.
}

onready var _btn_retry = $ButtonRetry
onready var _checkbox4x4 = $RadioButtonMode/CheckBox4x4
onready var _completed_spr = $CompletedSpr
onready var _checkbox_number = $CheckBoxNumber
onready var _answer = $Answer
onready var _checkbox002 = $RadioButtonImage/CheckBox002
onready var _checkbox003 = $RadioButtonImage/CheckBox003

var _state = eState.MAIN
var _tiles = []
var _arr:Common.Array2D
var _next_mode = Common.eMode.NONE # ゲームモードを変更したときはここに値を入れておく.
var _next_image_number = 0 # 画像を変更したときの番号.

## 開始.
func _ready() -> void:
	# 番号を表示するかどうか.
	_checkbox_number.pressed = Common.is_display_number()
	
	match Common.get_mode():
		Common.eMode.TILE_3x3:
			pass
		Common.eMode.TILE_4x4:
			_checkbox4x4.pressed = true
	
	_arr = Common.Array2D.new(Common.width(), Common.height())
	
	match Common.get_image_number():
		1:
			pass
		2:
			_checkbox002.pressed = true
		3:
			_checkbox003.pressed = true	
	# 画像の更新.
	_answer.texture = Common.get_image()
	_completed_spr.texture = Common.get_image()
	
	# タイルをランダムに配置する.
	randomize()
	var tmp = _create_random()
	
	var idx = 0
	for j in range(tmp.height):
		for i in range(tmp.width):
			var v = tmp.get_v(i, j)
			if v == _arr.width * _arr.height:
				continue # 最後のパネルを除外する.
		
			_arr.set_v(i, j, v)
			var tile = TileObj.instance()
			add_child(tile)
			tile.setup(i, j, v)
			_tiles.append(tile)
		
			idx += 1

## 更新.
func _process(delta: float) -> void:
	match _state:
		eState.MAIN:
			_update_main(delta)
		eState.WAIT:
			_update_wait(delta)
		eState.COMPLETED:
			_update_completed(delta)

## 更新 > メイン.
func _update_main(_delta:float) -> void:
	# 番号を表示するかどうか.
	Common.set_display_number(_checkbox_number.pressed)
	
	var mouse = get_viewport().get_mouse_position()
	var i = Common.to_grid_x(mouse.x)
	var j = Common.to_grid_y(mouse.y)
	var tile = _get_tile_from_grid(i, j)
	if tile != null:
		tile.set_blink(true)
		if Input.is_action_just_pressed("ui_click"):
			# スライドを実行する.
			_panel_slide(i, j)
	
	if _check_completed(_arr):
		# 完了.
		#_btn_retry.disabled = true # 押せなくする.
		_state = eState.WAIT

## 更新 > 完了待ち.
func _update_wait(_delta:float) -> void:
	for tile in _tiles:
		if tile.is_moving():
			return # 移動中.
		
	_completed_spr.visible = true
	_completed_spr.modulate.a = 0
	_state = eState.COMPLETED
	
## 更新 > 完了.
func _update_completed(_delta:float) -> void:
	_completed_spr.modulate.a += _delta
	if _completed_spr.modulate.a > 1.0:
		_completed_spr.modulate.a = 1.0

## グリッド座標系からタイルを探す.
func _get_tile_from_grid(i:int, j:int) -> Tile:
	var n = _arr.get_v(i, j)
	return _get_tile_from_number(n)

## 指定の番号からタイルを探す.
func _get_tile_from_number(n:int) -> Tile:
	for tile in _tiles:
		if n == tile.get_number():
			return tile
	
	return null

## パネルをスライドする.
func _panel_slide(i:int, j:int) -> void:

	# 上下左右の方向を調べる.
	for v in [[-1, 0], [0, -1], [1, 0], [0, 1]]:
		var dx = v[0]
		var dy = v[1]
		
		var idx_list = [] # 移動可能パネルのリスト (インデックス座標系)
		# 開始パネルをリストに追加.
		idx_list.append(Common.grid_to_idx(i, j))
		
		# 移動可能かどうかチェックする.
		if _panel_slide_sub(idx_list, i, j, dx, dy):
			# 移動可能.
			idx_list.invert() # 後ろから動かしたいので逆順にする.
			#print(idx_list)
			for idx in idx_list:
				var i2 = Common.idx_to_grid_x(idx)
				var j2 = Common.idx_to_grid_y(idx)
				var tile = _get_tile_from_grid(i2, j2)
				var i2next = i2 + dx
				var j2next = j2 + dy
				tile.move_to(i2next, j2next)
				_arr.set_v(i2next, j2next, tile.get_number())
			# 開始地点を空にしておく.
			_arr.set_v(i, j, Common.Array2D.EMPTY)

## PoolIntArrayにすると実体のコピー渡しになるのであえてArrayで渡す.
## @param idx_list 移動可能なパネルの位置を表すリスト
## @param i 基準座標(X)
## @param j 基準座標(Y)
## @param dx 移動方向(X)
## @param dy 移動方向(Y)
func _panel_slide_sub(idx_list:Array, i:int, j:int, dx:int, dy:int) -> bool:
	var inext = i + dx
	var jnext = j + dy
	var n = _arr.get_v(inext, jnext)
	if n == Common.Array2D.OUT_OF_RANGE:
		return false # フィールド外なので終了.
	
	if n == Common.Array2D.EMPTY:
		return true # 移動可能.
	
	# リストに追加.
	idx_list.append(Common.grid_to_idx(inext, jnext))
	
	# 次を調べる.
	return _panel_slide_sub(idx_list, inext, jnext, dx, dy)

## 正解判定.
func _check_completed(arr:Common.Array2D) -> bool:
	var idx = 1
	for j in range(arr.height):
		for i in range(arr.width):
			var n = arr.get_v(i, j)
			if n == Common.Array2D.EMPTY:
				idx += 1
				continue # 空欄は除外.
			if n != idx:
				return false # 一致していない.
			idx += 1
			
	return true # 正解.

## 完全なランダムだと解法がなくなる可能性があるので答えからランダムで動かします.
func _create_random() -> Common.Array2D:
	var tmp = Common.Array2D.new(Common.width(), Common.height())
	
	# 完成の状態を作る
	var num = 1 # 1始まり.
	for j in range(tmp.height):
		for i in range(tmp.width):
			tmp.set_v(i, j, num)
			num += 1
	
	# 空とする番号.
	var empty = Common.width() * Common.height()
	
	while true:
		# ここからシャッフル処理.
		var cnt = SHUFFLE_CNT
		if Common.get_mode() == Common.eMode.TILE_4x4:
			cnt *= 5 # 4x4のときはシャッフル回数を増やします
		for i in range(cnt):
			var idx = tmp.search(empty) # 空のパネルを探す.
			var tbl = [[-1, 0], [0, -1], [1, 0], [0, 1]] # 上下左右を調べる.
			tbl.shuffle() # シャッフルする.
			for v in tbl:
				var i1 = Common.idx_to_grid_x(idx)
				var j1 = Common.idx_to_grid_y(idx)
				var dx = v[0]
				var dy = v[1]
				var i2 = i1 + dx
				var j2 = j1 + dy
				if tmp.swap(i1, j1, i2, j2):
					break # 交換成功.
		
		# 完成しているかどうか.
		var is_completed = _check_completed(tmp)		
		if is_completed == false:
			break # 完成していないのでOK
	return tmp

	
# -------------------------------------------------------
# signal.
# -------------------------------------------------------
## やり直しボタン.
func _on_ButtonRetry_pressed() -> void:
	if _next_mode != Common.eMode.NONE:
		# モードの切り替えがあった.
		Common.set_mode(_next_mode)
	if _next_image_number != 0:
		# 画像の切り替えがあった.
		Common.set_image_number(_next_image_number)
	get_tree().change_scene("res://Main.tscn")

## フィールドサイズ変更.
func _on_CheckBox3x3_toggled(button_pressed: bool) -> void:
	if button_pressed:
		# 3x3 モードにする.
		_next_mode = Common.eMode.TILE_3x3


func _on_CheckBox4x4_toggled(button_pressed: bool) -> void:
	if button_pressed:
		# 4x4 モードにする.
		_next_mode = Common.eMode.TILE_4x4

## 画像切替.
func _on_CheckBox001_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_next_image_number = 1

func _on_CheckBox002_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_next_image_number = 2

func _on_CheckBox003_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_next_image_number = 3
