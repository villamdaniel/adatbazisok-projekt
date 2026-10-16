-- Lumen Klinika
-- 04 Triggerek: üzleti szabály, készlet, számla, audit.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

CREATE OR REPLACE FUNCTION trg_szuletesi_nem_jovobeli()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.szuletesi_datum > CURRENT_DATE THEN
        RAISE EXCEPTION 'A születési dátum nem lehet jövőbeli.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER beteg_szuletesi
BEFORE INSERT OR UPDATE OF szuletesi_datum ON beteg
FOR EACH ROW EXECUTE FUNCTION trg_szuletesi_nem_jovobeli();

CREATE TRIGGER alkalmazott_szuletesi
BEFORE INSERT OR UPDATE OF szuletesi_datum ON alkalmazott
FOR EACH ROW EXECUTE FUNCTION trg_szuletesi_nem_jovobeli();

CREATE OR REPLACE FUNCTION trg_szerepkor_kizaro()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF TG_TABLE_NAME = 'orvos' AND EXISTS (
        SELECT 1 FROM apolo WHERE alkalmazott_id = NEW.alkalmazott_id
    ) THEN
        RAISE EXCEPTION 'Egy alkalmazott nem lehet egyszerre orvos és ápoló.';
    END IF;

    IF TG_TABLE_NAME = 'apolo' AND EXISTS (
        SELECT 1 FROM orvos WHERE alkalmazott_id = NEW.alkalmazott_id
    ) THEN
        RAISE EXCEPTION 'Egy alkalmazott nem lehet egyszerre orvos és ápoló.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER orvos_nem_apolo
BEFORE INSERT OR UPDATE ON orvos
FOR EACH ROW EXECUTE FUNCTION trg_szerepkor_kizaro();

CREATE TRIGGER apolo_nem_orvos
BEFORE INSERT OR UPDATE ON apolo
FOR EACH ROW EXECUTE FUNCTION trg_szerepkor_kizaro();

CREATE OR REPLACE FUNCTION trg_osztaly_vezeto()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.vezeto_orvos_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM orvos o
        JOIN alkalmazott a ON a.alkalmazott_id = o.alkalmazott_id
        WHERE o.alkalmazott_id = NEW.vezeto_orvos_id
          AND o.osztaly_id = NEW.osztaly_id
          AND a.aktiv
    ) THEN
        RAISE EXCEPTION 'Az osztályvezető csak az adott osztály aktív orvosa lehet.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER osztaly_vezeto_ellenorzes
BEFORE INSERT OR UPDATE OF vezeto_orvos_id, osztaly_id ON osztaly
FOR EACH ROW EXECUTE FUNCTION trg_osztaly_vezeto();

CREATE OR REPLACE FUNCTION trg_orvos_osztaly_valtas()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.osztaly_id IS DISTINCT FROM OLD.osztaly_id AND EXISTS (
        SELECT 1 FROM osztaly WHERE vezeto_orvos_id = NEW.alkalmazott_id
    ) THEN
        RAISE EXCEPTION 'Osztályvezető nem helyezhető át, amíg a tisztségét át nem adta.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER orvos_osztaly_valtas
BEFORE UPDATE OF osztaly_id ON orvos
FOR EACH ROW EXECUTE FUNCTION trg_orvos_osztaly_valtas();

CREATE OR REPLACE FUNCTION fn_agy_statusz_frissit(p_agy_id integer)
RETURNS void
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    UPDATE agy a
    SET statusz = CASE
        WHEN a.statusz = 'karbantartas' THEN 'karbantartas'
        WHEN EXISTS (
            SELECT 1
            FROM felvetel f
            WHERE f.agy_id = a.agy_id
              AND f.statusz = 'aktiv'
        ) THEN 'foglalt'
        ELSE 'szabad'
    END
    WHERE a.agy_id = p_agy_id;
END;
$$;

CREATE OR REPLACE FUNCTION trg_felvetel_ellenorzes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_agy_statusz text;
    v_agy_osztaly integer;
    v_osztaly_kod text;
    v_orvos_osztaly integer;
    v_orvos_aktiv boolean;
    v_szul date;
BEGIN
    SELECT a.statusz, k.osztaly_id, o.kod
    INTO v_agy_statusz, v_agy_osztaly, v_osztaly_kod
    FROM agy a
    JOIN korterem k ON k.korterem_id = a.korterem_id
    JOIN osztaly o ON o.osztaly_id = k.osztaly_id
    WHERE a.agy_id = NEW.agy_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Az ágy nem található.';
    END IF;

    IF NEW.statusz = 'aktiv' AND v_agy_statusz = 'karbantartas' THEN
        RAISE EXCEPTION 'Karbantartás alatt álló ágyra nem vehető fel beteg.';
    END IF;

    SELECT o.osztaly_id, a.aktiv
    INTO v_orvos_osztaly, v_orvos_aktiv
    FROM orvos o
    JOIN alkalmazott a ON a.alkalmazott_id = o.alkalmazott_id
    WHERE o.alkalmazott_id = NEW.felvevo_orvos_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'A felvevő orvos nem található.';
    END IF;

    IF NOT v_orvos_aktiv THEN
        IF TG_OP = 'INSERT' THEN
            RAISE EXCEPTION 'Inaktív orvos nem vehet fel beteget.';
        ELSIF NEW.felvevo_orvos_id IS DISTINCT FROM OLD.felvevo_orvos_id THEN
            RAISE EXCEPTION 'Inaktív orvos nem vehet fel beteget.';
        END IF;
    END IF;

    IF v_orvos_osztaly IS DISTINCT FROM v_agy_osztaly THEN
        RAISE EXCEPTION 'A felvevő orvos nem a kórterem osztályához tartozik.';
    END IF;

    SELECT szuletesi_datum INTO v_szul
    FROM beteg
    WHERE beteg_id = NEW.beteg_id;

    IF v_osztaly_kod = 'GYE'
       AND age(NEW.felvetel_idopont, v_szul::timestamptz) >= INTERVAL '18 years' THEN
        RAISE EXCEPTION 'A gyermekgyógyászatra csak 18 év alatti beteg vehető fel.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER felvetel_ellenorzes
BEFORE INSERT OR UPDATE ON felvetel
FOR EACH ROW EXECUTE FUNCTION trg_felvetel_ellenorzes();

CREATE OR REPLACE FUNCTION trg_agy_statusz()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.agy_id IS DISTINCT FROM NEW.agy_id THEN
        PERFORM fn_agy_statusz_frissit(OLD.agy_id);
    END IF;

    IF TG_OP = 'DELETE' THEN
        PERFORM fn_agy_statusz_frissit(OLD.agy_id);
        RETURN OLD;
    END IF;

    PERFORM fn_agy_statusz_frissit(NEW.agy_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER felvetel_agy_statusz
AFTER INSERT OR UPDATE OR DELETE ON felvetel
FOR EACH ROW EXECUTE FUNCTION trg_agy_statusz();

CREATE OR REPLACE FUNCTION trg_kotelezo_fodiagnozis()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_id integer;
BEGIN
    IF TG_TABLE_NAME = 'felvetel' THEN
        v_id := NEW.felvetel_id;
    ELSE
        v_id := COALESCE(NEW.felvetel_id, OLD.felvetel_id);
    END IF;

    -- Törölt felvételnél a kaszkád már elvitte a diagnózist: nincs mit ellenőrizni.
    IF EXISTS (SELECT 1 FROM felvetel WHERE felvetel_id = v_id)
       AND NOT EXISTS (
            SELECT 1
            FROM felvetel_diagnozis
            WHERE felvetel_id = v_id
              AND tipus = 'fo'
       ) THEN
        RAISE EXCEPTION 'Minden felvételhez pontosan egy fődiagnózis kell.';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER felvetel_kotelezo_diagnozis
AFTER INSERT ON felvetel
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION trg_kotelezo_fodiagnozis();

CREATE CONSTRAINT TRIGGER diagnozis_kotelezo_fo
AFTER INSERT OR UPDATE OR DELETE ON felvetel_diagnozis
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION trg_kotelezo_fodiagnozis();

CREATE OR REPLACE FUNCTION trg_vizit_ellenorzes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_aktiv boolean;
BEGIN
    SELECT a.aktiv INTO v_aktiv
    FROM orvos o
    JOIN alkalmazott a ON a.alkalmazott_id = o.alkalmazott_id
    WHERE o.alkalmazott_id = NEW.orvos_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Az orvos nem található.';
    END IF;

    IF TG_OP = 'INSERT' AND NOT v_aktiv THEN
        RAISE EXCEPTION 'Inaktív orvoshoz nem foglalható rendelés.';
    END IF;

    IF NEW.statusz IN ('tervezett', 'megjelent') AND EXISTS (
        SELECT 1
        FROM vizit v
        WHERE v.orvos_id = NEW.orvos_id
          AND v.statusz IN ('tervezett', 'megjelent')
          AND v.vizit_id IS DISTINCT FROM NEW.vizit_id
          AND tstzrange(v.idopont_kezdet, v.idopont_vege, '[)')
              && tstzrange(NEW.idopont_kezdet, NEW.idopont_vege, '[)')
    ) THEN
        RAISE EXCEPTION 'Az orvosnak ebben az időben már van rendelése.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER vizit_ellenorzes
BEFORE INSERT OR UPDATE ON vizit
FOR EACH ROW EXECUTE FUNCTION trg_vizit_ellenorzes();

CREATE OR REPLACE FUNCTION trg_veny_kiadas()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.kiadva THEN
        RAISE EXCEPTION 'Kiadott vénytétel nem módosítható.';
    END IF;

    IF NEW.kiadva THEN
        INSERT INTO keszlet_mozgas (gyogyszer_id, mennyiseg, ok, veny_tetel_id, megjegyzes)
        VALUES (NEW.gyogyszer_id, -NEW.mennyiseg, 'kiadas', NEW.veny_tetel_id, 'vénykiadás');
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER veny_tetel_kiadas
AFTER INSERT OR UPDATE OF kiadva, mennyiseg, gyogyszer_id ON veny_tetel
FOR EACH ROW EXECUTE FUNCTION trg_veny_kiadas();

CREATE OR REPLACE FUNCTION trg_keszlet_csak_beszuras()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    RAISE EXCEPTION 'A készletmozgás módosíthatatlan napló. Javítás csak új korrekciós sorral lehetséges.';
END;
$$;

CREATE TRIGGER keszlet_nem_modosithato
BEFORE UPDATE OR DELETE ON keszlet_mozgas
FOR EACH ROW EXECUTE FUNCTION trg_keszlet_csak_beszuras();

CREATE OR REPLACE FUNCTION trg_keszlet_nem_negativ()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_keszlet integer;
BEGIN
    PERFORM 1
    FROM gyogyszer
    WHERE gyogyszer_id = NEW.gyogyszer_id
    FOR UPDATE;

    SELECT COALESCE(sum(mennyiseg), 0)
    INTO v_keszlet
    FROM keszlet_mozgas
    WHERE gyogyszer_id = NEW.gyogyszer_id;

    IF v_keszlet + NEW.mennyiseg < 0 THEN
        RAISE EXCEPTION 'Nincs elég készlet a gyógyszerből (azonosító: %).', NEW.gyogyszer_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER keszlet_nem_negativ
BEFORE INSERT ON keszlet_mozgas
FOR EACH ROW EXECUTE FUNCTION trg_keszlet_nem_negativ();

CREATE OR REPLACE FUNCTION trg_fizetes_ellenorzes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_statusz text;
    v_brutto numeric(14, 2);
    v_fizetett numeric(14, 2);
BEGIN
    SELECT statusz INTO v_statusz
    FROM szamla
    WHERE szamla_id = NEW.szamla_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'A számla nem található.';
    END IF;

    IF v_statusz = 'sztorno' THEN
        RAISE EXCEPTION 'Sztornózott számlára nem lehet fizetni.';
    END IF;

    SELECT COALESCE(sum(brutto_osszeg), 0)
    INTO v_brutto
    FROM szamla_tetel
    WHERE szamla_id = NEW.szamla_id;

    SELECT COALESCE(sum(osszeg), 0)
    INTO v_fizetett
    FROM fizetes
    WHERE szamla_id = NEW.szamla_id;

    v_fizetett := v_fizetett + NEW.osszeg;

    IF v_fizetett > v_brutto THEN
        RAISE EXCEPTION 'A befizetés meghaladja a számla végösszegét.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER fizetes_ellenorzes
BEFORE INSERT ON fizetes
FOR EACH ROW EXECUTE FUNCTION trg_fizetes_ellenorzes();

CREATE OR REPLACE FUNCTION trg_szamla_statusz_fizetesbol()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_brutto numeric(14, 2);
    v_fizetett numeric(14, 2);
BEGIN
    SELECT COALESCE(sum(brutto_osszeg), 0)
    INTO v_brutto
    FROM szamla_tetel
    WHERE szamla_id = NEW.szamla_id;

    SELECT COALESCE(sum(osszeg), 0)
    INTO v_fizetett
    FROM fizetes
    WHERE szamla_id = NEW.szamla_id;

    IF v_fizetett = v_brutto AND v_brutto > 0 THEN
        UPDATE szamla
        SET statusz = 'fizetve'
        WHERE szamla_id = NEW.szamla_id
          AND statusz = 'nyitott';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER fizetes_statusz
AFTER INSERT ON fizetes
FOR EACH ROW EXECUTE FUNCTION trg_szamla_statusz_fizetesbol();

CREATE OR REPLACE FUNCTION trg_szamla_sztorno()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF NEW.statusz = 'sztorno' AND OLD.statusz IS DISTINCT FROM 'sztorno' AND EXISTS (
        SELECT 1 FROM fizetes WHERE szamla_id = NEW.szamla_id
    ) THEN
        RAISE EXCEPTION 'Befizetett számla nem sztornózható. Előbb a pénzügyi rendezés kell.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER szamla_sztorno
BEFORE UPDATE OF statusz ON szamla
FOR EACH ROW EXECUTE FUNCTION trg_szamla_sztorno();

CREATE OR REPLACE FUNCTION trg_audit_naplo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_new jsonb;
    v_old jsonb;
    v_forras jsonb;
    v_id text;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        v_old := to_jsonb(OLD);
    END IF;
    IF TG_OP <> 'DELETE' THEN
        v_new := to_jsonb(NEW);
    END IF;

    v_forras := COALESCE(v_new, v_old);
    v_id := COALESCE(
        v_forras->>'felvetel_id',
        v_forras->>'vizit_id',
        v_forras->>'fizetes_id',
        v_forras->>'mozgas_id'
    );

    INSERT INTO audit_naplo (tabla_nev, muvelet, rekord_id, regi_adatok, uj_adatok)
    VALUES (TG_TABLE_NAME, TG_OP, COALESCE(v_id, '?'), v_old, v_new);

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER felvetel_audit
AFTER INSERT OR UPDATE OR DELETE ON felvetel
FOR EACH ROW EXECUTE FUNCTION trg_audit_naplo();

CREATE TRIGGER vizit_audit
AFTER INSERT OR UPDATE OR DELETE ON vizit
FOR EACH ROW EXECUTE FUNCTION trg_audit_naplo();

CREATE TRIGGER fizetes_audit
AFTER INSERT OR UPDATE OR DELETE ON fizetes
FOR EACH ROW EXECUTE FUNCTION trg_audit_naplo();

CREATE TRIGGER keszlet_audit
AFTER INSERT OR UPDATE OR DELETE ON keszlet_mozgas
FOR EACH ROW EXECUTE FUNCTION trg_audit_naplo();
