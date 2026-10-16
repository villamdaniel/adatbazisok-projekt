# Relációs modell, normalizálás, integritás

## Relációk

Az elsődleges kulcs azonosító, kivéve a diagnózis kódját és a két összekötő tábla összetett kulcsát. Az idegen kulcs oszlopa a cél elsődleges kulcsára mutat.

| Reláció | Elsődleges kulcs | Fontos idegen kulcs | Törlés |
| --- | --- | --- | --- |
| osztaly | osztaly_id | vezeto_orvos_id | vezető törlésekor a hivatkozás NULL |
| alkalmazott | alkalmazott_id | | korlátozott |
| orvos | alkalmazott_id | osztaly_id | korlátozott |
| apolo | alkalmazott_id | osztaly_id | korlátozott |
| korterem | korterem_id | osztaly_id | korlátozott |
| agy | agy_id | korterem_id | korlátozott |
| beteg | beteg_id | | korlátozott |
| diagnozis | kod | | korlátozott, kódváltáskor kaszkád |
| felvetel | felvetel_id | beteg_id, agy_id, felvevo_orvos_id | korlátozott |
| felvetel_diagnozis | (felvetel_id, diagnozis_kod) | mindkét rész | a felvétel törlésekor a sor is megy |
| vizit | vizit_id | beteg_id, orvos_id | korlátozott |
| gyogyszer | gyogyszer_id | | korlátozott |
| veny | veny_id | beteg_id, orvos_id, vizit_id vagy felvetel_id | korlátozott |
| veny_tetel | veny_tetel_id | veny_id, gyogyszer_id | a vény törlésekor a tétel is megy |
| keszlet_mozgas | mozgas_id | gyogyszer_id, veny_tetel_id | korlátozott, és trigger is tiltja |
| labor_tipus | tipus_id | | korlátozott |
| labor_lelet | lelet_id | beteg_id, kert_orvos_id, tipus_id | korlátozott |
| szolgaltatas | szolgaltatas_id | | korlátozott |
| szamla | szamla_id | beteg_id | korlátozott |
| szamla_tetel | tetel_id | szamla_id, szolgaltatas_id | a számla törlésekor a tétel is megy |
| fizetes | fizetes_id | szamla_id | korlátozott |
| audit_naplo | naplo_id | | a napló nem hivatkozik vissza |

A korlátozott törlés tudatos: beteg, felvétel és számla nem tűnhet el azért, mert valaki kitöröl egy törzsadatot. A tétel jellegű sorok a szülővel együtt mennek, mert nélkülük nincs jelentésük.

## Normálformák

**1NF.** Minden oszlop egy érték. Nincs „diagnózisok” felsorolás egy mezőben, nincs ismétlődő gyógyszercsoport a vényen. A több diagnózis és a több vénytétel külön sor.

**2NF.** Ahol a kulcs összetett (`felvetel_diagnozis`), a típus a teljes kulcstól függ, nem az egyik felétől. A többi reláció kulcsa egy azonosító, ezért részleges függés nincs.

**3NF.** Nincs olyan nem kulcs oszlop, amely egy másik nem kulcs oszloptól függ.

- A beteg neve nem kerül rá a számlára és a leletre. Mindkettő a `beteg_id`-n keresztül éri el.
- A labor mértékegysége és a referenciatartomány a típusnál van, a leleten csak az eredmény.
- Az osztály neve nincs az orvos során, csak `osztaly_id`.
- A viziten és a felvételen nincs osztály. Az előbbi az orvosé, az utóbbi az ágyé. Ha mindkettőt tárolnánk, a két érték szétcsúszhatna.

**BCNF.** A függések bal oldala kulcs. A TAJ a beteget meghatározza, és egyben kulcs is (egyedi). A pecsétszám ugyanígy kulcs az orvosnál. Olyan függés nincs, amelynek a bal oldala nem kulcs.

### A számlatétel ára miért van mégis a tételen

A `szolgaltatas.netto_egysegar` a mai katalógusár. A `szamla_tetel.netto_egysegar` az a tény, amennyiért a tételt kiállították. A kettő ugyanabból a számításból indul, de utána külön életet él. Ha ezt nem másolnánk le, egy árlista-módosítás átírná a régi számlákat. Ez nem normalizálási hiba, hanem a tranzakció pillanatának megőrzése. Ugyanezért van a tételen a megnevezés is.

A bruttó nem tárolt döntés: generált oszlop, a mennyiség, a nettó ár és az áfakulcs meghatározza.

### Altípus egy tábla helyett

Egyetlen `alkalmazott` táblában a pecsétszám és az oklevélszám a sorok felén NULL lenne, és egy CHECK-kel kellene őrizni, hogy orvosnál a pecsét ki van töltve, ápolónál pedig nincs. Az altípus ezt a feltételt a tábla létével mondja ki. Az árnyoldala, hogy az „orvos és ápoló egyszerre” szabályt triggernek kell kimondania.

## Megszorítások, és miért ott vannak

| Szabály | Hol él | Miért nem elég egy másik eszköz |
| --- | --- | --- |
| TAJ ellenőrző jegy | `dom_taj` tartomány | A függvény `IMMUTABLE`, ezért CHECK-ben használható. |
| E-mail forma | `dom_email` | Egy helyen van, betegnél és dolgozónál is. |
| Státuszok, áfakulcs, pozitív összeg | CHECK | A trigger kikapcsolható, a CHECK a tábláé. |
| Aktív felvétel ideje nyitott, a lezárté zárt | CHECK | Az állapot és a dátum együtt érvényes. |
| Beteg és ágy felvételei nem fedik egymást | kizáró megszorítás, GiST | A részleges egyedi index csak az aktív sort védi. A kizáró megszorítás a múltbeli, átfedő időszakot is. |
| Orvos rendelései nem ütköznek | részleges kizáró megszorítás | A `lemondott` és a `nem_jelent_meg` kint marad a feltételből. A tartomány félig nyílt, az egymás utáni rendelés szabad. |
| Egy fődiagnózis | részleges egyedi index, és halasztott constraint trigger | Az index a „legfeljebb egy”. A trigger a „legalább egy”, de csak a tranzakció végén, hogy a felvétel és a diagnózis két utasítás lehessen. |
| Egy aktív felvétel betegenként és ágyanként | részleges egyedi index | Olvashatóbb hiba, a kizáró megszorítás mellett második zár. |
| Karbantartott ágy, osztály, 18 év | BEFORE trigger | Több tábla állapotától függ, CHECK ezt nem látja. |
| Készlet nem negatív, a napló csak bővül | BEFORE trigger | Összesített szabály, és az üzleti mondat az, hogy javítani új sorral lehet. |
| Befizetés nem több a végösszegnél, a számla `fizetve` lesz | BEFORE és AFTER trigger | A végösszeg másik táblában van. |
| Audit | AFTER trigger | A napló a megtörtént művelet másolata. |

A PostgreSQL az idegen kulcsokra nem gyárt indexet. Ezek a `02_indexek.sql` fájlban vannak, külön a keresőindexektől. A névrészlet-keresés trigram indexet használ. A nyitott számlák határidejére részleges index van, mert a lejárt számlát ezen a szűk halmazon keressük.

## Tranzakció

Az eljárások nem hívnak `COMMIT`-ot. A hívó dönti el, hogy a felvétel, az áthelyezés vagy a befizetés végleges-e. A `sql/demo/tranzakciok.sql` ezt mutatja: egy áthelyezés atomi, egy hibás befizetés pedig `SAVEPOINT`-ig gördül vissza, a jó sor megmarad a tranzakción belül, majd a bemutató az egészet visszavonja.

## Jogosultság

Öt csoportszerep van, mindegyikhez egy belépő demo felhasználó. A jogosultság a csoporton van, ezért új pénzügyes felhasználónak elég a csoporttagság.

A recepció nézetet kap, táblát nem. A nézet a tulajdonos jogával fut, és szándékosan nem tartalmaz panaszt. A `vizit` táblán sorvédelem van: az orvos csak azt a sort látja, amelyiknek az `orvos_id`-ja megegyezik az `app.orvos_id` munkamenet-változóval. A tábla tulajdonosa ezt megkerüli. Ez PostgreSQL-sajátosság, a bemutatón ki kell mondani, nem elrejteni.
