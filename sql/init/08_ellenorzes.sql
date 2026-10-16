-- Lumen Klinika
-- 08 Ellenőrzés. Ha egy szabály nem teljesül, a szkript hibával áll meg.
-- A módosító próbák saját blokkban futnak, és visszagörgetődnek.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

DO $$
BEGIN
    IF (SELECT count(*) FROM beteg) <> 24 THEN
        RAISE EXCEPTION 'HIBA: 24 betegnek kell lennie.';
    END IF;
    IF (SELECT count(*) FROM v_aktiv_fekvobetegek) <> 8 THEN
        RAISE EXCEPTION 'HIBA: 8 aktív felvételnek kell látszania.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 1) <> 'foglalt' THEN
        RAISE EXCEPTION 'HIBA: az 1-es ágynak foglaltnak kell lennie.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 3) <> 'szabad' THEN
        RAISE EXCEPTION 'HIBA: a 3-as ágynak szabadnak kell lennie.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 4) <> 'karbantartas' THEN
        RAISE EXCEPTION 'HIBA: a 4-es ágy karbantartás alatt van.';
    END IF;
    IF (SELECT count(*) FROM osztaly WHERE vezeto_orvos_id IS NOT NULL) <> 6 THEN
        RAISE EXCEPTION 'HIBA: mind a hat osztálynak vezetőt kell kapnia.';
    END IF;
    IF (SELECT count(*) FROM audit_naplo) = 0 THEN
        RAISE EXCEPTION 'HIBA: az audit napló üres.';
    END IF;
    IF (SELECT statusz FROM szamla WHERE szamla_id = 4) <> 'fizetve' THEN
        RAISE EXCEPTION 'HIBA: a kiegyenlített számla nem került fizetve állapotba.';
    END IF;
    IF (SELECT statusz FROM szamla WHERE szamla_id = 3) <> 'nyitott' THEN
        RAISE EXCEPTION 'HIBA: a részben fizetett számlának nyitottnak kell maradnia.';
    END IF;
    IF (SELECT count(*) FROM v_lejaro_szamlak WHERE szamla_id IN (1, 3)) <> 2 THEN
        RAISE EXCEPTION 'HIBA: a lejárt nyitott számlák nézete hibás.';
    END IF;
    IF (SELECT brutto_osszeg FROM szamla_tetel WHERE tetel_id = 6) <> 6350.00 THEN
        RAISE EXCEPTION 'HIBA: a 27%%-os igazolás bruttója nem 6350.';
    END IF;
    IF (SELECT count(*) FROM v_alacsony_keszlet WHERE gyogyszer_id IN (3, 8)) <> 2 THEN
        RAISE EXCEPTION 'HIBA: az alacsony készlet nézete nem a várt gyógyszereket adja.';
    END IF;
    IF (SELECT keszlet FROM v_gyogyszer_keszlet WHERE gyogyszer_id = 3) <> 1 THEN
        RAISE EXCEPTION 'HIBA: az amoxicillin készlete 1 kell legyen.';
    END IF;
    IF (SELECT count(*) FROM v_labor_riasztas) < 4 THEN
        RAISE EXCEPTION 'HIBA: kevés a referenciatartományon kívüli lelet.';
    END IF;
    IF (SELECT count(*) FROM v_mai_elojegyzes) < 10 THEN
        RAISE EXCEPTION 'HIBA: a mai előjegyzés nézet üres vagy hiányos.';
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM vizit tervezett
        JOIN vizit lemondott
          ON lemondott.orvos_id = tervezett.orvos_id
         AND lemondott.vizit_id <> tervezett.vizit_id
         AND lemondott.statusz = 'lemondott'
         AND tervezett.statusz = 'tervezett'
         AND tstzrange(lemondott.idopont_kezdet, lemondott.idopont_vege, '[)')
             && tstzrange(tervezett.idopont_kezdet, tervezett.idopont_vege, '[)')
    ) THEN
        RAISE EXCEPTION 'HIBA: a lemondott rendelésnek nem kellene foglalnia az idősávot.';
    END IF;
    IF EXISTS (
        SELECT felvetel_id
        FROM felvetel_diagnozis
        WHERE tipus = 'fo'
        GROUP BY felvetel_id
        HAVING count(*) <> 1
    ) OR EXISTS (
        SELECT f.felvetel_id
        FROM felvetel f
        WHERE NOT EXISTS (
            SELECT 1 FROM felvetel_diagnozis d
            WHERE d.felvetel_id = f.felvetel_id AND d.tipus = 'fo'
        )
    ) THEN
        RAISE EXCEPTION 'HIBA: nem pontosan egy fődiagnózis tartozik minden felvételhez.';
    END IF;
END
$$;

-- Hibás TAJ.
DO $$
BEGIN
    BEGIN
        INSERT INTO beteg (vezeteknev, keresztnev, taj_szam, szuletesi_datum, nem)
        VALUES ('Teszt', 'Rossz', '123456789', DATE '1990-01-01', 'ferfi');
        RAISE EXCEPTION 'HIBA: a hibás TAJ-t a séma elfogadta.';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Jövőbeli születési dátum.
DO $$
BEGIN
    BEGIN
        INSERT INTO beteg (vezeteknev, keresztnev, taj_szam, szuletesi_datum, nem)
        VALUES ('Teszt', 'Jövő', '555544440', CURRENT_DATE + 1, 'no');
        RAISE EXCEPTION 'HIBA: jövőbeli születési dátum bekerült.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Ütköző rendelés.
DO $$
BEGIN
    BEGIN
        INSERT INTO vizit (beteg_id, orvos_id, idopont_kezdet, idopont_vege, statusz)
        VALUES (
            13, 1,
            CURRENT_DATE + TIME '08:00',
            CURRENT_DATE + TIME '08:20',
            'tervezett'
        );
        RAISE EXCEPTION 'HIBA: ütköző rendelés létrejött.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Karbantartás alatti ágy.
DO $$
BEGIN
    BEGIN
        INSERT INTO felvetel (beteg_id, agy_id, felvevo_orvos_id, felvetel_idopont, statusz)
        VALUES (9, 4, 1, now(), 'aktiv');
        RAISE EXCEPTION 'HIBA: karbantartott ágyra felvétel került.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Felnőtt a gyermekosztályon.
DO $$
BEGIN
    BEGIN
        INSERT INTO felvetel (beteg_id, agy_id, felvevo_orvos_id, felvetel_idopont, statusz)
        VALUES (9, 18, 8, now(), 'aktiv');
        RAISE EXCEPTION 'HIBA: felnőtt került a gyermekgyógyászatra.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Második aktív felvétel ugyanarra a betegre.
DO $$
BEGIN
    BEGIN
        INSERT INTO felvetel (beteg_id, agy_id, felvevo_orvos_id, felvetel_idopont, statusz)
        VALUES (1, 3, 1, now(), 'aktiv');
        RAISE EXCEPTION 'HIBA: a betegnek két aktív felvétele lett.';
    EXCEPTION
        WHEN exclusion_violation OR unique_violation THEN
            NULL;
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Negatív készlet.
DO $$
BEGIN
    BEGIN
        INSERT INTO keszlet_mozgas (gyogyszer_id, mennyiseg, ok, megjegyzes)
        VALUES (1, -1000, 'korrekcio', 'teszt');
        RAISE EXCEPTION 'HIBA: a készlet nulla alá ment.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Készletnapló törlése.
DO $$
BEGIN
    BEGIN
        DELETE FROM keszlet_mozgas
        WHERE mozgas_id = (SELECT min(mozgas_id) FROM keszlet_mozgas);
        RAISE EXCEPTION 'HIBA: készletsort törölni lehetett.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Túlzott befizetés.
DO $$
BEGIN
    BEGIN
        INSERT INTO fizetes (szamla_id, osszeg, fizetes_mod)
        VALUES (2, 999999, 'kartya');
        RAISE EXCEPTION 'HIBA: a számla végösszegénél nagyobb befizetés bekerült.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Orvos és ápoló ugyanaz a személy.
DO $$
BEGIN
    BEGIN
        INSERT INTO apolo (alkalmazott_id, oklevel_szam, osztaly_id)
        VALUES (1, 'AP-TESZT', 1);
        RAISE EXCEPTION 'HIBA: az orvos ápolóként is felvehető volt.';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'HIBA:%' THEN
                RAISE;
            END IF;
    END;
END
$$;

-- Elbocsátás, áthelyezés, felvétel, vénykiadás: hatás, majd visszagörgetés.
DO $$
DECLARE
    v_agy integer;
    v_keszlet integer;
BEGIN
    CALL sp_beteg_elbocsatasa(1);
    SELECT agy_id INTO v_agy FROM felvetel WHERE felvetel_id = 1;
    IF (SELECT statusz FROM felvetel WHERE felvetel_id = 1) <> 'lezart' THEN
        RAISE EXCEPTION 'HIBA: az elbocsátás nem zárta a felvételt.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = v_agy) <> 'szabad' THEN
        RAISE EXCEPTION 'HIBA: az elbocsátás nem szabadította fel az ágyat.';
    END IF;

    RAISE EXCEPTION 'ROLLBACK_TESZT';
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE 'HIBA:%' OR SQLERRM IS DISTINCT FROM 'ROLLBACK_TESZT' THEN
            RAISE;
        END IF;
END
$$;

DO $$
BEGIN
    CALL sp_agy_attesz(1, 3);
    IF (SELECT agy_id FROM felvetel WHERE felvetel_id = 1) <> 3 THEN
        RAISE EXCEPTION 'HIBA: az áthelyezés nem történt meg.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 1) <> 'szabad'
       OR (SELECT statusz FROM agy WHERE agy_id = 3) <> 'foglalt' THEN
        RAISE EXCEPTION 'HIBA: az ágyak állapota áthelyezés után hibás.';
    END IF;
    RAISE EXCEPTION 'ROLLBACK_TESZT';
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE 'HIBA:%' OR SQLERRM IS DISTINCT FROM 'ROLLBACK_TESZT' THEN
            RAISE;
        END IF;
END
$$;

DO $$
BEGIN
    CALL sp_beteg_felvetele(10, 3, 2, 'I10', now());
    IF NOT EXISTS (
        SELECT 1
        FROM felvetel f
        JOIN felvetel_diagnozis d ON d.felvetel_id = f.felvetel_id
        WHERE f.beteg_id = 10
          AND f.statusz = 'aktiv'
          AND d.tipus = 'fo'
          AND d.diagnozis_kod = 'I10'
    ) THEN
        RAISE EXCEPTION 'HIBA: a felvételi eljárás nem hozta létre a fődiagnózist.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 3) <> 'foglalt' THEN
        RAISE EXCEPTION 'HIBA: az új felvétel nem foglalta az ágyat.';
    END IF;
    RAISE EXCEPTION 'ROLLBACK_TESZT';
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE 'HIBA:%' OR SQLERRM IS DISTINCT FROM 'ROLLBACK_TESZT' THEN
            RAISE;
        END IF;
END
$$;

DO $$
DECLARE
    v_keszlet integer;
BEGIN
    SELECT keszlet INTO v_keszlet FROM v_gyogyszer_keszlet WHERE gyogyszer_id = 2;
    CALL sp_veny_kiad(4);
    IF NOT EXISTS (SELECT 1 FROM veny_tetel WHERE veny_tetel_id = 4 AND kiadva) THEN
        RAISE EXCEPTION 'HIBA: a vénykiadás nem jelölte kiadottnak a tételt.';
    END IF;
    IF (SELECT keszlet FROM v_gyogyszer_keszlet WHERE gyogyszer_id = 2) <> v_keszlet - 1 THEN
        RAISE EXCEPTION 'HIBA: a vénykiadás nem csökkentette a készletet.';
    END IF;
    RAISE EXCEPTION 'ROLLBACK_TESZT';
EXCEPTION
    WHEN raise_exception THEN
        IF SQLERRM LIKE 'HIBA:%' OR SQLERRM IS DISTINCT FROM 'ROLLBACK_TESZT' THEN
            RAISE;
        END IF;
END
$$;

DO $$
BEGIN
    IF (SELECT statusz FROM felvetel WHERE felvetel_id = 1) <> 'aktiv' THEN
        RAISE EXCEPTION 'HIBA: a teszt elbocsátás végleges maradt.';
    END IF;
    IF (SELECT agy_id FROM felvetel WHERE felvetel_id = 1) <> 1 THEN
        RAISE EXCEPTION 'HIBA: a teszt áthelyezés végleges maradt.';
    END IF;
    IF (SELECT statusz FROM agy WHERE agy_id = 3) <> 'szabad' THEN
        RAISE EXCEPTION 'HIBA: a 3-as ágy a tesztek után nem szabad.';
    END IF;
    IF EXISTS (SELECT 1 FROM felvetel WHERE beteg_id = 10 AND statusz = 'aktiv') THEN
        RAISE EXCEPTION 'HIBA: a tesztfelvétel végleges maradt.';
    END IF;
    IF EXISTS (SELECT 1 FROM veny_tetel WHERE veny_tetel_id = 4 AND kiadva) THEN
        RAISE EXCEPTION 'HIBA: a teszt vénykiadás végleges maradt.';
    END IF;
    IF (SELECT keszlet FROM v_gyogyszer_keszlet WHERE gyogyszer_id = 2) <> 40 THEN
        RAISE EXCEPTION 'HIBA: az ibuprofen készlete a teszt után megváltozott.';
    END IF;
END
$$;
