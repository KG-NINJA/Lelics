extends SceneTree

func _init() -> void:
    var scene := load("res://Main.tscn").instantiate()
    root.add_child(scene)
    assert(scene.MAX_SPEED == 150.0)
    assert(scene.ACCEL == 420.0)
    assert(scene.BRAKE == 300.0)
    assert(scene.GRAVITY == 1350.0)
    assert(scene.JUMP == -480.0)
    assert(scene.mode == "character")
    assert(scene.stage == 1)
    print("Lelics Godot smoke tests passed: smooth fixed-step movement constants and initial state")
    quit()
