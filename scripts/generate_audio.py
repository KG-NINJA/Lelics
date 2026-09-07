"""オリジナルの波・電子音・ヒット音を標準ライブラリだけで合成する。"""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[1]/'godot/assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)
RATE=22050
rng=random.Random(9271)
def save(name,values):
    peak=max(abs(v) for v in values)
    gain=min(1.0,0.85/max(peak,0.00001))
    with wave.open(str(ROOT/name),'wb') as out:
        out.setparams((1,2,RATE,0,'NONE','not compressed'))
        out.writeframes(b''.join(struct.pack('<h',round(max(-1,min(1,x*gain))*32767)) for x in values))
    print(name,len(values),round(peak*gain,4))
sea=[]; low=0.0; mid=0.0
for i in range(RATE*8):
    t=i/RATE
    n=rng.uniform(-1,1)
    low+=0.025*(n-low);mid+=0.18*(n-mid)
    swell=0.22+0.7*math.sin(math.pi*t/8)**2
    edge=min(1,t/0.2,(8-t)/0.2)
    sea.append((low*1.8+mid*0.35)*swell*edge)
save('waves.wav',sea)
save('electronic.wav',[(math.sin(2*math.pi*(880 if i<RATE*.075 else 1320)*i/RATE)*0.30)*min(1,i/(RATE*.005))*math.exp(-i/RATE*15) for i in range(int(RATE*.22))])
save('hit.wav',[(rng.uniform(-1,1)*0.5*math.exp(-i/RATE*40)+math.sin(2*math.pi*(150*i/RATE-90*(i/RATE)**2))*0.6*math.exp(-i/RATE*17))*min(1,i/(RATE*.001)) for i in range(int(RATE*.30))])
