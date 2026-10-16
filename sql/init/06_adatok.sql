-- Lumen Klinika
-- 06 Mintaadatok. A dátumok a betöltés napjához képest relatívak,
-- ezért a "mai rendelés" és a "lejárt számla" később is értelmes marad.
-- A TAJ-számok a 01_sema.sql ellenőrző jegyének megfelelnek.

SET client_encoding = 'UTF8';
SET TIME ZONE 'Europe/Budapest';

INSERT INTO diagnozis (kod, megnevezes, kategoria) VALUES
    ('I10', 'Magas vérnyomás', 'Keringés'),
    ('I21', 'Akut szívizominfarktus', 'Keringés'),
    ('I50', 'Szívelégtelenség', 'Keringés'),
    ('E11', '2-es típusú cukorbetegség', 'Anyagcsere'),
    ('E78', 'Zsíranyagcsere-zavar', 'Anyagcsere'),
    ('J06', 'Felső légúti fertőzés', 'Légzőszerv'),
    ('J45', 'Asztma', 'Légzőszerv'),
    ('J20', 'Akut hörghurut', 'Légzőszerv'),
    ('S72', 'Combcsonttörés', 'Sérülés'),
    ('K35', 'Heveny vakbélgyulladás', 'Emésztés'),
    ('G40', 'Epilepszia', 'Idegrendszer'),
    ('G43', 'Migrén', 'Idegrendszer'),
    ('N39', 'Húgyúti fertőzés', 'Urogenitális'),
    ('Z00', 'Általános vizsgálat', 'Egyéb');

INSERT INTO labor_tipus (tipus_id, kod, nev, mertekegyseg, ref_min, ref_max) VALUES
    (1, 'HGB', 'Hemoglobin', 'g/L', 120, 160),
    (2, 'CRP', 'C-reaktív protein', 'mg/L', 0, 5),
    (3, 'GLU', 'Vércukor', 'mmol/L', 3.9, 5.6),
    (4, 'K', 'Kálium', 'mmol/L', 3.5, 5.1),
    (5, 'WBC', 'Fehérvérsejt', '10^9/L', 4.0, 10.0);

INSERT INTO szolgaltatas (szolgaltatas_id, kod, nev, netto_egysegar, afa_kulcs) VALUES
    (1, 'SZV', 'Szakorvosi vizsgálat', 20000, 0),
    (2, 'KON', 'Kontrollvizsgálat', 12000, 0),
    (3, 'LAB', 'Laborvizsgálat', 8000, 0),
    (4, 'NAP', 'Fekvőbeteg ápolási nap', 35000, 0),
    (5, 'IGA', 'Orvosi igazolás', 5000, 27),
    (6, 'UH', 'Ultrahang', 18000, 0);

INSERT INTO gyogyszer (gyogyszer_id, nev, hatoanyag, kiszereles, venykoteles) VALUES
    (1, 'Paracetamol', 'paracetamol', '500 mg tabletta', false),
    (2, 'Ibuprofen', 'ibuprofen', '400 mg tabletta', false),
    (3, 'Amoxicillin', 'amoxicillin', '500 mg kapszula', true),
    (4, 'Bisoprolol', 'bisoprolol', '5 mg tabletta', true),
    (5, 'Metformin', 'metformin', '1000 mg tabletta', true),
    (6, 'Amlodipin', 'amlodipin', '5 mg tabletta', true),
    (7, 'Atorvasztatin', 'atorvasztatin', '20 mg tabletta', true),
    (8, 'Szalbutamol', 'szalbutamol', 'inhalációs adagoló', true),
    (9, 'Omeprazol', 'omeprazol', '20 mg kapszula', true),
    (10, 'Acetilszalicilsav', 'acetilszalicilsav', '100 mg tabletta', false);

INSERT INTO osztaly (osztaly_id, kod, nev, epulet, emelet, leiras) VALUES
    (1, 'BEL', 'Belgyógyászat', 'A', 2, 'Általános belgyógyászati ellátás'),
    (2, 'SEB', 'Sebészet', 'A', 3, 'Általános és baleseti sebészet'),
    (3, 'KAR', 'Kardiológia', 'B', 1, 'Kardiológiai őrzés és gondozás'),
    (4, 'NEU', 'Neurológia', 'B', 2, 'Neurológiai fekvő- és járóbeteg-ellátás'),
    (5, 'GYE', 'Gyermekgyógyászat', 'C', 1, '18 év alatti betegek osztálya'),
    (6, 'SUR', 'Sürgősségi ellátás', 'A', 0, 'Sürgősségi felvétel');

INSERT INTO alkalmazott (
    alkalmazott_id, vezeteknev, keresztnev, szuletesi_datum, email, telefon, felvetel_datuma
) VALUES
    (1, 'Kovács', 'Anna', DATE '1978-04-12', 'anna.kovacs@lumen-klinika.example', '+36301110001', DATE '2012-02-01'),
    (2, 'Szabó', 'László', DATE '1972-11-03', 'laszlo.szabo@lumen-klinika.example', '+36301110002', DATE '2008-09-01'),
    (3, 'Tóth', 'Gábor', DATE '1969-06-21', 'gabor.toth@lumen-klinika.example', '+36301110003', DATE '2005-03-15'),
    (4, 'Horváth', 'Eszter', DATE '1984-02-14', 'eszter.horvath@lumen-klinika.example', '+36301110004', DATE '2016-06-01'),
    (5, 'Varga', 'Péter', DATE '1975-09-30', 'peter.varga@lumen-klinika.example', '+36301110005', DATE '2010-01-10'),
    (6, 'Kiss', 'Nóemi', DATE '1988-01-19', 'noemi.kiss@lumen-klinika.example', '+36301110006', DATE '2018-04-01'),
    (7, 'Molnár', 'István', DATE '1970-12-08', 'istvan.molnar@lumen-klinika.example', '+36301110007', DATE '2006-11-01'),
    (8, 'Németh', 'Júlia', DATE '1982-05-25', 'julia.nemeth@lumen-klinika.example', '+36301110008', DATE '2014-08-20'),
    (9, 'Farkas', 'Balázs', DATE '1979-07-07', 'balazs.farkas@lumen-klinika.example', '+36301110009', DATE '2011-05-02'),
    (10, 'Balogh', 'Katalin', DATE '1990-03-16', 'katalin.balogh@lumen-klinika.example', '+36301110010', DATE '2019-09-01'),
    (11, 'Oláh', 'Mária', DATE '1986-08-02', 'maria.olah@lumen-klinika.example', '+36302220011', DATE '2015-02-01'),
    (12, 'Simon', 'Réka', DATE '1992-10-11', 'reka.simon@lumen-klinika.example', '+36302220012', DATE '2017-03-01'),
    (13, 'Fekete', 'Andrea', DATE '1985-04-04', 'andrea.fekete@lumen-klinika.example', '+36302220013', DATE '2013-07-01'),
    (14, 'Papp', 'Zsófia', DATE '1991-01-28', 'zsofia.papp@lumen-klinika.example', '+36302220014', DATE '2016-10-01'),
    (15, 'Takács', 'Dóra', DATE '1994-06-06', 'dora.takacs@lumen-klinika.example', '+36302220015', DATE '2020-01-15'),
    (16, 'Juhász', 'Petra', DATE '1987-09-09', 'petra.juhasz@lumen-klinika.example', '+36302220016', DATE '2014-04-01'),
    (17, 'Nagy', 'Katalin', DATE '1983-03-03', 'katalin.nagy@lumen-klinika.example', '+36303330017', DATE '2012-01-09'),
    (18, 'Kiss', 'Gergő', DATE '1993-11-23', 'gergo.kiss@lumen-klinika.example', '+36303330018', DATE '2019-02-01');

INSERT INTO orvos (alkalmazott_id, pecsetszam, szakvizsga, osztaly_id) VALUES
    (1, '10001', 'Belgyógyászat', 1),
    (2, '10002', 'Endokrinológia', 1),
    (3, '10003', 'Traumatológia', 2),
    (4, '10004', 'Általános sebészet', 2),
    (5, '10005', 'Kardiológia', 3),
    (6, '10006', 'Kardiológia', 3),
    (7, '10007', 'Neurológia', 4),
    (8, '10008', 'Gyermekgyógyászat', 5),
    (9, '10009', 'Sürgősségi orvostan', 6),
    (10, '10010', 'Sürgősségi orvostan', 6);

INSERT INTO apolo (alkalmazott_id, oklevel_szam, osztaly_id) VALUES
    (11, 'AP-2015-011', 1),
    (12, 'AP-2017-012', 2),
    (13, 'AP-2013-013', 3),
    (14, 'AP-2016-014', 4),
    (15, 'AP-2020-015', 5),
    (16, 'AP-2014-016', 6);

UPDATE osztaly SET vezeto_orvos_id = 1 WHERE osztaly_id = 1;
UPDATE osztaly SET vezeto_orvos_id = 3 WHERE osztaly_id = 2;
UPDATE osztaly SET vezeto_orvos_id = 5 WHERE osztaly_id = 3;
UPDATE osztaly SET vezeto_orvos_id = 7 WHERE osztaly_id = 4;
UPDATE osztaly SET vezeto_orvos_id = 8 WHERE osztaly_id = 5;
UPDATE osztaly SET vezeto_orvos_id = 9 WHERE osztaly_id = 6;

INSERT INTO beteg (
    beteg_id, taj_szam, vezeteknev, keresztnev, szuletesi_datum, nem,
    email, telefon, iranyitoszam, varos, utca, regisztracio_datuma
) VALUES
    (1, '037654320', 'Nagy', 'Péter', DATE '1952-03-14', 'ferfi', 'peter.nagy@example.com', '+36201110001', '1051', 'Budapest', 'Széchenyi utca 4.', CURRENT_DATE - 800),
    (2, '112233440', 'Szűcs', 'Ilona', DATE '1948-11-02', 'no', 'ilona.szucs@example.com', '+36201110002', '4024', 'Debrecen', 'Piac utca 18.', CURRENT_DATE - 600),
    (3, '201945188', 'Kiss', 'Bence', DATE '1991-06-21', 'ferfi', 'bence.kiss@example.com', '+36201110003', '9021', 'Győr', 'Baross út 9.', CURRENT_DATE - 120),
    (4, '334455660', 'Tóth', 'Márk', DATE '1984-01-30', 'ferfi', 'mark.toth@example.com', '+36201110004', '6720', 'Szeged', 'Kárász utca 7.', CURRENT_DATE - 90),
    (5, '445566770', 'Horváth', 'Máté', DATE '1976-09-12', 'ferfi', 'mate.horvath@example.com', '+36201110005', '7621', 'Pécs', 'Király utca 22.', CURRENT_DATE - 400),
    (6, '556677880', 'Váradi', 'Katalin', DATE '1963-04-08', 'no', 'katalin.varadi@example.com', '+36201110006', '3525', 'Miskolc', 'Széchenyi utca 11.', CURRENT_DATE - 200),
    (7, '667788990', 'Bodnár', 'Gergő', DATE '2001-12-19', 'ferfi', 'gergo.bodnar@example.com', '+36201110007', '1024', 'Budapest', 'Retek utca 3.', CURRENT_DATE - 30),
    (8, '778899000', 'Fekete', 'Judit', DATE '1958-07-25', 'no', 'judit.fekete@example.com', '+36201110008', '8000', 'Székesfehérvár', 'Fő utca 15.', CURRENT_DATE - 500),
    (9, '889900110', 'Pintér', 'Ádám', DATE '1988-02-17', 'ferfi', 'adam.pinter@example.com', '+36201110009', '3300', 'Eger', 'Dobó tér 2.', CURRENT_DATE - 150),
    (10, '990011220', 'Szalai', 'Emese', DATE '1995-10-05', 'no', 'emese.szalai@example.com', '+36201110010', '9400', 'Sopron', 'Várkerület 8.', CURRENT_DATE - 80),
    (11, '102938478', 'Kocsis', 'László', DATE '1972-08-23', 'ferfi', 'laszlo.kocsis@example.com', '+36201110011', '6000', 'Kecskemét', 'Rákóczi út 6.', CURRENT_DATE - 300),
    (12, '564738292', 'Orbán', 'Petra', DATE '1999-05-14', 'no', 'petra.orban@example.com', '+36201110012', '8200', 'Veszprém', 'Kossuth utca 19.', CURRENT_DATE - 40),
    (13, '135792463', 'Magyar', 'Dániel', DATE '1982-03-03', 'ferfi', 'daniel.magyar@example.com', '+36201110013', '4400', 'Nyíregyháza', 'Bethlen utca 5.', CURRENT_DATE - 220),
    (14, '246801359', 'Verebes', 'Hanga', DATE '1979-12-01', 'no', 'hanga.verebes@example.com', '+36201110014', '9700', 'Szombathely', 'Fő tér 1.', CURRENT_DATE - 260),
    (15, '314159261', 'Antal', 'Zoltán', DATE '1966-06-06', 'ferfi', 'zoltan.antal@example.com', '+36201110015', '2800', 'Tatabánya', 'Komáromi utca 14.', CURRENT_DATE - 110),
    (16, '271828185', 'Csonka', 'Lilla', DATE '2004-09-18', 'no', 'lilla.csonka@example.com', '+36201110016', '1132', 'Budapest', 'Váci út 40.', CURRENT_DATE - 15),
    (17, '161803397', 'Bíró', 'Tamás', DATE '1955-01-11', 'ferfi', 'tamas.biro@example.com', '+36201110017', '6500', 'Baja', 'Deák Ferenc utca 9.', CURRENT_DATE - 340),
    (18, '141421359', 'Jakab', 'Fanni', DATE '1993-04-27', 'no', 'fanni.jakab@example.com', '+36201110018', '8900', 'Zalaegerszeg', 'Kossuth utca 3.', CURRENT_DATE - 18),
    (19, '173205086', 'Hegedűs', 'Nóra', DATE '2016-02-02', 'no', 'nora.hegedus@example.com', '+36201110019', '1052', 'Budapest', 'Petőfi Sándor utca 6.', CURRENT_DATE - 70),
    (20, '223606797', 'Lukács', 'Dóra', DATE '2018-08-30', 'no', 'dora.lukacs@example.com', '+36201110020', '4025', 'Debrecen', 'Sumen utca 2.', CURRENT_DATE - 10),
    (21, '264575135', 'Fodor', 'Levente', DATE '2014-05-19', 'ferfi', 'levente.fodor@example.com', '+36201110021', '9022', 'Győr', 'Liszt Ferenc utca 12.', CURRENT_DATE - 95),
    (22, '304080768', 'Somogyi', 'Áron', DATE '2019-11-11', 'ferfi', NULL, NULL, '7622', 'Pécs', 'Rákóczi út 1.', CURRENT_DATE - 8),
    (23, '123456788', 'Balázs', 'Kinga', DATE '1944-10-10', 'no', NULL, '+36201110023', '6722', 'Szeged', 'Tisza Lajos körút 24.', CURRENT_DATE - 900),
    (24, '876543212', 'Varga', 'Bence', DATE '1990-07-07', 'ferfi', NULL, NULL, '1037', 'Budapest', 'Bojtár utca 8.', CURRENT_DATE - 5);

INSERT INTO korterem (korterem_id, osztaly_id, szam) VALUES
    (1, 1, '101'), (2, 1, '102'),
    (3, 2, '201'), (4, 2, '202'),
    (5, 3, '301'), (6, 3, '302'),
    (7, 4, '401'), (8, 4, '402'),
    (9, 5, '501'), (10, 5, '502'),
    (11, 6, '001'), (12, 6, '002');

INSERT INTO agy (agy_id, korterem_id, agy_szam) VALUES
    (1, 1, 1), (2, 1, 2),
    (3, 2, 1), (4, 2, 2),
    (5, 3, 1), (6, 3, 2),
    (7, 4, 1), (8, 4, 2),
    (9, 5, 1), (10, 5, 2),
    (11, 6, 1), (12, 6, 2),
    (13, 7, 1), (14, 7, 2),
    (15, 8, 1), (16, 8, 2),
    (17, 9, 1), (18, 9, 2),
    (19, 10, 1), (20, 10, 2),
    (21, 11, 1), (22, 11, 2),
    (23, 12, 1), (24, 12, 2);

UPDATE agy SET statusz = 'karbantartas' WHERE agy_id = 4;

-- A fődiagnózis kötelező, de a megszorítás csak a tranzakció végén fut,
-- ezért a felvétel és a diagnózis egy tranzakció.
BEGIN;

INSERT INTO felvetel (
    felvetel_id, beteg_id, agy_id, felvevo_orvos_id, felvetel_idopont, elbocsatas_idopont, statusz
) VALUES
    (1, 1, 1, 1, (CURRENT_DATE - 3) + TIME '08:00', NULL, 'aktiv'),
    (2, 2, 2, 2, (CURRENT_DATE - 1) + TIME '09:00', NULL, 'aktiv'),
    (3, 3, 5, 3, (CURRENT_DATE - 5) + TIME '11:00', NULL, 'aktiv'),
    (4, 4, 9, 5, (CURRENT_DATE - 2) + TIME '14:00', NULL, 'aktiv'),
    (5, 5, 13, 7, (CURRENT_DATE - 4) + TIME '10:00', NULL, 'aktiv'),
    (6, 19, 17, 8, (CURRENT_DATE - 1) + TIME '08:30', NULL, 'aktiv'),
    (7, 7, 21, 9, CURRENT_DATE + TIME '06:00', NULL, 'aktiv'),
    (8, 8, 10, 6, (CURRENT_DATE - 6) + TIME '16:00', NULL, 'aktiv'),
    (9, 1, 1, 1, (CURRENT_DATE - 50) + TIME '10:00', (CURRENT_DATE - 44) + TIME '11:00', 'lezart'),
    (10, 9, 6, 4, (CURRENT_DATE - 60) + TIME '08:00', (CURRENT_DATE - 55) + TIME '09:00', 'lezart'),
    (11, 10, 11, 5, (CURRENT_DATE - 40) + TIME '09:00', (CURRENT_DATE - 35) + TIME '10:00', 'lezart'),
    (12, 23, 3, 2, (CURRENT_DATE - 70) + TIME '12:00', (CURRENT_DATE - 58) + TIME '09:00', 'lezart'),
    (13, 11, 14, 7, (CURRENT_DATE - 25) + TIME '08:00', (CURRENT_DATE - 22) + TIME '15:00', 'lezart'),
    (14, 21, 18, 8, (CURRENT_DATE - 30) + TIME '09:00', (CURRENT_DATE - 27) + TIME '10:00', 'lezart');

INSERT INTO felvetel_diagnozis (felvetel_id, diagnozis_kod, tipus) VALUES
    (1, 'I10', 'fo'),
    (1, 'E78', 'mellek'),
    (2, 'E11', 'fo'),
    (3, 'S72', 'fo'),
    (4, 'I21', 'fo'),
    (4, 'E11', 'mellek'),
    (5, 'G40', 'fo'),
    (6, 'J45', 'fo'),
    (7, 'J06', 'fo'),
    (8, 'I50', 'fo'),
    (8, 'I10', 'mellek'),
    (9, 'J06', 'fo'),
    (10, 'K35', 'fo'),
    (11, 'I10', 'fo'),
    (12, 'I50', 'fo'),
    (13, 'G43', 'fo'),
    (14, 'J20', 'fo');

COMMIT;

INSERT INTO vizit (
    vizit_id, beteg_id, orvos_id, idopont_kezdet, idopont_vege, statusz, panasz
) VALUES
    (1, 9, 1, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '08:20', 'tervezett', 'Mellkasi szorítás'),
    (2, 10, 1, CURRENT_DATE + TIME '08:30', CURRENT_DATE + TIME '08:50', 'tervezett', 'Kontroll'),
    (3, 12, 1, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '09:20', 'megjelent', 'Fáradékonyság'),
    (4, 11, 1, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '08:20', 'lemondott', 'A beteg lemondta'),
    (5, 13, 2, CURRENT_DATE + TIME '08:00', CURRENT_DATE + TIME '08:30', 'tervezett', 'Vércukor-beállítás'),
    (6, 15, 2, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '09:30', 'tervezett', 'Kontroll'),
    (7, 1, 2, CURRENT_DATE + TIME '11:00', CURRENT_DATE + TIME '11:30', 'tervezett', 'Bent fekvő beteg konzíliuma'),
    (8, 16, 3, CURRENT_DATE + TIME '11:00', CURRENT_DATE + TIME '11:30', 'tervezett', 'Bokatáji fájdalom'),
    (9, 14, 5, CURRENT_DATE + TIME '10:00', CURRENT_DATE + TIME '10:30', 'tervezett', 'Szívritmuszavar'),
    (10, 17, 5, CURRENT_DATE + TIME '10:30', CURRENT_DATE + TIME '11:00', 'tervezett', 'Magas vérnyomás'),
    (11, 18, 6, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '09:20', 'tervezett', 'Mellkasi panasz'),
    (12, 6, 7, CURRENT_DATE + TIME '13:00', CURRENT_DATE + TIME '13:30', 'tervezett', 'Fejfájás'),
    (13, 20, 8, CURRENT_DATE + TIME '09:00', CURRENT_DATE + TIME '09:30', 'tervezett', 'Köhögés'),
    (14, 22, 8, CURRENT_DATE + TIME '10:00', CURRENT_DATE + TIME '10:30', 'tervezett', 'Láz'),
    (15, 24, 9, CURRENT_DATE + TIME '14:00', CURRENT_DATE + TIME '14:20', 'tervezett', 'Rosszullét'),
    (16, 16, 4, CURRENT_DATE + TIME '15:00', CURRENT_DATE + TIME '15:30', 'tervezett', 'Sebészeti kontroll'),
    (17, 9, 1, (CURRENT_DATE - 20) + TIME '08:00', (CURRENT_DATE - 20) + TIME '08:20', 'megjelent', 'Korábbi kontroll'),
    (18, 10, 1, (CURRENT_DATE - 20) + TIME '09:00', (CURRENT_DATE - 20) + TIME '09:20', 'megjelent', 'Korábbi kontroll'),
    (19, 9, 1, (CURRENT_DATE - 12) + TIME '08:00', (CURRENT_DATE - 12) + TIME '08:20', 'megjelent', 'Ismételt kontroll'),
    (20, 11, 2, (CURRENT_DATE - 18) + TIME '08:00', (CURRENT_DATE - 18) + TIME '08:30', 'megjelent', 'Labor utáni vizit'),
    (21, 13, 2, (CURRENT_DATE - 15) + TIME '08:00', (CURRENT_DATE - 15) + TIME '08:30', 'megjelent', 'Gyógyszerbeállítás'),
    (22, 14, 5, (CURRENT_DATE - 16) + TIME '10:00', (CURRENT_DATE - 16) + TIME '10:30', 'megjelent', 'Kardiológiai kontroll'),
    (23, 8, 5, (CURRENT_DATE - 16) + TIME '11:00', (CURRENT_DATE - 16) + TIME '11:30', 'megjelent', 'Szívelégtelenség gondozás'),
    (24, 15, 2, (CURRENT_DATE - 14) + TIME '11:00', (CURRENT_DATE - 14) + TIME '11:20', 'nem_jelent_meg', 'Nem jelent meg');

INSERT INTO keszlet_mozgas (gyogyszer_id, mennyiseg, ok, megjegyzes) VALUES
    (1, 80, 'bevetel', 'nyitó készlet'),
    (2, 40, 'bevetel', 'nyitó készlet'),
    (3, 5, 'bevetel', 'nyitó készlet'),
    (4, 60, 'bevetel', 'nyitó készlet'),
    (5, 50, 'bevetel', 'nyitó készlet'),
    (6, 40, 'bevetel', 'nyitó készlet'),
    (7, 40, 'bevetel', 'nyitó készlet'),
    (8, 3, 'bevetel', 'nyitó készlet'),
    (9, 30, 'bevetel', 'nyitó készlet'),
    (10, 50, 'bevetel', 'nyitó készlet');

INSERT INTO veny (veny_id, beteg_id, orvos_id, vizit_id, felvetel_id, kiallitas_datuma) VALUES
    (1, 1, 1, NULL, 1, CURRENT_DATE - 2),
    (2, 2, 2, NULL, 2, CURRENT_DATE - 1),
    (3, 9, 1, 17, NULL, CURRENT_DATE - 20),
    (4, 19, 8, NULL, 6, CURRENT_DATE - 1),
    (5, 4, 5, NULL, 4, CURRENT_DATE - 2),
    (6, 14, 5, 22, NULL, CURRENT_DATE - 16);

INSERT INTO veny_tetel (veny_tetel_id, veny_id, gyogyszer_id, mennyiseg, adag, gyakorisag, kiadva) VALUES
    (1, 1, 1, 2, '1 tabletta', 'szükség esetén', true),
    (2, 1, 4, 1, 'reggel 1 tabletta', 'naponta', true),
    (3, 2, 5, 2, '1 tabletta', 'reggel és este', true),
    (4, 3, 2, 1, '1 tabletta', 'étkezés után', false),
    (5, 4, 8, 1, '1 befújás', 'szükség esetén', true),
    (6, 5, 7, 1, 'este 1 tabletta', 'naponta', true),
    (7, 5, 10, 1, 'reggel 1 tabletta', 'naponta', true),
    (8, 6, 6, 1, 'reggel 1 tabletta', 'naponta', true),
    (9, 3, 3, 4, '1 kapszula', '8 óránként', true);

INSERT INTO labor_lelet (
    lelet_id, beteg_id, kert_orvos_id, tipus_id, mintavetel_idopont, eredmeny
) VALUES
    (1, 1, 1, 2, (CURRENT_DATE - 3) + TIME '07:10', 18.0),
    (2, 1, 1, 3, (CURRENT_DATE - 3) + TIME '07:10', 5.2),
    (3, 2, 2, 3, (CURRENT_DATE - 1) + TIME '07:20', 11.4),
    (4, 4, 5, 4, (CURRENT_DATE - 2) + TIME '06:50', 5.8),
    (5, 8, 6, 1, (CURRENT_DATE - 6) + TIME '07:00', 98.0),
    (6, 19, 8, 5, (CURRENT_DATE - 1) + TIME '08:00', 7.2),
    (7, 5, 7, 2, (CURRENT_DATE - 4) + TIME '07:40', 2.0),
    (8, 3, 3, 5, (CURRENT_DATE - 5) + TIME '12:00', 14.5),
    (9, 23, 2, 1, (CURRENT_DATE - 70) + TIME '08:00', 140.0),
    (10, 10, 1, 3, (CURRENT_DATE - 20) + TIME '08:10', 4.8),
    (11, 1, 1, 2, (CURRENT_DATE - 50) + TIME '09:00', 3.0);

INSERT INTO szamla (szamla_id, szamla_szam, beteg_id, kiallitas_datuma, hatarido) VALUES
    (1, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0001', 9, CURRENT_DATE - 20, CURRENT_DATE - 5),
    (2, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0002', 10, CURRENT_DATE - 2, CURRENT_DATE + 10),
    (3, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0003', 14, CURRENT_DATE - 15, CURRENT_DATE - 1),
    (4, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0004', 1, CURRENT_DATE - 3, CURRENT_DATE + 7),
    (5, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0005', 11, CURRENT_DATE - 40, CURRENT_DATE - 20),
    (6, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0006', 18, CURRENT_DATE - 1, CURRENT_DATE + 14),
    (7, 'SZ-' || to_char(CURRENT_DATE, 'YYYY') || '-0007', 8, CURRENT_DATE - 6, CURRENT_DATE + 4);

INSERT INTO szamla_tetel (
    tetel_id, szamla_id, szolgaltatas_id, megnevezes, mennyiseg, netto_egysegar, afa_kulcs
) VALUES
    (1, 1, 1, 'Szakorvosi vizsgálat', 1, 20000, 0),
    (2, 2, 2, 'Kontrollvizsgálat', 1, 12000, 0),
    (3, 3, 6, 'Ultrahang', 1, 18000, 0),
    (4, 4, 4, 'Fekvőbeteg ápolási nap', 3, 35000, 0),
    (5, 5, 3, 'Laborvizsgálat', 1, 8000, 0),
    (6, 6, 5, 'Orvosi igazolás', 1, 5000, 27),
    (7, 7, 1, 'Szakorvosi vizsgálat', 1, 20000, 0),
    (8, 7, 3, 'Laborvizsgálat', 1, 8000, 0);

INSERT INTO fizetes (fizetes_id, szamla_id, osszeg, fizetes_mod, idopont) VALUES
    (1, 3, 8000, 'utalas', (CURRENT_DATE - 10) + TIME '12:00'),
    (2, 4, 105000, 'kartya', (CURRENT_DATE - 2) + TIME '15:30'),
    (3, 5, 8000, 'keszpenz', (CURRENT_DATE - 35) + TIME '09:15'),
    (4, 7, 28000, 'utalas', (CURRENT_DATE - 5) + TIME '11:45');

SELECT setval(pg_get_serial_sequence('osztaly', 'osztaly_id'), (SELECT max(osztaly_id) FROM osztaly));
SELECT setval(pg_get_serial_sequence('alkalmazott', 'alkalmazott_id'), (SELECT max(alkalmazott_id) FROM alkalmazott));
SELECT setval(pg_get_serial_sequence('korterem', 'korterem_id'), (SELECT max(korterem_id) FROM korterem));
SELECT setval(pg_get_serial_sequence('agy', 'agy_id'), (SELECT max(agy_id) FROM agy));
SELECT setval(pg_get_serial_sequence('beteg', 'beteg_id'), (SELECT max(beteg_id) FROM beteg));
SELECT setval(pg_get_serial_sequence('felvetel', 'felvetel_id'), (SELECT max(felvetel_id) FROM felvetel));
SELECT setval(pg_get_serial_sequence('vizit', 'vizit_id'), (SELECT max(vizit_id) FROM vizit));
SELECT setval(pg_get_serial_sequence('gyogyszer', 'gyogyszer_id'), (SELECT max(gyogyszer_id) FROM gyogyszer));
SELECT setval(pg_get_serial_sequence('veny', 'veny_id'), (SELECT max(veny_id) FROM veny));
SELECT setval(pg_get_serial_sequence('veny_tetel', 'veny_tetel_id'), (SELECT max(veny_tetel_id) FROM veny_tetel));
SELECT setval(pg_get_serial_sequence('keszlet_mozgas', 'mozgas_id'), (SELECT max(mozgas_id) FROM keszlet_mozgas));
SELECT setval(pg_get_serial_sequence('labor_tipus', 'tipus_id'), (SELECT max(tipus_id) FROM labor_tipus));
SELECT setval(pg_get_serial_sequence('labor_lelet', 'lelet_id'), (SELECT max(lelet_id) FROM labor_lelet));
SELECT setval(pg_get_serial_sequence('szolgaltatas', 'szolgaltatas_id'), (SELECT max(szolgaltatas_id) FROM szolgaltatas));
SELECT setval(pg_get_serial_sequence('szamla', 'szamla_id'), (SELECT max(szamla_id) FROM szamla));
SELECT setval(pg_get_serial_sequence('szamla_tetel', 'tetel_id'), (SELECT max(tetel_id) FROM szamla_tetel));
SELECT setval(pg_get_serial_sequence('fizetes', 'fizetes_id'), (SELECT max(fizetes_id) FROM fizetes));
