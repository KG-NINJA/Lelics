extends RefCounted
## オリジナルの限定色キャラクター。関節の補間で輪郭と重心を連動させる。
const INK := Color("101827")
const SKIN := Color("deb68c")
const SHADE := Color("936d69")
const LIGHT := Color("eff3cf")
## 接地、蹴り出し、回収の8姿勢。約16姿勢/秒で巡回し、間を補間する。
const WALK := [Vector4(0,5,0,0),Vector4(6,3,0,-5),Vector4(9,0,0,-7),Vector4(6,0,3,-5),Vector4(0,0,5,0),Vector4(-6,0,3,5),Vector4(-9,0,0,7),Vector4(-6,3,0,5)]

static func pose(state: String, phase: float, strength: float, progress: float) -> Dictionary:
    var key_position := fposmod(phase / TAU * 8, 8)
    var key := int(key_position)
    var frame: Vector4 = WALK[key].lerp(WALK[(key+1)%8],key_position-key)
    var stride := frame.x * strength
    var lift_left := frame.y * strength
    var lift_right := frame.z * strength
    var squash := absf(cos(phase)) * 1.5 * strength
    var lean := 2.5 * strength
    var arms := frame.w * strength
    if state == "rise":
        stride = 5; lift_left = 9; lift_right = 3; arms = -7; lean = 3
    elif state == "fall":
        stride = 6; lift_left = 2; lift_right = 5; arms = 8; lean = -1
    elif state == "land":
        squash = sin(progress * PI) * 7; stride = 5; arms = 5; lean = 3
    elif state == "start":
        squash += sin(progress * PI) * 3; lean += 3 * sin(progress * PI)
    elif state == "stop":
        lean = -4 * (1 - progress); squash += 2 * sin(progress * PI)
    elif state == "turn":
        squash += sin(progress * PI) * 4; lean = -3
    elif state in ["leave", "possess", "interact"]:
        arms = -12 * sin(progress * PI); squash = 2 * sin(progress * PI); lean = 0
    return {"stride":stride,"left":lift_left,"right":lift_right,"squash":squash,"lean":lean,"arms":arms}

static func limb(canvas: CanvasItem, a: Vector2, b: Vector2, width: float, color: Color) -> void:
    canvas.draw_line(a, b, INK, width + 2, false)
    canvas.draw_line(a, b, color, width, false)

static func draw_actor(canvas: CanvasItem, actor: Dictionary, feet: Vector2, p: Dictionary, facing: float, active: bool) -> void:
    var coat: Color = actor.color
    var rank: int = actor.rank
    canvas.draw_set_transform(feet, 0, Vector2(facing, 1))
    # 接地影と奥側の脚・腕から描き、手前の輪郭を保つ。
    canvas.draw_rect(Rect2(-13, -1, 26, 2), INK)
    var hip := Vector2(p.lean, -22 + p.squash)
    var shoulder := hip + Vector2(p.lean, -15)
    var rear_foot := Vector2(-p.stride, -p.right - 2)
    var front_foot := Vector2(p.stride, -p.left - 2)
    limb(canvas, hip, (hip + rear_foot) * 0.5 + Vector2(3, 0), 5, coat.darkened(0.45))
    limb(canvas, (hip + rear_foot) * 0.5 + Vector2(3, 0), rear_foot, 4, coat.darkened(0.45))
    limb(canvas, shoulder, shoulder + Vector2(-p.arms - 2, 13), 4, coat.darkened(0.4))
    canvas.draw_rect(Rect2(hip.x - 7, shoulder.y - 1, 14, 19), INK)
    canvas.draw_rect(Rect2(hip.x - 6, shoulder.y, 12, 16), coat)
    canvas.draw_rect(Rect2(hip.x - 6, shoulder.y, 3, 16), coat.darkened(0.3))
    canvas.draw_rect(Rect2(hip.x + 1, shoulder.y + 2, 3, 9), coat.lightened(0.25))
    canvas.draw_rect(Rect2(hip.x - 7, hip.y - 2, 14, 3), INK)
    canvas.draw_rect(Rect2(hip.x + 1, hip.y - 2, 3, 2), LIGHT)
    limb(canvas, hip, (hip + front_foot) * 0.5 + Vector2(4, -1), 5, coat.darkened(0.2))
    limb(canvas, (hip + front_foot) * 0.5 + Vector2(4, -1), front_foot, 4, coat.darkened(0.1))
    canvas.draw_rect(Rect2(rear_foot.x - 3, rear_foot.y - 1, 9, 3), INK)
    canvas.draw_rect(Rect2(front_foot.x - 3, front_foot.y - 1, 10, 3), INK)
    canvas.draw_rect(Rect2(front_foot.x, front_foot.y, 6, 1), SHADE)
    var head := shoulder + Vector2(1, -10)
    canvas.draw_rect(Rect2(head.x - 6, head.y - 3, 12, 13), INK)
    canvas.draw_rect(Rect2(head.x - 4, head.y - 1, 9, 10), SKIN)
    canvas.draw_rect(Rect2(head.x - 4, head.y + 3, 3, 6), SHADE)
    canvas.draw_rect(Rect2(head.x + 5, head.y + 3, 2, 3), SKIN)
    canvas.draw_rect(Rect2(head.x + 3, head.y + 2, 2, 2), INK)
    # ランナーのスカーフ、技師のゴーグル、守衛の兜、主任の襟章。
    if rank == 1:
        canvas.draw_rect(Rect2(head.x - 6, head.y - 3, 11, 4), INK)
        canvas.draw_rect(Rect2(shoulder.x - 7, shoulder.y - 1, 12, 3), Color("db765c"))
        canvas.draw_rect(Rect2(shoulder.x - 13, shoulder.y + 1 + p.arms * 0.15, 8, 3), Color("a34b50"))
    elif actor.get("id", "").begins_with("bodyguard"):
        canvas.draw_rect(Rect2(head.x - 6, head.y - 4, 13, 5), coat.darkened(0.3))
        canvas.draw_rect(Rect2(head.x - 1, head.y + 1, 8, 3), INK)
        canvas.draw_rect(Rect2(head.x, head.y + 2, 6, 1), LIGHT)
        canvas.draw_rect(Rect2(hip.x - 5, shoulder.y + 2, 10, 9), INK)
        canvas.draw_rect(Rect2(hip.x - 3, shoulder.y + 3, 6, 6), Color("8fd3b6"))
        canvas.draw_rect(Rect2(shoulder.x - 9, shoulder.y - 2, 6, 6), coat.lightened(0.2))
    elif rank == 2:
        canvas.draw_rect(Rect2(head.x - 6, head.y - 3, 13, 4), Color("e0b95e"))
        canvas.draw_rect(Rect2(head.x, head.y + 1, 6, 3), INK)
        canvas.draw_rect(Rect2(head.x + 1, head.y + 1, 4, 2), Color("8fd3b6"))
        canvas.draw_rect(Rect2(hip.x - 9, hip.y - 5, 5, 7), SHADE)
    elif rank == 3:
        canvas.draw_rect(Rect2(head.x - 6, head.y - 4, 13, 7), coat.darkened(0.3))
        canvas.draw_rect(Rect2(head.x - 1, head.y + 2, 8, 3), INK)
        canvas.draw_rect(Rect2(head.x + 1, head.y + 2, 5, 1), LIGHT)
        canvas.draw_rect(Rect2(shoulder.x - 9, shoulder.y - 2, 18, 5), coat.lightened(0.3))
    else:
        canvas.draw_rect(Rect2(head.x - 6, head.y - 4, 12, 4), Color("c8d6ca"))
        canvas.draw_rect(Rect2(hip.x, shoulder.y + 1, 2, 9), INK)
        canvas.draw_rect(Rect2(hip.x + 4, shoulder.y + 4, 3, 3), LIGHT)
    var elbow := shoulder + Vector2(p.arms * 0.65 + 2, 8)
    var hand := shoulder + Vector2(p.arms + 5, 14 - absf(p.arms) * 0.4)
    limb(canvas, shoulder, elbow, 4, coat)
    limb(canvas, elbow, hand, 3, coat.lightened(0.15))
    canvas.draw_rect(Rect2(hand - Vector2(2, 1), Vector2(4, 4)), SKIN)
    if active:
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3,-59),Vector2(3,-59),Vector2(0,-55)]), Color("8fd3b6"))
    canvas.draw_set_transform(Vector2.ZERO)
