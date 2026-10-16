-- Lumen Klinika
-- 07 Jogosultság. A jelszavak csak helyi bemutatóhoz valók.
-- Csoportszerep + belépő szerep: új felhasználó a csoport jogosultságát örökli.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

CREATE ROLE klinika_olvaso NOLOGIN;
CREATE ROLE klinika_apolo NOLOGIN;
CREATE ROLE klinika_orvos NOLOGIN;
CREATE ROLE klinika_penzugy NOLOGIN;
CREATE ROLE klinika_admin NOLOGIN;

CREATE ROLE demo_olvaso LOGIN PASSWORD 'olvaso_dev';
CREATE ROLE demo_apolo LOGIN PASSWORD 'apolo_dev';
CREATE ROLE demo_orvos LOGIN PASSWORD 'orvos_dev';
CREATE ROLE demo_penzugy LOGIN PASSWORD 'penzugy_dev';
CREATE ROLE demo_admin LOGIN PASSWORD 'admin_dev';

GRANT klinika_olvaso TO demo_olvaso;
GRANT klinika_apolo TO demo_apolo;
GRANT klinika_orvos TO demo_orvos;
GRANT klinika_penzugy TO demo_penzugy;
GRANT klinika_admin TO demo_admin;

DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO CURRENT_USER', current_database());
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO klinika_olvaso, klinika_apolo, klinika_orvos, klinika_penzugy, klinika_admin',
        current_database()
    );
END
$$;

GRANT USAGE ON SCHEMA public TO
    klinika_olvaso, klinika_apolo, klinika_orvos, klinika_penzugy, klinika_admin;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

GRANT SELECT ON v_osztaly_kihasznaltsag, v_mai_elojegyzes TO klinika_olvaso;

GRANT SELECT ON
    beteg, osztaly, korterem, agy, felvetel, felvetel_diagnozis, diagnozis,
    v_aktiv_fekvobetegek, v_osztaly_kihasznaltsag, v_mai_elojegyzes, v_gyogyszer_keszlet, v_alacsony_keszlet
TO klinika_apolo;

GRANT SELECT ON
    beteg, osztaly, korterem, agy, alkalmazott, orvos, apolo,
    felvetel, felvetel_diagnozis, diagnozis, vizit,
    gyogyszer, veny, veny_tetel, labor_tipus, labor_lelet,
    szolgaltatas, szamla, szamla_tetel,
    v_aktiv_fekvobetegek, v_osztaly_kihasznaltsag, v_mai_elojegyzes,
    v_gyogyszer_keszlet, v_alacsony_keszlet, v_labor_riasztas, v_szamla_egyenleg
TO klinika_orvos;

GRANT INSERT, UPDATE ON
    felvetel, felvetel_diagnozis, vizit, veny, veny_tetel, labor_lelet
TO klinika_orvos;

GRANT SELECT ON
    beteg, szolgaltatas, szamla, szamla_tetel, fizetes,
    v_szamla_egyenleg, v_lejaro_szamlak, v_osztaly_kihasznaltsag
TO klinika_penzugy;

GRANT INSERT, UPDATE ON szamla, szamla_tetel, fizetes TO klinika_penzugy;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO klinika_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO klinika_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO klinika_orvos, klinika_penzugy;

REVOKE ALL ON PROCEDURE sp_beteg_felvetele(integer, integer, integer, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_beteg_elbocsatasa(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_agy_attesz(integer, integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_vizit_foglalas(integer, integer, timestamptz, timestamptz, text) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_veny_kiad(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_szamla_fizet(integer, numeric, text) FROM PUBLIC;

GRANT EXECUTE ON PROCEDURE
    sp_beteg_felvetele(integer, integer, integer, text, timestamptz),
    sp_beteg_elbocsatasa(integer),
    sp_agy_attesz(integer, integer),
    sp_vizit_foglalas(integer, integer, timestamptz, timestamptz, text),
    sp_veny_kiad(integer)
TO klinika_orvos, klinika_admin;

GRANT EXECUTE ON PROCEDURE sp_szamla_fizet(integer, numeric, text)
TO klinika_penzugy, klinika_admin;

-- Az orvos csak a munkamenetben megadott saját rendeléseit látja közvetlenül a táblán.
-- A nézet tulajdonosa a klinika adminisztrátora, ezért a nézet szándékosan a teljes napot mutatja.
ALTER TABLE vizit ENABLE ROW LEVEL SECURITY;

CREATE POLICY vizit_orvos_sajat ON vizit
FOR ALL
TO klinika_orvos, demo_orvos
USING (orvos_id = NULLIF(current_setting('app.orvos_id', true), '')::integer)
WITH CHECK (orvos_id = NULLIF(current_setting('app.orvos_id', true), '')::integer);

CREATE POLICY vizit_admin_minden ON vizit
FOR ALL
TO klinika_admin, demo_admin
USING (true)
WITH CHECK (true);
