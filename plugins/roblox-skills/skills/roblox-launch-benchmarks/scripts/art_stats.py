import json, os, colorsys, statistics as st
from PIL import Image, ImageFilter, ImageStat
d=json.load(open('bench.json'))
def stats(p):
    im=Image.open(p).convert('RGB'); im.thumbnail((256,256))
    px=list(im.getdata()); n=len(px)
    hsv=[colorsys.rgb_to_hsv(r/255,g/255,b/255) for r,g,b in px]
    sat=sum(h[1] for h in hsv)/n; val=sum(h[2] for h in hsv)/n
    lum=[0.2126*r+0.7152*g+0.0722*b for r,g,b in px]; con=st.pstdev(lum)/255
    # center vs edge brightness (subject in center / vignette)
    w,h=im.size; c=im.crop((w//4,h//4,3*w//4,3*h//4)); ce=ImageStat.Stat(c.convert('L')).mean[0]; al=ImageStat.Stat(im.convert('L')).mean[0]
    edges=im.convert('L').filter(ImageFilter.FIND_EDGES); ed=ImageStat.Stat(edges).mean[0]/255
    # distinct hue buckets with >=8% share (palette size)
    b={}
    for hh,ss,vv in hsv:
        if ss>0.25 and vv>0.2: b[int(hh*12)%12]=b.get(int(hh*12)%12,0)+1
    pal=sum(1 for v in b.values() if v/n>=0.08)
    return dict(sat=sat,val=val,con=con,center_minus_all=(ce-al)/255,edge=ed,hues=pal)
def agg(kind):
    rows=[]
    for u,v in d.items():
        files=[f for f in os.listdir(f'{kind}') if f.startswith(u+('_' if kind=='thumbs' else '.'))]
        if files: rows.append(stats(f'{kind}/{files[0]}'))
    print('==',kind,len(rows))
    for k in rows[0]:
        xs=sorted(r[k] for r in rows); q=lambda p: xs[int(p*(len(xs)-1))]
        print(f' {k}: p10={q(.1):.2f} med={q(.5):.2f} p90={q(.9):.2f}')
agg('icons'); agg('thumbs')
