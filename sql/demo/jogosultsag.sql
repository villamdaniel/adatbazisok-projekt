-- Lumen Klinika
-- Jogosultság-bemutató. A tulaj olvasása nem esik sorvédelem alá.
-- A demo_orvos szerep csak a beállított orvos rendeléseit látja.

\set ON_ERROR_STOP on
SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

\echo ''
\echo 'Olvasó: kihasználtság igen, labor tábla nem'

SET ROLE demo_olvaso;
SELECT osztaly, kihasznaltsag_szazalek
FROM v_osztaly_kihasznaltsag
ORDER BY osztaly;

\echo 'A következő lekérdezésnek permission denied hibát kell adnia.'
\set ON_ERROR_STOP off
SELECT count(*) AS labor_sorok_ha_latszodna FROM labor_lelet;
\set ON_ERROR_STOP on
RESET ROLE;

\echo ''
\echo 'Orvos sorvédelem: Kovács Anna (1) csak a saját rendeléseit látja'

SET ROLE demo_orvos;
SELECT set_config('app.orvos_id', '1', false);
SELECT count(*) AS sajat_vizitek
FROM vizit;

SELECT set_config('app.orvos_id', '5', false);
SELECT count(*) AS varga_peter_vizitjei
FROM vizit;
RESET ROLE;

\echo ''
\echo 'Admin szerep a teljes vizit táblát látja'

SET ROLE demo_admin;
SELECT count(*) AS osszes_vizit FROM vizit;
RESET ROLE;
