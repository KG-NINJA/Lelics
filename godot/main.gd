extends Node2D

# Lelicsのゲーム状態と、重く滑らかな16ビット描画をまとめて管理する。
const W := 640.0
const H := 360.0
const GROUND := 300.0
const MAX_SPEED := 150.0
const ACCEL := 420.0
const BRAKE := 300.0
const TURN_ACCEL := 260.0
const GRAVITY := 1350.0
const JUMP := -480.0
const PALETTE := [Color("#07111f"),Color("#102d4a"),Color("#1d5570"),Color("#4ca6a8"),Color("#8fd3b6"),Color("#f0d58a"),Color("#db765c"),Color("#743f72")]

var host := {"name":"ランナー","rank":1,"x":110.0,"y":252.0,"vx":0.0,"vy":0.0,"color":PALETTE[3]}
var actors := [host, {"name":"エンジニア","rank":2,"x":290.0,"y":252.0,"vx":0.0,"vy":0.0,"color":PALETTE[4]}, {"name":"守衛","rank":3,"x":410.0,"y":252.0,"vx":0.0,"vy":0.0,"color":PALETTE[6]}, {"name":"主任","rank":4,"x":545.0,"y":252.0,"vx":0.0,"vy":0.0,"color":PALETTE[5]}]
var spirit := Vector2(70,180)
var spirit_velocity := Vector2.ZERO
var mode := "character"
var stage := 1
var door_open := false
var boss_stuns := 0
var boss_defeated := false
var game_over := false
var ending := false
var log_lines: Array[String] = ["ランナーに憑依した。Zで離脱、Xで憑依。"]
var previous_position := Vector2.ZERO
var render_position := Vector2.ZERO
var fixed_accumulator := 0.0
var jump_lock := 0.0

func _ready() -> void:
    previous_position = Vector2(host.x, host.y)
    render_position = previous_position
    queue_redraw()

func _physics_process(delta: float) -> void:
    fixed_accumulator += delta
    while fixed_accumulator >= 1.0 / 60.0:
        fixed_accumulator -= 1.0 / 60.0
        _fixed_step(1.0 / 60.0)
    var blend := fixed_accumulator * 60.0
    render_position = previous_position.lerp(Vector2(host.x, host.y), blend)
    queue_redraw()

func _fixed_step(dt: float) -> void:
    if game_over or ending: return
    previous_position = Vector2(host.x, host.y)
    if Input.is_action_just_pressed("leave") and mode == "character":
        mode = "spirit"; spirit = Vector2(host.x, host.y - 50); spirit_velocity = Vector2.ZERO; _log("エーテルフォームへ離脱")
    if Input.is_action_just_pressed("possess") and mode == "spirit": _try_possess()
    if Input.is_action_just_pressed("interact"): _interact()
    if mode == "character": _move_host(dt)
    elif mode == "spirit": _move_spirit(dt)
    jump_lock = maxf(0.0, jump_lock - dt)
    if stage == 1 and host.x > 605 and host.rank == 1:
        stage = 2; host.x = 90; _log("ステージ2。ボディーガードが待っている")
    if stage == 2 and not boss_defeated and host.x > 500 and host.rank < 3:
        game_over = true; _log("位階不足でボスに拘束された")
    if stage == 2 and boss_defeated and host.x > 605:
        ending = true; _log("MISSION COMPLETE")

func _move_host(dt: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var target := direction * MAX_SPEED
    var rate := TURN_ACCEL if signf(target) != signf(host.vx) and absf(target) > 0.1 else (ACCEL if absf(target) > 0.1 else BRAKE)
    host.vx = move_toward(host.vx, target, rate * dt)
    if Input.is_action_just_pressed("jump") and absf(host.y - (GROUND - 48)) < 0.5 and jump_lock <= 0:
        host.vy = JUMP; jump_lock = 0.18; _log("重い着地を伴うジャンプ")
    host.vy += GRAVITY * dt
    host.x += host.vx * dt; host.y += host.vy * dt
    host.x = clampf(host.x, 25, 620)
    if host.y >= GROUND - 48:
        host.y = GROUND - 48; host.vy = 0
    if stage == 1 and host.x > 235 and host.rank < 3: host.x = 235
    if stage == 1 and host.x > 360 and host.rank < 4 and not door_open: host.x = 360

func _move_spirit(dt: float) -> void:
    var target := Vector2(Input.get_axis("move_left", "move_right"), 0) * 190.0
    spirit_velocity = spirit_velocity.move_toward(target, 500.0 * dt)
    spirit += spirit_velocity * dt
    spirit.x = clampf(spirit.x, 20, 620)

func _try_possess() -> void:
    var nearest: Dictionary = {}; var distance := 9999.0
    for actor in actors:
        var d: float = absf(float(actor.x) - spirit.x)
        if d < 70 and d < distance and int(actor.rank) <= 4:
            nearest = actor; distance = d
    if nearest.is_empty(): _log("近くに憑依対象がない"); return
    host = nearest; mode = "character"; _log("%sに憑依した" % host.name)

func _interact() -> void:
    if mode == "spirit": _log("エーテル状態では操作できない"); return
    if stage == 1 and host.rank >= 4:
        door_open = not door_open; _log("端末で扉を%s" % ("開放" if door_open else "閉鎖")); return
    if stage == 2 and absf(host.x - 500) < 100 and host.rank >= 2 and boss_stuns < 3:
        boss_stuns += 1; _log("ボディーガードがボスを拘束 (%d/3)" % boss_stuns)
        if boss_stuns >= 3: boss_defeated = true; _log("ボスのコアが停止した")
    else: _log("%s: …" % host.name)

func _log(text: String) -> void:
    log_lines.push_front(text)
    if log_lines.size() > 4: log_lines.pop_back()

func _draw() -> void:
    # 低解像度を意識した硬い色面と最近傍拡大で、動きの補間は維持する。
    draw_rect(Rect2(0,0,W,H), PALETTE[0])
    for layer in range(4):
        var color := PALETTE[1 + layer % 3]
        for i in range(-1, 9):
            var x := float(i * 100 - int(Time.get_ticks_msec() * 0.01 * (layer + 1)) % 100)
            draw_rect(Rect2(x, 100 - layer * 18, 72, 200 + layer * 18), color.darkened(0.12 * layer))
    draw_rect(Rect2(0,GROUND,W,60), PALETTE[2])
    draw_line(Vector2(0,GROUND), Vector2(W,GROUND), PALETTE[4], 3)
    draw_rect(Rect2(235,GROUND-105,12,105), PALETTE[6] if host.rank < 3 else PALETTE[4])
    draw_rect(Rect2(360,GROUND-120,12,120), PALETTE[6] if not door_open else PALETTE[4])
    for actor in actors: _draw_actor(actor, render_position if actor == host else Vector2(actor.x,actor.y))
    if mode == "spirit": draw_circle(spirit, 14, PALETTE[7]); draw_rect(Rect2(spirit-Vector2(5,5),Vector2(10,10)),PALETTE[5])
    if stage == 2: _draw_boss()
    _draw_hud()

func _draw_actor(actor: Dictionary, pos: Vector2) -> void:
    var body := Rect2(pos.x - 12, pos.y - 44, 24, 44)
    draw_rect(body, actor.color)
    draw_rect(Rect2(pos.x - 9,pos.y - 34,18,12), PALETTE[0])
    draw_rect(Rect2(pos.x - 13,pos.y - 4,10,4), PALETTE[0]); draw_rect(Rect2(pos.x + 3,pos.y - 4,10,4), PALETTE[0])

func _draw_boss() -> void:
    var color := PALETTE[4] if boss_defeated else PALETTE[7]
    draw_rect(Rect2(500,GROUND-130,54,130),color)
    draw_rect(Rect2(510,GROUND-112,34,22),PALETTE[0])
    for i in range(3): draw_rect(Rect2(450+i*28,GROUND-20,18,8), PALETTE[6] if i >= boss_stuns else PALETTE[5])

func _draw_hud() -> void:
    draw_rect(Rect2(8,8,624,38), PALETTE[0].lightened(0.18))
    draw_string(ThemeDB.fallback_font,Vector2(18,25),"LELICS // STAGE %d  // %s" % [stage,mode.to_upper()],HORIZONTAL_ALIGNMENT_LEFT,300,14,PALETTE[5])
    draw_string(ThemeDB.fallback_font,Vector2(18,42),"←→移動  SPACE跳躍  Z離脱  X憑依  C操作",HORIZONTAL_ALIGNMENT_LEFT,-1,11,PALETTE[4])
    draw_rect(Rect2(8,318,624,34),PALETTE[0].lightened(0.12))
    for i in range(log_lines.size()): draw_string(ThemeDB.fallback_font,Vector2(18,332+i*9),log_lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,9,PALETTE[4])
    if game_over: draw_string(ThemeDB.fallback_font,Vector2(230,180),"GAME OVER",HORIZONTAL_ALIGNMENT_LEFT,-1,24,PALETTE[6])
    if ending: draw_string(ThemeDB.fallback_font,Vector2(220,180),"MISSION COMPLETE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,PALETTE[5])
