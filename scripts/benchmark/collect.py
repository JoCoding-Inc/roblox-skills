import json, urllib.request, time
def get(u):
    for i in range(3):
        try:
            return json.load(urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent':'Mozilla/5.0'}), timeout=20))
        except Exception as e:
            err=str(e); time.sleep(1.5)
    return {'error':err}
ids=[]; src={}
for s,n in [('top-playing-now',40),('top-trending',30),('up-and-coming',30)]:
    for g in json.load(open(s+'.json'))['games'][:n]:
        if g['universeId'] not in src: ids.append(g['universeId']); src[g['universeId']]=[]
        src[g['universeId']].append(s)
out={}
for i in range(0,len(ids),50):
    chunk=ids[i:i+50]
    q=','.join(map(str,chunk))
    det=get('https://games.roblox.com/v1/games?universeIds='+q)
    for d in det.get('data',[]): out[d['id']]={'detail':d,'src':src[d['id']]}
    th=get('https://thumbnails.roblox.com/v1/games/multiget/thumbnails?countPerUniverse=10&defaults=false&size=768x432&format=Png&universeIds='+q)
    for t in th.get('data',[]):
        out.setdefault(t['universeId'],{})['thumbs']=len(t.get('thumbnails',[]))
for u in ids:
    p=get(f'https://apis.roblox.com/game-passes/v1/universes/{u}/game-passes?passView=Full&pageSize=100')
    out.setdefault(u,{})['passes']=p
    dp=get(f'https://apis.roblox.com/developer-products/v2/universes/{u}/developer-products?pageSize=100')
    out[u]['products']=dp
    time.sleep(0.15)
json.dump(out,open('bench.json','w'))
print(len(out))
