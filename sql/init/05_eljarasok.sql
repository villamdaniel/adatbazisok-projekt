-- Lumen Klinika
-- 05 Tárolt eljárások: a támogatott műveleti felület.
-- Nem hívnak COMMIT-ot, a hívó tranzakciója érvényes.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

CREATE OR REPLACE PROCEDURE sp_beteg_felvetele(
    p_beteg_id integer,
    p_agy_id integer,
    p_orvos_id integer,
    p_diagnozis_kod text,
    p_idopont timestamptz
)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_idopont timestamptz;
    v_felvetel_id integer;
BEGIN
    v_idopont := COALESCE(p_idopont, now());

    INSERT INTO felvetel (beteg_id, agy_id, felvevo_orvos_id, felvetel_idopont, statusz)
    VALUES (p_beteg_id, p_agy_id, p_orvos_id, v_idopont, 'aktiv')
    RETURNING felvetel_id INTO v_felvetel_id;

    INSERT INTO felvetel_diagnozis (felvetel_id, diagnozis_kod, tipus)
    VALUES (v_felvetel_id, p_diagnozis_kod, 'fo');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_beteg_elbocsatasa(p_felvetel_id integer)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    UPDATE felvetel
    SET statusz = 'lezart',
        elbocsatas_idopont = now()
    WHERE felvetel_id = p_felvetel_id
      AND statusz = 'aktiv';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Nincs aktív felvétel ezzel az azonosítóval.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_agy_attesz(p_felvetel_id integer, p_uj_agy_id integer)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_regi_agy integer;
    v_statusz text;
    v_osztaly_regi integer;
    v_osztaly_uj integer;
BEGIN
    SELECT agy_id, statusz
    INTO v_regi_agy, v_statusz
    FROM felvetel
    WHERE felvetel_id = p_felvetel_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'A felvétel nem található.';
    END IF;

    IF v_statusz <> 'aktiv' THEN
        RAISE EXCEPTION 'Csak aktív felvétel helyezhető át.';
    END IF;

    SELECT k.osztaly_id INTO v_osztaly_regi
    FROM agy a
    JOIN korterem k ON k.korterem_id = a.korterem_id
    WHERE a.agy_id = v_regi_agy;

    SELECT k.osztaly_id INTO v_osztaly_uj
    FROM agy a
    JOIN korterem k ON k.korterem_id = a.korterem_id
    WHERE a.agy_id = p_uj_agy_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Az új ágy nem található.';
    END IF;

    IF v_osztaly_regi <> v_osztaly_uj THEN
        RAISE EXCEPTION 'Osztályok között az áthelyezés nem támogatott. Ehhez elbocsátás és új felvétel kell.';
    END IF;

    UPDATE felvetel
    SET agy_id = p_uj_agy_id
    WHERE felvetel_id = p_felvetel_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_vizit_foglalas(
    p_beteg_id integer,
    p_orvos_id integer,
    p_kezdet timestamptz,
    p_vege timestamptz,
    p_panasz text
)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    INSERT INTO vizit (beteg_id, orvos_id, idopont_kezdet, idopont_vege, statusz, panasz)
    VALUES (p_beteg_id, p_orvos_id, p_kezdet, p_vege, 'tervezett', p_panasz);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_veny_kiad(p_veny_tetel_id integer)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    UPDATE veny_tetel
    SET kiadva = true
    WHERE veny_tetel_id = p_veny_tetel_id
      AND kiadva = false;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'A vénytétel nem adható ki: nincs meg, vagy már kiadták.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_szamla_fizet(
    p_szamla_id integer,
    p_osszeg numeric,
    p_mod text
)
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    INSERT INTO fizetes (szamla_id, osszeg, fizetes_mod, idopont)
    VALUES (p_szamla_id, p_osszeg, p_mod, now());
END;
$$;
