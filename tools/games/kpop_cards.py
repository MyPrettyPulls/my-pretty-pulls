# Writes the KPop card + blurry-preview part of the games SQL
import json
from PIL import Image
OUT='/home/claude/my-pretty-pulls/cards'
cards=json.load(open('/home/claude/kimg/kcards2.json'))
q=lambda s:"$q$"+s+"$q$"
arr=lambda xs:"array["+",".join(q(x) for x in xs)+"]::text[]"
rows=[];mos=[]
for c in cards:
    n=int(c['num'].rsplit('-',1)[1])
    rows.append(f"({q(c['uid'])},{q(c['num'])},{n},{q(c['rar'])},{arr(c['eds'])},{q(c['name'])},{q(c['main']) if c['main'] else 'null'},{arr(c['appears'])},'kpdh')")
    if not c['img']: continue
    im=Image.open(f"{OUT}/{c['img']}-l.webp").convert('RGB'); land=im.size[0]>im.size[1]
    for lv,(w,h) in ((1,(3,4)),(2,(5,7)),(3,(8,11))):
        if land: w,h=h,w
        px=im.resize((w,h),Image.BOX).tobytes().hex()
        mos.append(f"({q(c['uid'])},{lv},{w},{h},'{px}')")
sql="delete from public.game_cards where fr = 'kpdh';\n"
sql+="insert into public.game_cards (uid, num, n, rar, editions, name, main, appears, fr) values\n"+",\n".join(rows)+";\n"
sql+="insert into public.game_mosaics (uid, level, w, h, px) values\n"+",\n".join(mos)+";\n"
open('/home/claude/games/part-cards.sql','w').write(sql); print(len(rows),len(mos))
