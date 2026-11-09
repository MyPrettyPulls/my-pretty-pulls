# Masks for Classic Edition Series 1 card effects. Coordinates are on a 733x1028 card (ZR: 1028x733) and scaled.
import numpy as np, json, sys
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage
OUT='/home/claude/my-pretty-pulls/cards'
cards=json.load(open('/home/claude/kimg/kcards.json'))
key=lambda n:n.lower().replace('◇cr','crp')
made={}
def load(k):
    L=Image.open(f'{OUT}/{k}-l.webp').convert('RGB'); return L,np.asarray(L).astype(int)
def rects(W,H,bw,bh,boxes,round_=0):
    m=Image.new('L',(W,H),0); d=ImageDraw.Draw(m); sx,sy=W/bw,H/bh
    for b in boxes: d.rounded_rectangle([b[0]*sx,b[1]*sy,b[2]*sx,b[3]*sy],radius=round_*sx,fill=255)
    return np.asarray(m)>0
def save(k,mask,name,blur=1.2):
    S=Image.open(f'{OUT}/{k}-s.webp'); size=S.size
    m=Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.GaussianBlur(blur)).resize(size,Image.LANCZOS)
    rgba=Image.new('RGBA',size,(255,255,255,0)); rgba.putalpha(m); rgba.save(f'{OUT}/{k}-{name}.webp',lossless=True)
    made.setdefault(k,[]).append(name)
lum=lambda a:a[...,0]*.3+a[...,1]*.59+a[...,2]*.11
def c1(rar): return [key(c['num']) for c in cards if c['set']=='KPDH01' and c['rar']==rar and 'c1' in c['eds']]

for k in c1('SR'):
    L,a=load(k); H,W,_=a.shape
    pop=rects(W,H,733,1028,[(38,38,192,128),(92,176,210,294),(548,288,636,376),(42,732,505,815),(598,806,712,916),(150,905,282,1018),(305,905,430,1020),(455,905,582,1018)],12)
    silver=rects(W,H,733,1028,[(505,24,712,274)],22)
    frame=~rects(W,H,733,1028,[(62,44,652,895)])
    edge=frame&~pop&~silver
    save(k,pop,'m'); save(k,silver,'m2'); save(k,edge,'m3')
for k in c1('SSR'):
    L,a=load(k); H,W,_=a.shape
    save(k,rects(W,H,733,1028,[(0,38,506,1028)],8),'m',2)
for k in c1('UR'):
    L,a=load(k); H,W,_=a.shape; l=lum(a)
    sat=a.max(2)-a.min(2)
    # gold signature (character name): on dark cards the gold ink, on light cards the dark ink
    sig=rects(W,H,733,1028,[(400,790,733,1000)])
    bg=l[sig].mean()
    ink=((a[...,0]>150)&(a[...,1]>105)&(a[...,2]<120)&(a[...,0]-a[...,2]>70)) if bg<150 else (l<bg-55)
    name=sig&ink; name=ndimage.binary_dilation(name,iterations=2)
    # white outlines on the group name, song titles and the little stickers
    white=(a.min(2)>222)&(sat<26)
    zone=rects(W,H,733,1028,[(0,0,733,250),(0,700,733,940)])|~rects(W,H,733,1028,[(110,250,650,700)])
    out=white&zone&~rects(W,H,733,1028,[(0,935,733,1028)])
    # drop large white areas (pale backgrounds), keep thin outlines
    lab,n=ndimage.label(out); sizes=ndimage.sum(out,lab,range(1,n+1))
    thick=ndimage.binary_erosion(out,iterations=4)
    out=out&~ndimage.binary_dilation(thick,iterations=5)
    save(k,name,'m2',1); save(k,out,'m3',1)
for k in c1('ZR'):
    L,a=load(k); H,W,_=a.shape; l=lum(a); f=W/1028
    loc=ndimage.uniform_filter(l,size=int(31*f))
    lines=(loc<130)&(l>loc+22)
    # the background is where the contour lines are packed close together; the character is smooth
    dens=ndimage.uniform_filter(lines.astype(float),size=int(61*f))
    back=ndimage.binary_closing(dens>.09,iterations=int(8*f)); back=ndimage.binary_opening(back,iterations=int(10*f))
    save(k,lines&back,'m',.8)
    # demon markings: thin glowing lines on the character (only cards where Jinu shows his markings)
    if k in ('kpdh01-zr-006','kpdh01-zr-008'):
        loc2=ndimage.uniform_filter(l,size=int(21*f))
        glow=(l>loc2+20)&(a[...,2]>a[...,0]+10)&(a[...,2]>110)
        mark=glow&~back
        mark=ndimage.binary_opening(mark,iterations=1); mark=ndimage.binary_dilation(mark,iterations=1)
        lab,n=ndimage.label(mark); sz=ndimage.sum(mark,lab,range(1,n+1)); mark=np.isin(lab,1+np.where(sz>25)[0])
        save(k,mark,'m2',1)
json.dump(made,open('/home/claude/fxwork/c1made.json','w')); print({k:v for k,v in list(made.items())[:3]}, len(made))
