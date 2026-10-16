-- Lumen Klinika
-- Lekérdezés-katalógus. Csak olvas. psql -f sql/demo/lekerdezesek.sql
-- Minden blokk egy olyan kérdés, amit a bemutatón el lehet mondani.

\set ON_ERROR_STOP on
SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

\echo ''
\echo 'Q01  Bent fekvő betegek: ágy, osztály, orvos, fődiagnózis'
\echo '     Több tábla belső összekapcsolása.'

SELECT
    beteg_nev,
    eletkor,
    osztaly,
    korterem,
    agy_szam,
    felvevo_orvos,
    fo_diagnozis
FROM v_aktiv_fekvobetegek
ORDER BY osztaly, korterem, agy_szam;

\echo ''
\echo 'Q02  Ágykihasználtság osztályonként'
\echo '     Csoportosítás és FILTER.'

SELECT
    osztaly,
    uzemelo_agyak,
    foglalt,
    szabad,
    karbantartas,
    kihasznaltsag_szazalek
FROM v_osztaly_kihasznaltsag
ORDER BY kihasznaltsag_szazalek DESC NULLS LAST;

\echo ''
\echo 'Q03  Regisztrált betegek, akiknek még nem volt rendelésük'
\echo '     NOT EXISTS anti-join.'

SELECT b.beteg_id, b.vezeteknev, b.keresztnev, b.regisztracio_datuma
FROM beteg b
WHERE NOT EXISTS (
    SELECT 1 FROM vizit v WHERE v.beteg_id = b.beteg_id
)
ORDER BY b.vezeteknev, b.keresztnev;

\echo ''
\echo 'Q04  Orvosok, akiknek az elmúlt 30 napban egynél több rendelésük volt'
\echo '     GROUP BY és HAVING.'

SELECT
    a.vezeteknev || ' ' || a.keresztnev AS orvos,
    count(*) AS vizitek
FROM vizit v
JOIN alkalmazott a ON a.alkalmazott_id = v.orvos_id
WHERE v.idopont_kezdet >= now() - INTERVAL '30 days'
  AND v.statusz <> 'lemondott'
GROUP BY a.alkalmazott_id, a.vezeteknev, a.keresztnev
HAVING count(*) > 1
ORDER BY vizitek DESC, orvos;

\echo ''
\echo 'Q05  Legtöbbet kiadott gyógyszerek'
\echo '     Összegzés és rendezés.'

SELECT
    g.nev,
    g.kiszereles,
    sum(-m.mennyiseg) AS kiadott_mennyiseg
FROM keszlet_mozgas m
JOIN gyogyszer g ON g.gyogyszer_id = m.gyogyszer_id
WHERE m.ok = 'kiadas'
GROUP BY g.gyogyszer_id, g.nev, g.kiszereles
ORDER BY kiadott_mennyiseg DESC, g.nev;

\echo ''
\echo 'Q06  Lejárt, még ki nem fizetett számlák'

SELECT szamla_szam, beteg, hatarido, brutto, fizetett, egyenleg
FROM v_lejaro_szamlak
ORDER BY hatarido, szamla_szam;

\echo ''
\echo 'Q07  Referenciatartományon kívüli laborok'

SELECT beteg, vizsgalat, eredmeny, mertekegyseg, ref_min, ref_max, elteres
FROM v_labor_riasztas
ORDER BY mintavetel_idopont DESC;

\echo ''
\echo 'Q08  Orvosok rangsora a megjelent rendelések szerint'
\echo '     RANK ablakfüggvény. Aki nem rendelt, nulla vizittel szerepel.'

SELECT
    orvos,
    megjelent,
    rank() OVER (ORDER BY megjelent DESC, orvos) AS helyezes
FROM (
    SELECT
        a.vezeteknev || ' ' || a.keresztnev AS orvos,
        count(v.vizit_id) FILTER (WHERE v.statusz = 'megjelent') AS megjelent
    FROM orvos o
    JOIN alkalmazott a ON a.alkalmazott_id = o.alkalmazott_id
    LEFT JOIN vizit v ON v.orvos_id = o.alkalmazott_id
    GROUP BY a.alkalmazott_id, a.vezeteknev, a.keresztnev
) s
ORDER BY helyezes, orvos;

\echo ''
\echo 'Q09  Ugyanazon beteg egymást követő rendelései között eltelt napok'
\echo '     LAG ablakfüggvény.'

SELECT
    beteg,
    idopont_kezdet,
    statusz,
    lag(idopont_kezdet) OVER (PARTITION BY beteg_id ORDER BY idopont_kezdet) AS elozo,
    round(EXTRACT(EPOCH FROM (
        idopont_kezdet - lag(idopont_kezdet) OVER (PARTITION BY beteg_id ORDER BY idopont_kezdet)
    )) / 86400.0, 1) AS nap_az_elozo_ota
FROM (
    SELECT
        v.beteg_id,
        b.vezeteknev || ' ' || b.keresztnev AS beteg,
        v.idopont_kezdet,
        v.statusz
    FROM vizit v
    JOIN beteg b ON b.beteg_id = v.beteg_id
    WHERE v.statusz <> 'lemondott'
) s
ORDER BY beteg, idopont_kezdet;

\echo ''
\echo 'Q10  Befizetés hónaponként és fizetési módon'
\echo '     GROUPING SETS.'

SELECT
    to_char(honap, 'YYYY-MM') AS honap,
    COALESCE(fizetes_mod, 'összesen') AS fizetes_mod,
    sum(osszeg) AS osszeg
FROM (
    SELECT date_trunc('month', idopont) AS honap, fizetes_mod, osszeg
    FROM fizetes
) befizetes
GROUP BY GROUPING SETS (
    (honap, fizetes_mod),
    (honap)
)
ORDER BY honap, fizetes_mod;

\echo ''
\echo 'Q11  Osztályok, ahol az üzemelő ágyak legalább fele foglalt'
\echo '     CTE.'

WITH kihasznaltsag AS (
    SELECT osztaly, uzemelo_agyak, foglalt, kihasznaltsag_szazalek
    FROM v_osztaly_kihasznaltsag
)
SELECT *
FROM kihasznaltsag
WHERE kihasznaltsag_szazalek >= 50
ORDER BY kihasznaltsag_szazalek DESC;

\echo ''
\echo 'Q12  Bent fekvő beteg, akinek ma járóbeteg-rendelése is van'

SELECT
    b.vezeteknev || ' ' || b.keresztnev AS beteg,
    o.nev AS fekvo_osztaly,
    a.vezeteknev || ' ' || a.keresztnev AS rendelo_orvos,
    v.idopont_kezdet
FROM felvetel f
JOIN beteg b ON b.beteg_id = f.beteg_id
JOIN agy ag ON ag.agy_id = f.agy_id
JOIN korterem k ON k.korterem_id = ag.korterem_id
JOIN osztaly o ON o.osztaly_id = k.osztaly_id
JOIN vizit v ON v.beteg_id = f.beteg_id
JOIN alkalmazott a ON a.alkalmazott_id = v.orvos_id
WHERE f.statusz = 'aktiv'
  AND v.statusz IN ('tervezett', 'megjelent')
  AND (v.idopont_kezdet AT TIME ZONE 'Europe/Budapest')::date
      = (now() AT TIME ZONE 'Europe/Budapest')::date
ORDER BY v.idopont_kezdet;

\echo ''
\echo 'Q13  Aktív fekvőbetegek átlagéletkora osztályonként'

SELECT
    osztaly,
    count(*) AS betegek,
    round(avg(eletkor), 1) AS atlag_eletkor
FROM v_aktiv_fekvobetegek
GROUP BY osztaly
ORDER BY osztaly;

\echo ''
\echo 'Q14  Mai ellátottak egy listában: bent fekvők és előjegyzettek'
\echo '     UNION.'

SELECT 'fekvobeteg' AS forma, beteg_nev AS nev, osztaly, felvetel_idopont AS idopont
FROM v_aktiv_fekvobetegek
UNION ALL
SELECT 'jarobeteg', beteg, osztaly, idopont_kezdet
FROM v_mai_elojegyzes
ORDER BY idopont, nev;

\echo ''
\echo 'Q15  Számla tételeinek futó összege'
\echo '     SUM ablakfüggvény.'

SELECT
    s.szamla_szam,
    t.megnevezes,
    t.brutto_osszeg,
    sum(t.brutto_osszeg) OVER (
        PARTITION BY t.szamla_id
        ORDER BY t.tetel_id
        ROWS UNBOUNDED PRECEDING
    ) AS futo_osszeg
FROM szamla_tetel t
JOIN szamla s ON s.szamla_id = t.szamla_id
ORDER BY s.szamla_szam, t.tetel_id;

\echo ''
\echo 'Q16  Betegenként a legutóbbi laboreredmény'
\echo '     DISTINCT ON, PostgreSQL-sajátosság.'

SELECT DISTINCT ON (b.beteg_id)
    b.vezeteknev || ' ' || b.keresztnev AS beteg,
    l.mintavetel_idopont,
    t.nev AS vizsgalat,
    l.eredmeny,
    t.mertekegyseg
FROM labor_lelet l
JOIN beteg b ON b.beteg_id = l.beteg_id
JOIN labor_tipus t ON t.tipus_id = l.tipus_id
ORDER BY b.beteg_id, l.mintavetel_idopont DESC;

\echo ''
\echo 'Q17  Gyógyszerek, amelyekből még nem volt kiadás'
\echo '     LEFT JOIN, a hiányzó pár érdekel.'

SELECT g.nev, g.kiszereles, k.keszlet
FROM gyogyszer g
JOIN v_gyogyszer_keszlet k ON k.gyogyszer_id = g.gyogyszer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM keszlet_mozgas m
    WHERE m.gyogyszer_id = g.gyogyszer_id
      AND m.ok = 'kiadas'
)
ORDER BY g.nev;

\echo ''
\echo 'Q18  Névtöredék keresése'
\echo '     A trigram index ezt a mintát tudja gyorsítani.'

SELECT beteg_id, vezeteknev, keresztnev, varos
FROM beteg
WHERE (vezeteknev || ' ' || keresztnev) ILIKE '%horv%'
ORDER BY vezeteknev, keresztnev;
