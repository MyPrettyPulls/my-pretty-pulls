# Writes both trivia question banks from the sheet (exported to JSON)
import json
q=lambda s:"$t$"+s.strip()+"$t$"
out=""
for fr,f in (("winx","winx.json"),("kpdh","kpdh.json")):
    rows=json.load(open('/home/claude/games/'+f))[1:]
    rows=[r for r in rows if len(r)>=6 and r[0].strip() and not r[0].startswith("EXAMPLE")]
    out+=f"update public.trivia_questions set active = false where fr = '{fr}';\n"
    for r in rows:
        out+=(f"insert into public.trivia_questions (question, answer, wrong, difficulty, fact, active, fr) values ({q(r[0])}, {q(r[1])}, array[{q(r[2])},{q(r[3])},{q(r[4])}], '{r[5].strip()}', null, true, '{fr}')"
              " on conflict (question) do update set answer = excluded.answer, wrong = excluded.wrong, difficulty = excluded.difficulty, fact = null, active = true, fr = excluded.fr;\n")
    print(fr,len(rows))
open('/home/claude/games/part-trivia.sql','w').write(out)
