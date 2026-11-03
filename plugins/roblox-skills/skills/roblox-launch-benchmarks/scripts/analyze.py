import json, collections, re, datetime, sys
d=json.load(open('bench.json'))
sorts={}
for s in ['top-playing-now','top-trending','up-and-coming']:
    for g in json.load(open(s+'.json'))['games']: sorts[str(g['universeId'])]=g
now=datetime.datetime.now(datetime.timezone.utc)
rows=[]
for u,v in d.items():
    if 'detail' not in v: continue
    x=v['detail']; g=sorts.get(u,{})
    ps=[p['price'] for p in v['passes'].get('gamePasses',[]) if p.get('price') and p.get('isForSale')]
    cr=datetime.datetime.fromisoformat(x['created'].replace('Z','+00:00'))
    uv,dv=g.get('totalUpVotes',0),g.get('totalDownVotes',0)
    rows.append(dict(maxp=x['maxPlayers'],age=(now-cr).days,thumbs=v.get('thumbs') or 0,np=len(ps),prices=ps,like=(uv/(uv+dv)) if uv+dv else 0,desc=len(x['description'] or ''),genreL1=g.get('genreL1'),mat=g.get('contentMaturity')))
def q(a,p): a=sorted(a); return a[min(len(a)-1,int(len(a)*p))] if a else None
def summ(label,rs):
    print(f'== {label} n={len(rs)}')
    for k in ['maxp','thumbs','np','desc','age']:
        a=[r[k] for r in rs]; print(f' {k}: p10={q(a,.1)} med={q(a,.5)} p90={q(a,.9)}')
    lk=[r['like'] for r in rs if r['like']]; print(f' like: p10={q(lk,.1)} med={q(lk,.5)} p90={q(lk,.9)}')
    allp=[p for r in rs for p in r['prices']]; print(f' pass price n={len(allp)} p10={q(allp,.1)} med={q(allp,.5)} p90={q(allp,.9)}')
    print(' top price points',collections.Counter(allp).most_common(10))
    print(' genreL1',collections.Counter(r['genreL1'] for r in rs).most_common(8))
    print(' maturity',collections.Counter(r['mat'] for r in rs).most_common(4))
    print(' zero-pass games',sum(r['np']==0 for r in rs))
summ('all',rows); summ('young<=120d',[r for r in rows if r['age']<=120]); summ('old',[r for r in rows if r['age']>120])
