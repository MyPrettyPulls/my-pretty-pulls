import numpy as np, json
from PIL import Image, ImageDraw, ImageFilter
OUT='/home/claude/my-pretty-pulls/cards'
info={}
for i in range(1,25):
    k=f'kpdh01-r-{i:03d}'
    L=Image.open(f'{OUT}/{k}-l.webp').convert('RGB'); a=np.asarray(L).astype(int); H,W,_=a.shape
    sx,sy=W/733,H/1028
    top=a[int(20*sy),W//2]; bot=a[H-int(40*sy),int(600*sx)]
    pink=top[0]>top[2]+20
    yy,xx=np.mgrid[0:H,0:W]
    band=np.zeros((H,W),bool)
    band|=(yy<int(60*sy))&(np.abs(a-top).sum(2)<60)
    band|=(yy>H-int(175*sy))&((np.abs(a-bot).sum(2)<60)|(np.abs(a-top).sum(2)<60))
    from scipy import ndimage
    band=ndimage.binary_fill_holes(ndimage.binary_closing(band,iterations=5))
    # holo rings around the round "story" pictures, plus the LIVE badges
    ring=Image.new('L',(W,H),0); d=ImageDraw.Draw(ring)
    for cx in (220,366,513):
        d.ellipse([(cx-58)*sx,(113-58)*sy,(cx+58)*sx,(113+58)*sy],fill=255); d.ellipse([(cx-46)*sx,(113-46)*sy,(cx+46)*sx,(113+46)*sy],fill=0)
    d.ellipse([(82-44)*sx,(918-44)*sy,(82+44)*sx,(918+44)*sy],fill=255); d.ellipse([(82-35)*sx,(918-35)*sy,(82+35)*sx,(918+35)*sy],fill=0)
    d.rounded_rectangle([168*sx,146*sy,270*sx,178*sy],radius=14*sx,fill=255)
    d.rounded_rectangle([48*sx,943*sy,116*sx,968*sy],radius=10*sx,fill=255)
    ring=np.asarray(ring)>0
    holo=ring|(band if not pink else False)
    shine=band if pink else np.zeros_like(band)
    S=Image.open(f'{OUT}/{k}-s.webp'); size=S.size
    def save(mask,name):
        m=Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.GaussianBlur(1.2)).resize(size,Image.LANCZOS)
        rgba=Image.new('RGBA',size,(255,255,255,0)); rgba.putalpha(m); rgba.save(f'{OUT}/{k}-{name}.webp',lossless=True)
    save(holo,'m')
    if pink: save(shine,'m2')
    info[k]='pink' if pink else 'purple'
json.dump(info,open('/home/claude/fxwork/rinfo.json','w')); print(info)
# preview: masks tinted over a purple and a pink card
for k in ('kpdh01-r-001','kpdh01-r-003'):
    S=Image.open(f'{OUT}/{k}-s.webp').convert('RGBA')
    m=Image.open(f'{OUT}/{k}-m.webp').getchannel('A'); ov=Image.new('RGBA',S.size,(0,255,120,0)); ov.putalpha(m.point(lambda v:v*0.8))
    out=Image.alpha_composite(S,ov)
    try:
        m2=Image.open(f'{OUT}/{k}-m2.webp').getchannel('A'); ov2=Image.new('RGBA',S.size,(255,200,0,0)); ov2.putalpha(m2.point(lambda v:v*0.8)); out=Image.alpha_composite(out,ov2)
    except FileNotFoundError: pass
    out.save(f'/home/claude/shots/mask-{k}.png')
