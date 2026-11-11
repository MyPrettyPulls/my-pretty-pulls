import asyncio,json
from playwright.async_api import async_playwright
MOCK=open('/home/claude/gtest/mock.js').read()
async def main():
  async with async_playwright() as p:
    b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--no-sandbox"]); pg=await b.new_page()
    async def rt(r):
      u=r.request.url
      if "supabase-js" in u: await r.fulfill(body=MOCK,content_type="application/javascript")
      elif u.startswith("http://localhost"): await r.continue_()
      else: await r.abort()
    await pg.route("**/*",rt); await pg.goto("http://localhost:8765/index.html"); await pg.wait_for_timeout(800)
    d=await pg.evaluate("""()=>({
      cards:Object.values(FRANCH).flatMap(f=>f.cards).map(c=>({uid:c.uid,fr:c.fr,set:c.set,rar:c.rar,eds:c.editions,ap:c.appears,name:c.name})),
      merch:MERCH.map(m=>({uid:m.uid,fr:m.fr,prod:m.prod,prodName:m.prodName,name:m.name,secret:m.secret})),
      rinfo:Object.fromEntries(Object.entries(RINFO).map(([k,v])=>[k,v.name])),
      groups:Object.fromEntries(Object.values(FRANCH).map(f=>[f.id,f.groups.map(g=>({label:g.label||g.name,chars:g.chars}))])),
      eds:Object.fromEntries(Object.values(FRANCH).map(f=>[f.id,f.editions.map(e=>({id:e.id,name:e.name,series:e.series||''}))]))})""")
    json.dump(d,open('/tmp/carddata.json','w'))
    await b.close()
asyncio.run(main())
