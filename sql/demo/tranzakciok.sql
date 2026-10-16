-- Lumen Klinika
-- Tranzakciós bemutató. A végén minden változás visszagörgetődik,
-- a parancs ismételhető.
--
-- psql viselkedése: a szándékos hibánál a szkript megy tovább,
-- majd ROLLBACK TO SAVEPOINT helyreállítja a tranzakciót.

\set ON_ERROR_STOP on
SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

\echo ''
\echo '1. Atomi áthelyezés, majd a teljes tranzakció visszavonása'

BEGIN;

SELECT agy_id, statusz
FROM agy
WHERE agy_id IN (1, 3)
ORDER BY agy_id;

CALL sp_agy_attesz(1, 3);

SELECT felvetel_id, agy_id, statusz
FROM felvetel
WHERE felvetel_id = 1;

SELECT agy_id, statusz
FROM agy
WHERE agy_id IN (1, 3)
ORDER BY agy_id;

ROLLBACK;

SELECT felvetel_id, agy_id
FROM felvetel
WHERE felvetel_id = 1;

\echo ''
\echo '2. SAVEPOINT: a túl nagy befizetés hibája nem viszi el a jó sort'

\set ON_ERROR_STOP off
BEGIN;
INSERT INTO fizetes (szamla_id, osszeg, fizetes_mod, idopont)
VALUES (2, 1000, 'kartya', now());
SAVEPOINT reszleges_fizetes;
INSERT INTO fizetes (szamla_id, osszeg, fizetes_mod, idopont)
VALUES (2, 999999, 'kartya', now());
ROLLBACK TO SAVEPOINT reszleges_fizetes;
\set ON_ERROR_STOP on

SELECT szamla_id, osszeg, fizetes_mod
FROM fizetes
WHERE szamla_id = 2
ORDER BY fizetes_id;

ROLLBACK;

\echo ''
\echo '3. A bemutató után a 2-es számla továbbra is érintetlen'

SELECT szamla_szam, statusz, fizetett, egyenleg
FROM v_szamla_egyenleg
WHERE szamla_id = 2;
