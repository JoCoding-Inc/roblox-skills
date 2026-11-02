import json, urllib.request, os, time
d=json.load(open('bench.json'))
ids=list(d)
def get(u):
    for _ in range(3):
        try: return urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'Mozilla/5.0'}),timeout=30).read()
        except Exception as e: time.sleep(1)
    return None
icons={}
for i in range(0,len(ids),50):
    b=ids[i:i+50]
    r=json.loads(get("https://thumbnails.roblox.com/v1/games/icons?universeIds="+",".join(b)+"&size=512x512&format=Png&isCircular=false"))
    for x in r["data"]: icons[str(x["targetId"])]=x.get("imageUrl")
thumbs={}
for i in range(0,len(ids),25):
    b=ids[i:i+25]
    r=json.loads(get("https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds="+",".join(b)+"&countPerUniverse=3&size=768x432&format=Png&isCircular=false"))
    for x in r["data"]: thumbs[str(x["universeId"])]=[t["imageUrl"] for t in x["thumbnails"] if t.get("imageUrl")]
os.makedirs('icons',exist_ok=True); os.makedirs('thumbs',exist_ok=True)
for u in ids:
    if icons.get(u):
        b=get(icons[u]); 
        if b: open(f'icons/{u}.png','wb').write(b)
    for n,t in enumerate(thumbs.get(u,[])[:1]):
        b=get(t)
        if b: open(f'thumbs/{u}_{n}.png','wb').write(b)
print(len(os.listdir('icons')),len(os.listdir('thumbs')))
