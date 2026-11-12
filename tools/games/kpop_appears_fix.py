# Who is on each KPop card whose name doesn't say (scene cards, screenshots, album cards...).
# Checked card by card from the pictures. "Demons" and "Fans" are labels for the "Other" question, not characters.
import json
T=["Rumi","Mira","Zoey"]; S=["Jinu","Abby","Baby","Mystery","Romance"]
A={
 # Series 1 Rare (social posts)
 "KPDH01-R-001":T,"KPDH01-R-002":["Rumi","Derpy"],"KPDH01-R-003":["Rumi","Jinu"],"KPDH01-R-006":T,"KPDH01-R-007":T+["Fans"],
 "KPDH01-R-008":T,"KPDH01-R-009":T,"KPDH01-R-010":T+["Demons"],"KPDH01-R-011":T,"KPDH01-R-013":S,"KPDH01-R-016":T,"KPDH01-R-017":T,
 "KPDH01-R-019":["Fans"],"KPDH01-R-020":S,"KPDH01-R-021":["Demons"],"KPDH01-R-022":T,"KPDH01-R-023":T,"KPDH01-R-024":["Rumi"],
 # Series 1 SR demons
 "KPDH01-SR-016":["Demons"],"KPDH01-SR-017":["Demons"],"KPDH01-SR-018":["Demons"],
 # Series 1 HR (movie moments)
 "KPDH01-HR-001":["Mira","Zoey"],"KPDH01-HR-002":["Rumi"],"KPDH01-HR-003":["Zoey"],"KPDH01-HR-004":["Mira"],"KPDH01-HR-006":T,
 "KPDH01-HR-007":["Fans"],"KPDH01-HR-009":T,"KPDH01-HR-010":S,"KPDH01-HR-011":["Rumi"],"KPDH01-HR-012":T,"KPDH01-HR-013":["Mira","Zoey"],
 "KPDH01-HR-019":["Rumi","Demons"],"KPDH01-HR-023":["Mira"],"KPDH01-HR-024":["Zoey"],
 # Series 1 QR demon charms
 "KPDH01-QR-016":["Demons"],"KPDH01-QR-019":["Demons"],
 # Special Mini SSR
 "KPDHM01-SSR-001":T,"KPDHM01-SSR-002":T,"KPDHM01-SSR-003":T,"KPDHM01-SSR-004":["Rumi"],"KPDHM01-SSR-005":["Zoey"],
 "KPDHM01-SSR-010":T,"KPDHM01-SSR-014":["Mira","Zoey"],"KPDHM01-SSR-015":["Mira","Zoey"],
 # Series 2
 "KPDH02-R-003":["Fans"],"KPDH02-R-011":[],
 "KPDH02-SR-011":["Demons"],"KPDH02-SR-012":["Demons"],"KPDH02-SR-013":["Demons"],"KPDH02-SR-014":["Demons"],"KPDH02-SR-015":["Demons"],
 "KPDH02-HR-001":["Rumi"],"KPDH02-HR-002":S,"KPDH02-HR-003":["Zoey"],"KPDH02-HR-004":T,"KPDH02-HR-005":T,"KPDH02-HR-006":["Rumi"],
 "KPDH02-HR-007":["Mira"],"KPDH02-HR-008":["Zoey"],"KPDH02-HR-009":["Mira"],"KPDH02-HR-010":["Rumi"],"KPDH02-HR-011":["Rumi","Mira"],
 "KPDH02-HR-012":["Mira"],"KPDH02-HR-013":["Rumi"],"KPDH02-HR-014":["Zoey"],"KPDH02-HR-015":["Rumi"],"KPDH02-HR-016":["Rumi"],
 "KPDH02-HR-017":["Jinu"],"KPDH02-HR-018":["Rumi"],"KPDH02-HR-019":["Jinu"],"KPDH02-HR-020":["Jinu","Rumi"],"KPDH02-HR-021":["Mystery","Zoey"],
 "KPDH02-HR-022":["Romance","Mira","Abby"],"KPDH02-HR-023":T,"KPDH02-HR-024":["Rumi"],
 "KPDH02-QR-001":["Jinu"],"KPDH02-QR-002":["Baby"],"KPDH02-QR-003":["Mystery"],"KPDH02-QR-004":["Romance"],"KPDH02-QR-005":["Abby"],
 "KPDH02-QR-009":["Jinu"],"KPDH02-QR-010":["Abby"],"KPDH02-QR-011":["Baby"],"KPDH02-QR-012":["Romance"],"KPDH02-QR-013":["Mystery"],
 "KPDH02-QR-014":["Rumi"],"KPDH02-QR-015":["Mira"],"KPDH02-QR-016":["Zoey"],"KPDH02-QR-017":["Rumi"],"KPDH02-QR-018":["Mira"],"KPDH02-QR-019":["Zoey"],
 "KPDH02-TR-016":["Fans"],"KPDH02-TR-017":["Fans"],"KPDH02-TR-018":["Fans"],
}
# The cards that were hard to tell from the picture were checked by Kinsey (sheet tab "KPop Characters to Check", Nov 2026)
UNSURE=[]
OTHER=["Celine","Bobby","Healer Han","Derpy","Sussie","Demons","Fans"]
if __name__=="__main__":
  d=json.load(open('/tmp/carddata.json'))
  empty={c['uid'].split('|')[0] for c in d['cards'] if c['fr']=='kpdh' and not c['ap']}
  assert set(A)==empty, (sorted(empty-set(A)), sorted(set(A)-empty))
  q=lambda s:"'"+s.replace("'","''")+"'"
  arr=lambda xs:"array["+",".join(q(x) for x in xs)+"]::text[]" if xs else "'{}'::text[]"
  real=lambda xs:[x for x in xs if x not in("Demons","Fans")]
  sql=["-- My Pretty Pulls: who's on each KPop scene card, and the HUNTR/X / Saja Boys / Other question. Safe to run again.",
       "begin;"]
  for num,xs in sorted(A.items()):
    main=q(real(xs)[0]) if len(xs)==1 and real(xs) else "null"
    sql.append(f"update public.game_cards set appears={arr(xs)}, main={main} where split_part(uid,'|',1)={q(num)};")
    sql.append(f"update public.badge_cards set ap={arr(xs)} where split_part(uid,'|',1)={q(num)};")
  open('/tmp/kc/updates.sql','w').write("\n".join(sql)+"\n")
  js="const K_APPEARS_NUM="+json.dumps(A,separators=(",",":"))+";"
  open('/tmp/kc/appears.js','w').write(js)
  print(len(A),"cards;",len(js),"chars of JS")
