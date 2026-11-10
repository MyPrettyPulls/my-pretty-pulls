import numpy as np, json
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage
OUT='/home/claude/my-pretty-pulls/cards'
cards=json.load(open('/home/claude/kimg/kcards.json'))
key=lambda n:n.lower().replace('◇cr','crp')
def ks(rar): return [key(c['num']) for c in cards if c['set']=='KPDH02' and c['rar']==rar]
def load(k):
    a=np.asarray(Image.open(f'{OUT}/{k}-l.webp').convert('RGB')).astype(float)/255
    mx=a.max(2); mn=a.min(2); s=np.where(mx>0,(mx-mn)/np.maximum(mx,1e-6),0)
    r,g,b=a[...,0],a[...,1],a[...,2]; h=np.degrees(np.arctan2(np.sqrt(3)*(g-b),2*r-g-b))%360
    return a,h,s,mx,.3*r+.59*g+.11*b
def box(H,W,x0,y0,x1,y1,ell=False):
    m=Image.new('L',(W,H),0); d=ImageDraw.Draw(m); bb=[x0*W,y0*H,x1*W,y1*H]
    (d.ellipse if ell else d.rectangle)(bb,fill=255); return np.asarray(m)>0
def save(k,mask,name,blur=1.2):
    size=Image.open(f'{OUT}/{k}-s.webp').size
    m=Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.GaussianBlur(blur)).resize(size,Image.LANCZOS)
    o=Image.new('RGBA',size,(255,255,255,0)); o.putalpha(m); o.save(f'{OUT}/{k}-{name}.webp',lossless=True)
for k in ks('SE'):
    a,h,s,v,l=load(k); H,W=l.shape
    person=box(H,W,.33,.14,.72,.86,True)
    f=W/899; mu=ndimage.uniform_filter(l,int(9*f)); sd=np.sqrt(np.maximum(ndimage.uniform_filter(l*l,int(9*f))-mu*mu,0))
    chrome=(s<.25)&(v>.45)&(sd>.07)&~person
    chrome=ndimage.binary_closing(chrome,iterations=2)&(s<.3)
    blue=(h>190)&(h<270)&(s>.2)&~ndimage.binary_dilation(chrome,iterations=3)
    save(k,ndimage.binary_opening(chrome,iterations=1),'m'); save(k,ndimage.binary_opening(blue,iterations=2),'m2',2)
for k in ks('SP'):
    a,h,s,v,l=load(k)
    m=ndimage.binary_opening((s>.28)&(l>.30)&(v>.35),iterations=1)
    if m.mean()<.12:   # softer cream/pastel versions (like SP-004): every tinted colour, still not black or white
        m=ndimage.binary_opening((s>.12)&(l>.25)&(l<.93),iterations=1)
    save(k,m,'m',.8)
for k in ks('BP'):
    a,h,s,v,l=load(k)
    save(k,ndimage.binary_opening((s<.08)&(l>.82),iterations=1),"m",1)   # the silver / white outlines and lines
for k in ks('LR'):
    a,h,s,v,l=load(k); H,W=l.shape
    top=box(H,W,0,0,1,.17)&(h>12)&(h<70)&(s>.4)&(v>.7)
    bot=box(H,W,0,.74,1,.93)&(((h>180)&(h<260)&(s>.25))|((l>.75)&(s<.3)))
    save(k,ndimage.binary_opening(top|bot,iterations=1),'m',1.2)
for k in ks('UR'):
    a,h,s,v,l=load(k); H,W=l.shape
    keep=~(box(H,W,.18,.1,.82,.47,True)|box(H,W,.18,.53,.82,.92,True))|box(H,W,.1,.42,.9,.54)
    f=W/733; mu=ndimage.uniform_filter(l,int(15*f))
    lines=((l>.6)&(s<.3))|((h>230)&(h<300)&(l>.5)&(s<.6))|((mu<.3)&(l>mu+.1))
    save(k,ndimage.binary_opening(lines,iterations=1)&keep,'m',1)
for k in ks('R'):
    a,h,s,v,l=load(k); H,W=l.shape
    save(k,~box(H,W,73/1028,119/733,983/1028,554/733),'m',2)
for k in ks('ZR'):
    a,h,s,v,l=load(k); H,W=l.shape
    save(k,box(H,W,.24,0,1,.17)&(l>.25),'m',1.5)
print('ok')
