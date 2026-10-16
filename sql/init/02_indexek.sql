-- Lumen Klinika
-- 02 Indexek. A PostgreSQL az idegen kulcsokra nem hoz létre automatikusan indexet.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Idegen kulcsok, amelyeken szűrés és törlés is fut.
CREATE INDEX ix_orvos_osztaly ON orvos (osztaly_id);
CREATE INDEX ix_apolo_osztaly ON apolo (osztaly_id);
CREATE INDEX ix_osztaly_vezeto ON osztaly (vezeto_orvos_id);
CREATE INDEX ix_korterem_osztaly ON korterem (osztaly_id);
CREATE INDEX ix_agy_korterem ON agy (korterem_id);
CREATE INDEX ix_felvetel_beteg ON felvetel (beteg_id);
CREATE INDEX ix_felvetel_agy ON felvetel (agy_id);
CREATE INDEX ix_felvetel_orvos ON felvetel (felvevo_orvos_id);
CREATE INDEX ix_felvetel_diagnozis_kod ON felvetel_diagnozis (diagnozis_kod);
CREATE INDEX ix_vizit_beteg ON vizit (beteg_id);
CREATE INDEX ix_vizit_orvos_ido ON vizit (orvos_id, idopont_kezdet);
CREATE INDEX ix_veny_beteg ON veny (beteg_id);
CREATE INDEX ix_veny_orvos ON veny (orvos_id);
CREATE INDEX ix_veny_vizit ON veny (vizit_id);
CREATE INDEX ix_veny_felvetel ON veny (felvetel_id);
CREATE INDEX ix_veny_tetel_veny ON veny_tetel (veny_id);
CREATE INDEX ix_veny_tetel_gyogyszer ON veny_tetel (gyogyszer_id);
CREATE INDEX ix_keszlet_gyogyszer ON keszlet_mozgas (gyogyszer_id);
CREATE INDEX ix_keszlet_tetel ON keszlet_mozgas (veny_tetel_id);
CREATE INDEX ix_labor_beteg_ido ON labor_lelet (beteg_id, mintavetel_idopont DESC);
CREATE INDEX ix_labor_tipus ON labor_lelet (tipus_id);
CREATE INDEX ix_labor_orvos ON labor_lelet (kert_orvos_id);
CREATE INDEX ix_szamla_beteg ON szamla (beteg_id);
CREATE INDEX ix_szamla_tetel_szamla ON szamla_tetel (szamla_id);
CREATE INDEX ix_szamla_tetel_szolg ON szamla_tetel (szolgaltatas_id);
CREATE INDEX ix_fizetes_szamla ON fizetes (szamla_id);

-- Keresés névrészletre a betegfelvételen.
CREATE INDEX ix_beteg_nev ON beteg (vezeteknev, keresztnev);
CREATE INDEX ix_beteg_nev_trgm ON beteg
    USING gin ((vezeteknev || ' ' || keresztnev) gin_trgm_ops);

-- Részleges indexek: a gyakori, szűk halmaz.
CREATE UNIQUE INDEX ux_felvetel_egy_fo_diagnozis
    ON felvetel_diagnozis (felvetel_id)
    WHERE tipus = 'fo';

CREATE UNIQUE INDEX ux_aktiv_felvetel_beteg
    ON felvetel (beteg_id)
    WHERE statusz = 'aktiv';

CREATE UNIQUE INDEX ux_aktiv_felvetel_agy
    ON felvetel (agy_id)
    WHERE statusz = 'aktiv';

CREATE UNIQUE INDEX ux_kiadas_egyszer
    ON keszlet_mozgas (veny_tetel_id)
    WHERE ok = 'kiadas';

CREATE INDEX ix_szamla_nyitott_hatarido
    ON szamla (hatarido)
    WHERE statusz = 'nyitott';

CREATE INDEX ix_audit_tabla_ido
    ON audit_naplo (tabla_nev, ido DESC);
