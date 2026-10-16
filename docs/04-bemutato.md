# Bemutató

Tíz perc elég. A sorrend a feladat, a modell, egy szabály, egy lekérdezés, egy tranzakció, egy jogosultság.

## Indítás

Dockerrel, üres állapotból:

```powershell
docker compose down -v
docker compose up -d --wait
docker compose exec db psql -U lumen -d lumen_klinika
```

A `-v` lemez nélkül az init szkriptek újra lefutnak, és a `08_ellenorzes.sql` hibával megáll, ha egy szabály elromlott.

Docker nélkül, meglévő PostgreSQL 16-on:

```powershell
psql -U postgres -c "CREATE DATABASE lumen_klinika"
psql -U postgres -d lumen_klinika -v ON_ERROR_STOP=1 -f sql/futtatas.sql
```

A `--single-transaction` kapcsolót ne használd: a mintaadat saját tranzakcióban tölti a felvételt és a diagnózist, mert a fődiagnózis kötelezősége a tranzakció végén fut.

## Mit melyik fájlban kell megmutatni

| Kérdés a védésen | Fájl |
| --- | --- |
| Hol a TAJ és az e-mail? | `sql/init/01_sema.sql` |
| Hol van, hogy két felvétel nem fedheti egymást? | ugyanott, `ex_felvetel_beteg_utkozes` |
| Miért nincs osztály a viziten? | `docs/03-relacios-modell.md` |
| Hol a fődiagnózis „pontosan egy”? | részleges index a `02_indexek.sql`-ben, halasztott trigger a `04_triggerek.sql`-ben |
| Hol csökken a készlet? | `trg_veny_kiadas` |
| Hol lesz a számla fizetve? | `trg_szamla_statusz_fizetesbol` |
| Melyik a támogatott művelet? | `sql/init/05_eljarasok.sql` |
| Hol van a 18 lekérdezés? | `sql/demo/lekerdezesek.sql` |

## Lekérdezések, amiket érdemes élőben futtatni

```powershell
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/lekerdezesek.sql
```

Három elég szóban, a többi a fájlban van:

1. **Q02** kihasználtság. A belgyógyászaton az egyik ágy karbantartás alatt van, és a százalék a karbantartást nem veszi üzemelő ágynak.
2. **Q09** a `LAG` ugyanannál a betegnél mutatja, hány nap telt el két rendelés között.
3. **Q16** a `DISTINCT ON` betegenként a legutóbbi labort adja. Ez PostgreSQL-sajátosság, szabványos megfelelője ablakfüggvény és külső szűrés.

## Tranzakció és jogosultság

```powershell
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/tranzakciok.sql
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/jogosultsag.sql
```

A jogosultságos szkript szándékosan kap egy `permission denied` sort: az olvasó nem éri el a labor táblát. Utána az orvos szerep csak annak az orvosnak a rendeléseit látja, akinek az azonosítóját a munkamenetbe tettük.

Demo belépők, csak erre a gépre:

| Szerep | Felhasználó | Jelszó |
| --- | --- | --- |
| adatbázis-tulajdonos | lumen | lumen_dev |
| olvasó | demo_olvaso | olvaso_dev |
| ápoló | demo_apolo | apolo_dev |
| orvos | demo_orvos | orvos_dev |
| pénzügy | demo_penzugy | penzugy_dev |
| admin | demo_admin | admin_dev |

## Ha a védésen egy szabályt kell élőben elrontani

Ütköző rendelés, aminek hibát kell adnia:

```sql
INSERT INTO vizit (beteg_id, orvos_id, idopont_kezdet, idopont_vege, statusz)
VALUES (13, 1, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '08:20', 'tervezett');
```

Ugyanebben az idősávban a 4-es rendelés `lemondott`, az bent maradhat. A különbség a kizáró megszorítás `WHERE` feltételében van.
