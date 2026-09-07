extends SceneTree
## 同じ入力を使い、歩行・停止・旋回・跳躍を録画する。
var game: Node2D
var tick := 0
func _init() -> void:
    call_deferred("start")
func start() -> void:
    game = load("res://Main.tscn").instantiate()
    root.add_child(game)
    game.input_override={"test":true}
func _physics_process(_dt: float) -> bool:
    if not is_instance_valid(game): return false
    tick += 1
    game.input_override={"move_right":tick>=30 and tick<180,"move_left":tick>=240 and tick<315,"jump":tick==345}
    if tick==480:
        print("LELICS_MOVIE_PASS")
        quit()
    return false
