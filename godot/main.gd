extends Node2D
## HTML版のルールと、固定物理・描画補間を分離する。
const Art = preload("res://character_art.gd")
const MAX_SPEED := 150.0
const ACCEL := 420.0
const BRAKE := 300.0
const TURN_ACCEL := 260.0
const GRAVITY := 1350.0
const JUMP := -480.0
const GROUND := 360.0
const PLATFORMS := [Rect2(420,264,160,16),Rect2(860,220,220,16)]
const PALETTE := [Color("07111f"),Color("102d4a"),Color("1d5570"),Color("4ca6a8"),Color("8fd3b6"),Color("f0d58a"),Color("db765c"),Color("743f72")]
var actors: Array[Dictionary] = []
var visuals: Array[Dictionary] = []
var host: Dictionary
var mode := "character"
var stage := 1
var spirit := Vector2(80,240)
var previous_spirit := spirit
var spirit_velocity := Vector2.ZERO
var door_x := 1040.0
var door_open := false
var gate_enabled := true
var gate_permanent := false
var boss_stuns := 0
var boss_timer := 0.0
var boss_defeated := false
var game_over := false
var ending := false
var clock := 0.0
var camera_x := 0.0
var jump_lock := 0.0
var logs: Array[String] = []
var action := ""
var action_age := 0.0
var action_applied := false
var action_target: Dictionary = {}
var input_override: Dictionary = {}
var font: Font
var verification_child := false
var sound: Node

func _ready() -> void:
    sound = preload("res://sound.gd").new()
    add_child(sound)
    var bold := FontVariation.new()
    bold.base_font = load("res://assets/NotoSansJP.ttf")
    bold.variation_opentype = {"wght":700}
    font = bold
    _add_actor("runner","ランナー",1,120,312,PALETTE[3])
    _add_actor("engineer","エンジニア",2,480,216,PALETTE[4])
    _add_actor("guard","オーバーウォッチ",3,720,312,PALETTE[6])
    _add_actor("director","セキュリティ主任",4,980,312,PALETTE[5])
    _add_actor("terminal","セキュリティ端末",4,1180,312,PALETTE[3],"computer")
    host = actors[0]
    _log("Zで離脱 / Xで憑依。位階を借りて進もう。")
    get_node("World").draw.connect(_draw_world)
    get_node("HUD/Display").draw.connect(_draw_hud)
    if "--verify" in OS.get_cmdline_user_args() and not verification_child:
        set_physics_process(false)
        set_process(false)
        _verify.call_deferred()

func _verify() -> void:
    var suite: Node = load("res://verification_suite.gd").new()
    get_tree().root.add_child(suite)

func _add_actor(id: String, title: String, rank: int, x: float, y: float, color: Color, kind := "character") -> void:
    actors.append({"id":id,"name":title,"rank":rank,"x":x,"y":y,"vx":0.0,"vy":0.0,"color":color,"type":kind,"downed":false,"grounded":true})
    visuals.append({"previous":Vector2(x,y),"facing":1.0,"phase":0.0,"state":"idle","age":0.0,"duration":0.18,"speed":0.0})
    var node: Node2D = preload("res://Actor.tscn").instantiate()
    node.name = id
    get_node("World").add_child(node)
    node.draw.connect(_draw_actor.bind(actors.size()-1,node))

func _physics_process(dt: float) -> void:
    for i in range(actors.size()): visuals[i].previous = Vector2(actors[i].x,actors[i].y)
    previous_spirit = spirit
    _fixed_step(dt)
    _animate(dt)

func _process(dt: float) -> void:
    clock += dt
    var f := Engine.get_physics_interpolation_fraction()
    var target: Vector2 = previous_spirit.lerp(spirit,f) if mode == "spirit" else visuals[actors.find(host)].previous.lerp(Vector2(host.x,host.y),f)
    camera_x = clampf(target.x-260,0,1360)
    get_node("World").position = Vector2(-camera_x,-60)
    get_node("World").queue_redraw()
    for child in get_node("World").get_children(): child.queue_redraw()
    get_node("HUD/Display").queue_redraw()

func _axis(negative: String, positive: String) -> float:
    if not input_override.is_empty(): return float(input_override.get(positive,0))-float(input_override.get(negative,0))
    return Input.get_axis(negative,positive)

func _pressed(key: String) -> bool:
    if not input_override.is_empty(): return bool(input_override.get(key,false))
    return Input.is_action_just_pressed(key)

func _fixed_step(dt: float) -> void:
    if game_over or ending: return
    jump_lock = maxf(0,jump_lock-dt)
    boss_timer = maxf(0,boss_timer-dt)
    if action != "":
        action_age += dt
        if action_age >= 0.12 and not action_applied:
            action_applied = true
            _apply_action()
        if action_age >= 0.35: action = ""
    if _pressed("leave") and mode in ["character","computer"] and action == "": _begin_action("leave")
    if _pressed("possess") and action == "": _try_possess()
    if _pressed("interact") and action == "": _interact()
    if mode == "character" and not host.downed: _move_host(dt)
    elif mode == "spirit": _move_spirit(dt)
    _check_progress()

func _move_host(dt: float) -> void:
    var target := _axis("move_left","move_right")*MAX_SPEED
    if jump_lock > 0 and host.grounded: target *= 0.3
    if action != "": target = 0
    var rate := TURN_ACCEL if absf(host.vx)>0.1 and signf(target) != signf(host.vx) and absf(target)>0.1 else (ACCEL if absf(target)>0.1 else BRAKE)
    host.vx = move_toward(host.vx,target,rate*dt)
    if _pressed("jump") and host.grounded and jump_lock<=0 and action == "":
        host.vy = JUMP
        host.grounded = false
    var old_feet: float = host.y+48
    host.vy += GRAVITY*dt
    host.x = clampf(host.x+host.vx*dt,24,1976)
    host.y += host.vy*dt
    host.grounded = false
    var landing := GROUND
    for p in PLATFORMS:
        if host.x+24>p.position.x and host.x-24<p.end.x and old_feet<=p.position.y+0.1 and host.y+48>=p.position.y and host.vy>=0: landing = minf(landing,p.position.y)
    if host.y+48>=landing:
        if host.vy>100: jump_lock = 0.18
        host.y = landing-48
        host.vy = 0.0
        host.grounded = true
    if gate_enabled:
        if host.rank>=3:
            gate_enabled = false
            gate_permanent = true
            _log("高位認証により関門を恒久解除。")
        elif host.y+40>GROUND-120 and host.y<GROUND+20 and host.x+20>760 and host.x<792:
            host.x = 740.0 if host.x<760 else 812.0
            host.vx = 0.0

func _move_spirit(dt: float) -> void:
    var direction := Vector2(_axis("move_left","move_right"),_axis("move_up","move_down"))
    spirit_velocity = spirit_velocity.move_toward(direction*190,500*dt)
    spirit += spirit_velocity*dt
    spirit.x = clampf(spirit.x,40,1400)
    spirit.y = clampf(spirit.y,40,260)

func _try_possess() -> void:
    var pivot := spirit if mode == "spirit" else Vector2(host.x,host.y)
    var nearest: Dictionary = {}
    var distance := 80.0
    for actor in actors:
        if actor == host or actor.downed or actor.type == "boss": continue
        var d := pivot.distance_to(Vector2(actor.x,actor.y))
        if d<distance:
            nearest = actor
            distance = d
    if nearest.is_empty():
        _log("近くに憑依できる対象がない。")
        return
    if nearest.type == "computer" and (mode != "character" or host.rank<4):
        _log("端末への接続には位階4の器が必要。")
        return
    _begin_action("possess",nearest)

func _begin_action(kind: String, target: Dictionary = {}) -> void:
    action = kind
    action_age = 0
    action_applied = false
    action_target = target if not target.is_empty() else host
    _set_animation(actors.find(action_target),kind,0.35)

func _apply_action() -> void:
    match action:
        "leave":
            sound.effect("electronic")
            spirit = Vector2(host.x,host.y-40)
            previous_spirit = spirit
            spirit_velocity = Vector2.ZERO
            host.vx = 0.0
            host.vy = 0.0
            mode = "spirit"
            _log("器から離脱した。")
        "possess":
            sound.effect("electronic")
            host = action_target
            host.vx = 0.0
            host.vy = 0.0
            mode = "computer" if host.type == "computer" else "character"
            _log("%sに憑依した。" % host.name)
        "interact":
            if mode == "computer":
                sound.effect("electronic")
                door_open = not door_open
                if not gate_permanent: gate_enabled = not door_open
                _log("端末操作：扉を%s。" % ("開放" if door_open else "閉鎖"))
            elif host.id.begins_with("bodyguard"):
                if host.downed or boss_defeated: return
                if absf(host.x-1420)>160:
                    _log("ボスにもっと接近してから起動する。")
                    return
                host.downed = true
                sound.effect("hit")
                host.vx = 0.0
                host.vy = 0.0
                boss_stuns += 1
                boss_timer = 5.5
                boss_defeated = boss_stuns>=3
                _log("自爆シールドで拘束 %d/3。%s" % [boss_stuns,"ランナーで脱出せよ！" if boss_defeated else "次の器へ。"])

func _interact() -> void:
    if mode == "spirit":
        _log("エーテル状態では会話できない。")
        return
    if mode == "computer" or host.id.begins_with("bodyguard"):
        _begin_action("interact")
        return
    _set_animation(actors.find(host),"interact",0.35)
    var talks := {"runner":"誰かの位階を借りて進もう。出口はランナーで。","engineer":"関門は守衛以上、端末は主任の位階が必要。","guard":"出口を抜ける資格はランナーだけだ。","director":"端末の近くでX。接続したらCで扉を開く。"}
    _log(talks.get(host.id,"…"))

func _check_progress() -> void:
    if mode != "character": return
    if stage == 1 and ((door_open and host.x>door_x+36) or host.x>=1480):
        if host.id == "runner": _stage_two()
        else: _lose("不正侵入。出口はランナーで通過する必要がある。")
    elif stage == 2:
        if not boss_defeated and boss_timer<=0 and not host.id.begins_with("bodyguard") and host.x>=1370: _lose("センチネルの一撃。別の手段を探そう。")
        elif boss_defeated and host.id == "runner" and host.x>=1580:
            ending = true
            mode = "ending"
            for actor in actors:
                actor.vx = 0.0
                actor.vy = 0.0
            _log("器たちの意志を継ぎ、施設から脱出した。")

func _lose(reason: String) -> void:
    sound.effect("hit")
    game_over = true
    mode = "game_over"
    for actor in actors:
        actor.vx = 0.0
        actor.vy = 0.0
    _log(reason)

func _stage_two() -> void:
    if stage == 2: return
    stage = 2
    var positions := [240.0,120.0,460.0,720.0,1080.0]
    for i in range(5):
        actors[i].x = positions[i]
        actors[i].vx = 0.0
        actors[i].vy = 0.0
        visuals[i].previous = Vector2(actors[i].x,actors[i].y)
    host = actors[0]
    host.y = 312.0
    visuals[0].previous = Vector2(host.x,host.y)
    door_x = 1180
    door_open = false
    gate_enabled = false
    gate_permanent = true
    for i in range(3): _add_actor("bodyguard_%d" % i,"ボディーガード%s" % ["A","B","C"][i],2,1230.0+i*50,312,Color("8aa9c0"))
    _add_actor("boss","ヴォイドセンチネル",7,1420,312,PALETTE[7],"boss")
    _log("STAGE 2 / 3人のボディーガードが合流した。")

func _set_animation(index: int, state: String, duration: float) -> void:
    visuals[index].state = state
    visuals[index].age = 0.0
    visuals[index].duration = duration

func _animate(dt: float) -> void:
    for i in range(actors.size()):
        var actor: Dictionary = actors[i]
        var v: Dictionary = visuals[i]
        var speed: float = absf(actor.vx) if actor == host and mode == "character" else 0.0
        var old_speed: float = v.speed
        v.age += dt
        v.phase += speed*dt*0.095
        v.speed = speed
        if v.state in ["leave","possess","interact"] and v.age<v.duration: continue
        if not actor.grounded: v.state = "rise" if actor.vy<0 else "fall"
        elif v.state in ["rise","fall"]: _set_animation(i,"land",0.22)
        elif v.state in ["land","start","stop","turn"] and v.age<v.duration: pass
        elif speed>0.1 and signf(actor.vx)!=v.facing:
            v.facing = signf(actor.vx)
            _set_animation(i,"turn",0.18)
        elif speed>0.1 and old_speed<=0.1: _set_animation(i,"start",0.12)
        elif speed<=0.1 and old_speed>0.1: _set_animation(i,"stop",0.18)
        else: v.state = "walk" if speed>0.1 else "idle"

func _log(message: String) -> void:
    logs.push_front(message)
    if logs.size()>3: logs.pop_back()

func _draw_world() -> void:
    var c: Node2D = get_node("World")
    c.draw_rect(Rect2(camera_x,60,640,360),PALETTE[0])
    for i in range(26):
        var x := i*96.0
        c.draw_rect(Rect2(x,100,62,260),PALETTE[1])
        c.draw_rect(Rect2(x+4,110,4,240),PALETTE[2])
        for j in range(5): c.draw_rect(Rect2(x+16,130+j*35,32,4),PALETTE[2])
    c.draw_rect(Rect2(0,GROUND,2000,60),PALETTE[1])
    c.draw_rect(Rect2(0,GROUND,2000,3),PALETTE[4])
    for i in range(50): c.draw_rect(Rect2(i*40,GROUND+8,30,2),PALETTE[2])
    for p in PLATFORMS:
        c.draw_rect(p,PALETTE[2])
        c.draw_rect(Rect2(p.position,Vector2(p.size.x,3)),PALETTE[4])
    c.draw_rect(Rect2(756,232,40,8),PALETTE[2])
    if gate_enabled:
        for i in range(6): c.draw_rect(Rect2(760+i*5,242,2,118),PALETTE[6])
    c.draw_rect(Rect2(door_x-4,216,32,5),PALETTE[4])
    if not door_open:
        c.draw_rect(Rect2(door_x,221,24,139),PALETTE[2])
        for i in range(6): c.draw_rect(Rect2(door_x+3,232+i*20,18,2),PALETTE[3])
    c.draw_string(font,Vector2(door_x-15,209),"LAB / %s" % ("OPEN" if door_open else "LOCK"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,PALETTE[5])
    c.draw_string(font,Vector2(1580,275),"EXIT →",HORIZONTAL_ALIGNMENT_LEFT,-1,16,PALETTE[4])
    if mode == "spirit":
        var center := previous_spirit.lerp(spirit,Engine.get_physics_interpolation_fraction())
        for i in range(5,0,-1): c.draw_rect(Rect2(center+Vector2(-i*5,sin(clock*5-i*0.7)*4)-Vector2(3,3),Vector2(6,6)),PALETTE[7] if i>2 else PALETTE[3])
        c.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-13),center+Vector2(9,-4),center+Vector2(7,8),center+Vector2(0,12),center+Vector2(-7,8),center+Vector2(-9,-4)]),PALETTE[3])
        c.draw_rect(Rect2(center-Vector2(5,5),Vector2(10,9)),PALETTE[4])
        c.draw_rect(Rect2(center+Vector2(-3,-2),Vector2(2,3)),PALETTE[0])
        c.draw_rect(Rect2(center+Vector2(2,-2),Vector2(2,3)),PALETTE[0])

func _draw_actor(index: int, c: Node2D) -> void:
    var actor: Dictionary = actors[index]
    var v: Dictionary = visuals[index]
    var pos: Vector2 = v.previous.lerp(Vector2(actor.x,actor.y),Engine.get_physics_interpolation_fraction())+Vector2(0,48)
    if actor.type == "computer":
        c.draw_rect(Rect2(pos+Vector2(-15,-42),Vector2(30,42)),PALETTE[0])
        c.draw_rect(Rect2(pos+Vector2(-13,-40),Vector2(26,24)),PALETTE[2])
        c.draw_rect(Rect2(pos+Vector2(-10,-37),Vector2(20,15)),PALETTE[4] if mode == "computer" else PALETTE[3])
        for i in range(3): c.draw_rect(Rect2(pos+Vector2(-8,-34+i*4),Vector2(12-i*3,1)),PALETTE[0])
        c.draw_rect(Rect2(pos+Vector2(-9,-13),Vector2(18,3)),PALETTE[5])
        c.draw_rect(Rect2(pos+Vector2(-11,-7),Vector2(22,5)),PALETTE[2])
    elif actor.type == "boss": _draw_boss(c,pos)
    elif actor.downed:
        c.draw_rect(Rect2(pos+Vector2(-22,-9),Vector2(34,8)),actor.color)
        c.draw_rect(Rect2(pos+Vector2(12,-10),Vector2(10,9)),Art.SKIN)
        c.draw_rect(Rect2(pos+Vector2(-22,-3),Vector2(44,3)),PALETTE[0])
    else:
        var subframe := Engine.get_physics_interpolation_fraction() / 60.0
        var pose := Art.pose(v.state,v.phase + v.speed * subframe * 0.095,minf(v.speed/MAX_SPEED,1),clampf((v.age+subframe)/v.duration,0,1))
        Art.draw_actor(c,actor,pos,pose,v.facing,actor == host and mode == "character")
    var label: String = actor.name
    if actor.id.begins_with("bodyguard"):
        label = "護衛" + ["A","B","C"][int(actor.id.get_slice("_",1))]
    c.draw_string(font,pos+Vector2(-27,-66 if actor.type != "boss" else -143),"%s / %d" % [label,actor.rank],HORIZONTAL_ALIGNMENT_LEFT,-1,9,PALETTE[4])

func _draw_boss(c: Node2D, pos: Vector2) -> void:
    pos.y += 72.0 if boss_defeated else (4.0 if boss_timer>0 else sin(clock*1.5)*1.5)
    c.draw_rect(Rect2(pos+Vector2(-31,-91),Vector2(62,59)),PALETTE[0])
    c.draw_rect(Rect2(pos+Vector2(-26,-88),Vector2(52,51)),PALETTE[7])
    c.draw_rect(Rect2(pos+Vector2(-35,-96),Vector2(70,14)),PALETTE[2])
    c.draw_rect(Rect2(pos+Vector2(-19,-126),Vector2(38,29)),PALETTE[2])
    c.draw_rect(Rect2(pos+Vector2(-15,-119),Vector2(30,13)),PALETTE[0])
    c.draw_rect(Rect2(pos+Vector2(-12,-115),Vector2(24,3)),PALETTE[4] if boss_defeated else PALETTE[6])
    c.draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-79),pos+Vector2(10,-66),pos+Vector2(0,-53),pos+Vector2(-10,-66)]),PALETTE[5] if boss_timer>0 else PALETTE[6])
    for side in [-1,1]:
        Art.limb(c,pos+Vector2(side*27,-83),pos+Vector2(side*40,-48),12,PALETTE[7])
        Art.limb(c,pos+Vector2(side*40,-48),pos+Vector2(side*33,-23),10,PALETTE[2])
        Art.limb(c,pos+Vector2(side*14,-36),pos+Vector2(side*18,-5),12,PALETTE[2])
        c.draw_rect(Rect2(pos+Vector2(side*18-9,-6),Vector2(21,7)),PALETTE[0])
    if boss_timer>0 and not boss_defeated:
        for i in range(3): c.draw_line(pos+Vector2(-42,-95+i*23),pos+Vector2(42,-80+i*23),PALETTE[4],2)

func _draw_hud() -> void:
    var c: Node2D = get_node("HUD/Display")
    c.draw_rect(Rect2(8,7,624,42),PALETTE[0])
    c.draw_rect(Rect2(8,7,3,42),PALETTE[3])
    c.draw_string(font,Vector2(18,24),"LELICS   /   STAGE %d   /   %s" % [stage,mode.to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,12,PALETTE[5])
    c.draw_string(font,Vector2(18,42),"矢印：移動  SPACE：跳躍  Z：離脱  X：憑依  C：会話・操作",HORIZONTAL_ALIGNMENT_LEFT,-1,10,PALETTE[4])
    c.draw_rect(Rect2(8,312,624,44),PALETTE[0])
    for i in range(logs.size()): c.draw_string(font,Vector2(18,324+i*12),logs[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,PALETTE[4])
    if stage == 2: c.draw_string(font,Vector2(470,65),"拘束 %d / 3" % boss_stuns,HORIZONTAL_ALIGNMENT_LEFT,-1,12,PALETTE[5])
    if game_over or ending:
        c.draw_rect(Rect2(130,125,380,94),PALETTE[0])
        c.draw_rect(Rect2(130,125,380,3),PALETTE[6] if game_over else PALETTE[4])
        c.draw_string(font,Vector2(195,165),"GAME OVER" if game_over else "MISSION COMPLETE",HORIZONTAL_ALIGNMENT_LEFT,-1,22,PALETTE[5])
        c.draw_string(font,Vector2(160,199),"再挑戦はゲームを再起動してください。" if game_over else "犠牲の意志を継いで、外の世界へ。",HORIZONTAL_ALIGNMENT_LEFT,-1,13,PALETTE[4])
