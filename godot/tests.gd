extends SceneTree
## 同じ検証スイートをエディター、Windows、Webで実行する。
func _init() -> void:
    var suite: Node = load("res://verification_suite.gd").new()
    root.add_child.call_deferred(suite)
