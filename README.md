# Lumen Klinika

Egyetemi adatbázis-projekt. A Lumen Klinika járó- és fekvőbeteg-ellátásának relációs modellje és PostgreSQL 16 (vagy újabb) megvalósítása. A hangsúly az SQL-en van: séma, megszorítás, nézet, trigger, tárolt eljárás, tranzakció, jogosultság és lekérdezés.

Hallgató neve:  Villám Dániel Zsolt
Neptun-kód: IF5XNY

A feladat leírása a [docs/01-feladat.md](docs/01-feladat.md) fájlban van. Az egyed-kapcsolat modell a [docs/02-ermodell.md](docs/02-ermodell.md), a normalizálás és az integritás a [docs/03-relacios-modell.md](docs/03-relacios-modell.md), a védés menete a [docs/04-bemutato.md](docs/04-bemutato.md) fájlban.

## Mit lehet rajta számonkérni

- 22 tábla, idegen kulcsokkal és indokolt törlési szabállyal
- TAJ ellenőrző jegy tartományként, áfa és státusz CHECK megszorításként
- kizáró megszorítás az ágy, a beteg és az orvos naptárának ütközésére
- részleges egyedi index a fődiagnózisra és az aktív felvételre
- halasztott constraint trigger: tranzakció végére minden felvételnek van fődiagnózisa
- készletnapló, amely nem írható felül és nem mehet nulla alá
- számla bruttója generált oszlop, a befizetés nem lépheti túl
- nézetek recepcióra, kihasználtságra, készletre, laborriasztásra és egyenlegre
- hat tárolt eljárás
- sorvédelem az orvos saját rendeléseire
- 18 lekérdezés: összekapcsolás, anti-join, HAVING, CTE, UNION, ablakfüggvény, GROUPING SETS, DISTINCT ON

## Futtatás Dockerrel

A [Docker Desktop](https://www.docker.com/products/docker-desktop/) kell, és az, hogy a gép el tudja indítani a konténert.

```powershell
docker compose up -d --wait
```

Az első induláskor a `sql/init` szkriptjei sorrendben lefutnak, a végén az ellenőrzés. Ha egy szabály nem állja meg a helyét, a konténer nem lesz kész.

| | |
| --- | --- |
| cím | `localhost:5432` |
| adatbázis | `lumen_klinika` |
| tulajdonos | `lumen` / `lumen_dev` |

```powershell
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/lekerdezesek.sql
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/tranzakciok.sql
docker compose exec db psql -U lumen -d lumen_klinika -f /demo/jogosultsag.sql
```

Újratöltés, az adatok törlésével:

```powershell
docker compose down -v
docker compose up -d --wait
```

A `scripts/ujrainditas.ps1` és a `scripts/lekerdezesek.ps1` ugyanez.

## Futtatás telepített PostgreSQL-lel

PostgreSQL 16 vagy újabb kell, a `citext`, `btree_gist` és `pg_trgm` kiegészítőkkel. Ezek a hivatalos telepítőben benne vannak.

```powershell
psql -U postgres -c "CREATE DATABASE lumen_klinika"
psql -U postgres -d lumen_klinika -v ON_ERROR_STOP=1 -f sql/futtatas.sql
psql -U postgres -d lumen_klinika -f sql/demo/lekerdezesek.sql
```

A `futtatas.sql`-t ne `--single-transaction` kapcsolóval futtasd. A felvétel és a fődiagnózis egy saját tranzakció, mert a kötelező diagnózis csak a tranzakció végén ellenőrződik.

## A repó térképe

```text
sql/init/01_sema.sql          táblák, kulcsok, CHECK, kizáró megszorítás
sql/init/02_indexek.sql       idegen kulcs indexe, részleges és trigram index
sql/init/03_nezetek.sql       nézetek és az életkor függvény
sql/init/04_triggerek.sql     üzleti szabály, készlet, számla, audit
sql/init/05_eljarasok.sql     felvétel, elbocsátás, áthelyezés, rendelés, kiadás, fizetés
sql/init/06_adatok.sql        mintaadat, a betöltés napjához képest
sql/init/07_jogosultsag.sql   szerepek, GRANT, sorvédelem
sql/init/08_ellenorzes.sql    a szabályok gépi ellenőrzése
sql/demo/                     lekérdezés, tranzakció, jogosultság bemutatója
docs/                         feladat, ER, normalizálás, védés
```

A minta dátumai nem 2026 októberéhez vannak kötve. A „mai rendelés” és a „lejárt számla” a betöltés napjához képest készül, ezért a bemutató egy későbbi napon is ugyanezt mutatja.

A jelszavak fejlesztői jelszavak. GitHubra így is feltehetők, éles rendszerbe nem valók.
