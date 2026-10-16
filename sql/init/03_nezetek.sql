-- Lumen Klinika
-- 03 Nézetek. A jogosultság később ezekre is épül.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

CREATE OR REPLACE FUNCTION fn_beteg_eletkor(p_szuletesi_datum date)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT EXTRACT(YEAR FROM age(CURRENT_DATE, p_szuletesi_datum))::integer;
$$;

CREATE OR REPLACE VIEW v_aktiv_fekvobetegek AS
SELECT
    f.felvetel_id,
    b.beteg_id,
    b.taj_szam,
    b.vezeteknev || ' ' || b.keresztnev AS beteg_nev,
    fn_beteg_eletkor(b.szuletesi_datum) AS eletkor,
    o.kod AS osztaly_kod,
    o.nev AS osztaly,
    k.szam AS korterem,
    a.agy_szam,
    doc.vezeteknev || ' ' || doc.keresztnev AS felvevo_orvos,
    f.felvetel_idopont,
    d.kod AS fo_diagnozis_kod,
    d.megnevezes AS fo_diagnozis
FROM felvetel f
JOIN beteg b ON b.beteg_id = f.beteg_id
JOIN agy a ON a.agy_id = f.agy_id
JOIN korterem k ON k.korterem_id = a.korterem_id
JOIN osztaly o ON o.osztaly_id = k.osztaly_id
JOIN orvos ov ON ov.alkalmazott_id = f.felvevo_orvos_id
JOIN alkalmazott doc ON doc.alkalmazott_id = ov.alkalmazott_id
LEFT JOIN felvetel_diagnozis fd
    ON fd.felvetel_id = f.felvetel_id AND fd.tipus = 'fo'
LEFT JOIN diagnozis d ON d.kod = fd.diagnozis_kod
WHERE f.statusz = 'aktiv';

CREATE OR REPLACE VIEW v_osztaly_kihasznaltsag AS
SELECT
    o.osztaly_id,
    o.kod,
    o.nev AS osztaly,
    count(a.agy_id) AS agyak,
    count(a.agy_id) FILTER (WHERE a.statusz = 'karbantartas') AS karbantartas,
    count(a.agy_id) FILTER (WHERE a.statusz <> 'karbantartas') AS uzemelo_agyak,
    count(a.agy_id) FILTER (WHERE a.statusz = 'foglalt') AS foglalt,
    count(a.agy_id) FILTER (WHERE a.statusz = 'szabad') AS szabad,
    round(
        100.0 * count(a.agy_id) FILTER (WHERE a.statusz = 'foglalt')
        / NULLIF(count(a.agy_id) FILTER (WHERE a.statusz <> 'karbantartas'), 0),
        1
    ) AS kihasznaltsag_szazalek
FROM osztaly o
JOIN korterem k ON k.osztaly_id = o.osztaly_id
JOIN agy a ON a.korterem_id = k.korterem_id
GROUP BY o.osztaly_id, o.kod, o.nev;

-- Recepció: időpont és név, klinikai szöveg nélkül.
CREATE OR REPLACE VIEW v_mai_elojegyzes AS
SELECT
    v.vizit_id,
    v.idopont_kezdet,
    v.idopont_vege,
    v.statusz,
    b.vezeteknev || ' ' || b.keresztnev AS beteg,
    d.vezeteknev || ' ' || d.keresztnev AS orvos,
    o.nev AS osztaly
FROM vizit v
JOIN beteg b ON b.beteg_id = v.beteg_id
JOIN orvos vo ON vo.alkalmazott_id = v.orvos_id
JOIN alkalmazott d ON d.alkalmazott_id = vo.alkalmazott_id
JOIN osztaly o ON o.osztaly_id = vo.osztaly_id
WHERE (v.idopont_kezdet AT TIME ZONE 'Europe/Budapest')::date
        = (now() AT TIME ZONE 'Europe/Budapest')::date
  AND v.statusz <> 'lemondott';

CREATE OR REPLACE VIEW v_gyogyszer_keszlet AS
SELECT
    g.gyogyszer_id,
    g.nev,
    g.hatoanyag,
    g.kiszereles,
    g.venykoteles,
    COALESCE(sum(m.mennyiseg), 0)::integer AS keszlet
FROM gyogyszer g
LEFT JOIN keszlet_mozgas m ON m.gyogyszer_id = g.gyogyszer_id
GROUP BY g.gyogyszer_id;

CREATE OR REPLACE VIEW v_alacsony_keszlet AS
SELECT *
FROM v_gyogyszer_keszlet
WHERE keszlet <= 5;

CREATE OR REPLACE VIEW v_labor_riasztas AS
SELECT
    l.lelet_id,
    b.beteg_id,
    b.vezeteknev || ' ' || b.keresztnev AS beteg,
    t.kod,
    t.nev AS vizsgalat,
    l.eredmeny,
    t.mertekegyseg,
    t.ref_min,
    t.ref_max,
    l.mintavetel_idopont,
    CASE
        WHEN l.eredmeny < t.ref_min THEN 'alacsony'
        ELSE 'magas'
    END AS elteres
FROM labor_lelet l
JOIN labor_tipus t ON t.tipus_id = l.tipus_id
JOIN beteg b ON b.beteg_id = l.beteg_id
WHERE l.eredmeny < t.ref_min OR l.eredmeny > t.ref_max;

CREATE OR REPLACE VIEW v_szamla_egyenleg AS
SELECT
    s.szamla_id,
    s.szamla_szam,
    s.beteg_id,
    b.vezeteknev || ' ' || b.keresztnev AS beteg,
    s.kiallitas_datuma,
    s.hatarido,
    s.statusz,
    COALESCE(t.brutto, 0) AS brutto,
    COALESCE(f.fizetett, 0) AS fizetett,
    COALESCE(t.brutto, 0) - COALESCE(f.fizetett, 0) AS egyenleg
FROM szamla s
JOIN beteg b ON b.beteg_id = s.beteg_id
LEFT JOIN (
    SELECT szamla_id, sum(brutto_osszeg) AS brutto
    FROM szamla_tetel
    GROUP BY szamla_id
) t ON t.szamla_id = s.szamla_id
LEFT JOIN (
    SELECT szamla_id, sum(osszeg) AS fizetett
    FROM fizetes
    GROUP BY szamla_id
) f ON f.szamla_id = s.szamla_id;

CREATE OR REPLACE VIEW v_lejaro_szamlak AS
SELECT *
FROM v_szamla_egyenleg
WHERE statusz = 'nyitott'
  AND hatarido < CURRENT_DATE
  AND egyenleg > 0;

COMMENT ON VIEW v_aktiv_fekvobetegek IS 'Bent fekvő betegek ággyal, orvossal és fődiagnózissal.';
COMMENT ON VIEW v_osztaly_kihasznaltsag IS 'Ágykihasználtság. A karbantartás alatti ágy nem számít üzemelőnek.';
COMMENT ON VIEW v_mai_elojegyzes IS 'Mai rendelések klinikai szöveg nélkül, recepciós nézet.';
COMMENT ON VIEW v_gyogyszer_keszlet IS 'Aktuális készlet a mozgásnapló összegeként.';
COMMENT ON VIEW v_labor_riasztas IS 'Referenciatartományon kívüli laboreredmények.';
COMMENT ON VIEW v_szamla_egyenleg IS 'Számla bruttó, befizetett és hátralék.';
