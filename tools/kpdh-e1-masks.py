import numpy as np, json, colorsys
from PIL import Image, ImageFilter
from scipy import ndimage
OUT='/home/claude/my-pretty-pulls/cards'
cards=json.load(open('/home/claude/kimg/kcards.json'))
key=lambda n:n.lower().replace('◇cr','crp')
def ks(rar): return [key(c['num']) for c in cards if c['set']=='KPDH01' and c['rar']==rar and 'e1' in c['eds']]
def load(k):
    a=np.asarray(Image.open(f'{OUT}/{k}-l.webp').convert('RGB')).astype(float)/255
    mx=a.max(2); mn=a.min(2); sat=np.where(mx>0,(mx-mn)/np.maximum(mx,1e-6),0)
    r,g,b=a[...,0],a[...,1],a[...,2]
    hue=np.degrees(np.arctan2(np.sqrt(3)*(g-b),2*r-g-b))%360
    lum=.3*r+.59*g+.11*b
    return a,hue,sat,mx,lum
def save(k,mask,name,blur=1.2):
    size=Image.open(f'{OUT}/{k}-s.webp').size
    m=Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.GaussianBlur(blur)).resize(size,Image.LANCZOS)
    o=Image.new('RGBA',size,(255,255,255,0)); o.putalpha(m); o.save(f'{OUT}/{k}-{name}.webp',lossless=True)
from PIL import ImageDraw
def rect(W,H,bw,bh,box,r=0):
    m=Image.new('L',(W,H),0); ImageDraw.Draw(m).rounded_rectangle([box[0]*W/bw,box[1]*H/bh,box[2]*W/bw,box[3]*H/bh],radius=r*W/bw,fill=255); return np.asarray(m)>0
for k in ks('SE'):
    a,h,s_,v,l=load(k); H,W=a.shape[:2]
    inner=rect(W,H,733,1028,(80,155,655,925),30) if H>W else rect(W,H,1028,733,(238,52,968,668),30)
    goldhue=(h>28)&(h<64)&(s_>.28)&(v>.45)
    gold=goldhue&~inner                              # frame, GOLDEN lettering, ornaments
    back=inner&(h>10)&(h<62)&(s_>.5)&(v>.4)          # the glow behind the girls
    gold=ndimage.binary_opening(gold,iterations=1); back=ndimage.binary_opening(back,iterations=2)
    save(k,gold,'m'); save(k,back,'m2',2)
for k in ks('SP'):
    a,h,s,v,l=load(k)
    col=(s>.28)&(l>.30)&(v>.35)                     # every colour, not black, white or the dark flat purples
    col=ndimage.binary_opening(col,iterations=1)
    save(k,col,'m',.8)
for k in ks('LR'):
    a,h,s,v,l=load(k)
    W=a.shape[1]; f=W/733
    sd=np.sqrt(np.maximum(ndimage.uniform_filter(l*l,int(15*f))-ndimage.uniform_filter(l,int(15*f))**2,0))
    dark=l<.22
    back=dark&(sd>.035)                              # the patterned black background (hats and clothes are flat black)
    back=ndimage.binary_closing(back,iterations=2)&dark
    skin=(a[...,0]>.55)&(a[...,1]>.42)&(a[...,2]>.38)&((a[...,0]-a[...,2])<.28)&((a[...,0]-a[...,2])>.07)&(s<.35)
    det=(~dark)&~skin&(l>.55)&(s<.4)                # silver lettering, chains, jewellery, white paper edges
    det=ndimage.binary_opening(det,iterations=1)
    # red chains running across the black background (and over the red paper edges)
    red=((h<22)|(h>335))&(s>.45)&(v>.3)
    near=ndimage.binary_dilation(back,iterations=int(10*f))
    loc=ndimage.uniform_filter(l,int(25*f))
    chain=red&near&(l>loc-.02)
    chain=ndimage.binary_opening(chain,iterations=1)
    chain=chain&~ndimage.binary_dilation(ndimage.binary_erosion(chain,iterations=int(4*f)),iterations=int(7*f))   # keep thin links, drop jackets and paper
    lab,n=ndimage.label(chain); sz=ndimage.sum(chain,lab,range(1,n+1)); chain=np.isin(lab,1+np.where(sz>30*f*f)[0])
    save(k,back,'m',1); save(k,det,'m2',1); save(k,chain,'m3',1)
print('ok')
