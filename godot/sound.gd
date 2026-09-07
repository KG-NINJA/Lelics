extends Node
## BGMは使用せず、波・電子機器・攻撃ヒットの3系統だけを再生する。
const WAVES = preload("res://assets/audio/waves.wav")
const ELECTRONIC = preload("res://assets/audio/electronic.wav")
const HIT = preload("res://assets/audio/hit.wav")
var ambient: AudioStreamPlayer
var electronic: AudioStreamPlayer
var impact: AudioStreamPlayer
var played := {"electronic":0,"hit":0}
func _ready() -> void:
    ambient = AudioStreamPlayer.new()
    var loop: AudioStreamWAV = WAVES.duplicate()
    loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
    loop.loop_begin = 0
    loop.loop_end = roundi(loop.get_length()*loop.mix_rate)
    ambient.stream=loop
    ambient.volume_db=-23
    add_child(ambient)
    electronic = AudioStreamPlayer.new()
    electronic.stream=ELECTRONIC
    electronic.volume_db=-14
    electronic.max_polyphony=3
    add_child(electronic)
    impact = AudioStreamPlayer.new()
    impact.stream=HIT
    impact.volume_db=-10
    impact.max_polyphony=3
    add_child(impact)
    ambient.play()
func effect(kind: String) -> void:
    if kind == "electronic":
        played.electronic += 1
        electronic.play()
    elif kind == "hit":
        played.hit += 1
        impact.play()
