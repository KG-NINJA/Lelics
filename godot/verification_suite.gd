extends Node
## 固定入力でルール、遷移、描画速度の独立性を確認する。
var checks := 0
var failures: Array[String] = []
var game: Node2D
func _ready() -> void:
    call_deferred("run")
func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        push_error(label)
func fresh() -> void:
    if is_instance_valid(game): game.free()
    game = load("res://Main.tscn").instantiate()
    game.verification_child = true
    get_tree().root.add_child(game)
    game.set_physics_process(false)
    game.set_process(false)
    game.input_override = {"test":true}
func ticks(count: int) -> void:
    for i in range(count): game._physics_process(1.0/60.0)
func finish_action() -> void:
    ticks(22)
func run() -> void:
    fresh()
    check(game.actors.size()==5,"initial roster")
    check(game.host.id=="runner" and game.mode=="character","initial possession")
    check(game.get_node("World/runner")!=null and game.get_node("HUD/Display")!=null,"scene composition")
    check(InputMap.action_get_events("move_left")[1].physical_keycode==KEY_LEFT,"left arrow mapping")
    check(InputMap.action_get_events("move_right")[1].physical_keycode==KEY_RIGHT,"right arrow mapping")
    check(game.MAX_SPEED==150 and game.ACCEL==420 and game.BRAKE==300 and game.TURN_ACCEL==260,"movement constants")
    check(game.JUMP==-480 and game.GRAVITY==1350,"jump constants")
    check(game.sound.get_child_count()==3,"only waves, electronic and hit players")
    check(game.sound.ambient.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"waves loop")
    check(game.sound.ambient.stream.get_length()==8.0,"wave duration")
    game.input_override = {"move_right":true}
    ticks(1)
    check(game.host.vx>0 and game.host.vx<10,"acceleration starts gradually")
    check(is_equal_approx(game.host.vx,420.0/60.0),"rest uses acceleration rather than turn rate")
    check(game.visuals[0].state=="start","start pose")
    ticks(59)
    check(is_equal_approx(game.host.vx,150),"speed cap")
    game.input_override = {"test":true}
    ticks(1)
    check(game.host.vx>0 and game.host.vx<150,"release preserves inertia")
    ticks(30)
    check(game.host.vx==0,"braking settles")
    check(game.visuals[0].state=="stop","stop pose")
    game.input_override = {"move_right":true}
    ticks(30)
    game.input_override = {"move_left":true}
    ticks(1)
    check(game.host.vx>0,"turn preserves forward inertia")
    ticks(35)
    check(game.host.vx<0,"turn reverses eventually")
    check(game.visuals[0].facing==-1,"turn facing")
    fresh()
    game.input_override = {"jump":true}
    ticks(1)
    check(game.host.vy<0 and not game.host.grounded,"jump launches")
    check(game.visuals[0].state=="rise","rise pose")
    game.input_override = {"test":true}
    ticks(24)
    check(game.visuals[0].state=="fall","fall pose")
    ticks(18)
    check(game.host.grounded and game.host.y==312,"jump lands on floor")
    check(game.jump_lock>0,"landing recovery")
    check(game.visuals[0].state=="land","landing pose")
    game.input_override = {"jump":true}
    ticks(1)
    check(game.host.grounded,"recovery blocks immediate jump")
    fresh()
    game.host.x = 480
    game.host.y = 180
    game.host.vy = 200
    game.host.grounded = false
    ticks(10)
    check(game.host.y==216 and game.host.grounded,"platform landing")
    fresh()
    game.host.x = 739
    game.input_override = {"move_right":true}
    ticks(20)
    check(game.host.x<=740 and game.gate_enabled,"rank1 gate blocked")
    game.host = game.actors[2]
    ticks(1)
    check(not game.gate_enabled and game.gate_permanent,"rank3 permanent unlock")
    fresh()
    game._begin_action("leave")
    ticks(6)
    check(game.mode=="character","leave anticipation")
    ticks(2)
    check(game.mode=="spirit","leave contact")
    check(game.sound.played.electronic==1,"leave electronic sound")
    ticks(14)
    check(game.action=="","leave recovery")
    game.spirit = Vector2(480,190)
    game._try_possess()
    finish_action()
    check(game.host.id=="engineer","spirit possession")
    check(game.mode=="character","possession character state")
    fresh()
    game.host = game.actors[3]
    game.host.x = 1120
    game._try_possess()
    finish_action()
    check(game.mode=="computer" and game.host.id=="terminal","rank4 terminal possession")
    game._interact()
    finish_action()
    check(game.door_open and not game.gate_enabled,"terminal opens linked gate")
    check(game.sound.played.electronic==2,"terminal contact electronic sound")
    game._interact()
    finish_action()
    check(not game.door_open,"terminal closes door")
    game._begin_action("leave")
    finish_action()
    check(game.mode=="spirit","leave terminal")
    fresh()
    game.host.x=1120
    game._try_possess()
    check(game.action=="" and game.mode=="character","rank1 terminal denied")
    game.mode="spirit"
    game.spirit=Vector2(1180,260)
    game._try_possess()
    check(game.action=="","spirit terminal denied")
    fresh()
    game.door_open=true
    game.host.x=1077
    game._check_progress()
    check(game.stage==2 and game.host.id=="runner","runner stage transition")
    check(game.actors.size()==9 and game.door_x==1180 and not game.door_open,"stage2 roster and door")
    check(game.host.x==240,"stage2 spawn")
    game._stage_two()
    check(game.actors.size()==9,"stage2 setup idempotent")
    fresh()
    game.host=game.actors[3]
    game.host.x=1077
    game.door_open=true
    game._check_progress()
    check(game.game_over and game.mode=="game_over","wrong host exit loses")
    fresh()
    game._stage_two()
    game.host.x=1370
    game._check_progress()
    check(game.game_over,"runner boss contact loses")
    check(game.sound.played.hit==1,"boss attack hit sound")
    fresh()
    game._stage_two()
    game.host=game.actors[3]
    game.host.x=1370
    game._check_progress()
    check(game.game_over,"rank4 has no boss immunity")
    fresh()
    game._stage_two()
    game.host=game.actors[5]
    game.host.x=1300
    game._interact()
    finish_action()
    check(game.boss_stuns==1 and game.host.downed,"bodyguard sacrifice")
    check(game.sound.played.hit==1,"shield contact hit sound")
    check(game.boss_timer>5,"stun duration")
    game._interact()
    finish_action()
    check(game.boss_stuns==1,"same bodyguard cannot repeat")
    game.mode="spirit"
    game.spirit=Vector2(1300,260)
    game._try_possess()
    finish_action()
    check(not game.host.downed,"downed excluded from possession")
    game.mode="spirit"
    ticks(340)
    check(game.boss_timer==0 and not game.boss_defeated,"temporary stun expires")
    for index in [6,7]:
        game.host=game.actors[index]
        game.mode="character"
        game.host.x=1300
        game._interact()
        finish_action()
    check(game.boss_stuns==3 and game.boss_defeated,"three distinct sacrifices defeat boss")
    game.host.x=1590
    game._check_progress()
    check(not game.ending,"ending requires runner")
    game.host=game.actors[0]
    game.host.x=1590
    game.host.vx=150.0
    game._check_progress()
    check(game.ending and game.mode=="ending","runner escapes")
    check(game.host.vx==0 and game.host.vy==0,"ending stops movement")
    var reference: Array = trajectory(30)
    check(trajectory(60)==reference,"30/60 fps identical physics trajectory")
    check(trajectory(120)==reference,"30/120 fps identical physics trajectory")
    for state in ["idle","walk","start","stop","turn","rise","fall","land","leave","possess","interact"]:
        var pose: Dictionary = game.Art.pose(state,1.2,0.7,0.5)
        check(pose.size()==6 and is_finite(pose.squash),"pose valid: "+state)
    print(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()}))
    if failures.is_empty(): print("LELICS_TESTS_PASS")
    game.free()
    var result := JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()})
    if OS.has_feature("web"):
        JavaScriptBridge.eval("document.title = " + JSON.stringify("LELICS VERIFY " + result))
    else:
        get_tree().quit(0 if failures.is_empty() else 1)

func trajectory(fps: int) -> Array:
    fresh()
    var elapsed := 0.0
    var physics_tick := 0
    var result: Array = []
    for frame in range(fps*3):
        elapsed += 1.0/fps
        while elapsed+0.0000001>=1.0/60.0:
            elapsed -= 1.0/60.0
            game.input_override={"move_right":physics_tick<60,"move_left":physics_tick>=90 and physics_tick<130,"jump":physics_tick==20}
            game._physics_process(1.0/60.0)
            result.append([game.host.x,game.host.y,game.host.vx,game.host.vy])
            physics_tick += 1
    return result
