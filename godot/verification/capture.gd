extends SceneTree
## 最終状態の実描画とキャラクター一覧を保存する。
func _init() -> void:
    call_deferred("run")
func snap(path: String) -> void:
    for i in range(12): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(path)
func run() -> void:
    var game: Node2D = load("res://Main.tscn").instantiate()
    root.add_child(game)
    await snap("C:/Users/user/OneDrive/Desktop/KGtool/output/lelics/stage1.png")
    game._stage_two()
    game.host=game.actors[6]
    await snap("C:/Users/user/OneDrive/Desktop/KGtool/output/lelics/stage2.png")
    game.set_physics_process(false)
    game.host=game.actors[0]
    var xs := [45.0,112.0,183.0,262.0,335.0,395.0,450.0,505.0,585.0]
    for i in range(game.actors.size()):
        game.actors[i].x=xs[i]
        game.actors[i].y=312.0
        game.visuals[i].previous=Vector2(xs[i],312)
        game.visuals[i].phase=i*0.7
        game.visuals[i].speed=95.0 if i<4 else 0.0
        game.visuals[i].state="walk" if i<4 else "idle"
    await snap("C:/Users/user/OneDrive/Desktop/KGtool/output/lelics/characters.png")
    print("LELICS_RENDER_PASS")
    quit()
