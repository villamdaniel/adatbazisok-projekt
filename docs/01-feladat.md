# Feladat és követelmények

Hallgató neve:  
Neptun-kód:  
Tárgy: Adatbázisok

## A feladat

A Lumen Klinika járó- és fekvőbeteg-ellátást, gyógyszerkészletet, labort és számlázást szeretne egyetlen relációs adatbázisból működtetni. A mostani nyilvántartás szétszórt: az ágyfoglalás, a rendelési naptár és a pénztár nincs összekötve, ezért kétszer foglalnak ágyat, ütközik az orvos naptára, és a számla végösszege eltérhet a tételektől.

A projekt ennek a nyilvántartásnak a terve és a PostgreSQL megvalósítása. Az alkalmazás felülete szándékosan nincs meg: a tárgy szempontjából a séma, a megszorítások és a lekérdezések a termék.

## Szereplők

- **Beteg** regisztrál, fekvőbetegként bent fekszik, vagy rendelésre jön.
- **Orvos** egy osztályhoz tartozik, felvesz, rendel, vényt és labort kér.
- **Ápoló** az osztály ágyait és a bent fekvőket látja.
- **Pénzügy** számlát állít ki és befizetést rögzít. Labort és kórtörténeti szöveget nem lát.
- **Recepció** a mai előjegyzést látja, panasz és javaslat nélkül.
- **Adminisztrátor** a teljes adatbázist kezeli.

## Funkcionális követelmények

1. Osztály, kórterem és ágy nyilvántartása. Az ágy lehet szabad, foglalt vagy karbantartás alatt.
2. Dolgozók közös törzse, orvos és ápoló altípussal. Egy ember nem lehet mindkettő.
3. Beteg azonosítása érvényes TAJ-számmal.
4. Fekvőbeteg-felvétel ágyra, felvevő orvossal és diagnózisokkal. Pontosan egy fődiagnózis kötelező.
5. Ugyanaz a beteg és ugyanaz az ágy időben nem lehet két felvételen.
6. Gyermekgyógyászatra csak 18 év alatti beteg vehető fel, és csak a saját osztály orvosa vehet fel.
7. Járóbeteg-rendelés. Egy orvos aktív rendelései nem fedhetik egymást. A lemondott időpont nem foglalja a naptárat.
8. Vény, amely vagy egy rendeléshez, vagy egy felvételhez tartozik, és készletmozgást ír, ha kiadják.
9. A gyógyszerkészlet a mozgások összege, nem egy felülírható szám. Nulla alá nem mehet, a napló sora nem törölhető.
10. Laborlelet referenciatartománnyal, és külön nézet a tartományon kívüli eredményekre.
11. Számla tételekkel. A tétel ára a kiállításkori másolat. A befizetés nem lépheti túl a végösszeget, a kiegyenlített számla állapota automatikusan `fizetve`.
12. Kijelölt műveletek naplózása.

## Nem funkcionális követelmények

- A séma legalább harmadik normálformában van, a számlatétel ára szándékos, indokolt másolat.
- A szabály a triggertől függetlenül is megszorítás, ahol az adatbázis-kezelő engedi.
- A dátumok a betöltés napjához képest relatívak, ezért a bemutató nem egy naptári naphoz kötött.
- Fejlesztői jelszavak csak a helyi gépre valók.

## Szándékosan nem tartozik ide

- Grafikus felület, bejelentkező képernyő, webes API.
- Valódi TAJ-nyilvántartás, EESZT vagy online pénztárgép.
- Éles jogosultság, titkosított jelszókezelés, mentési üzemeltetés.
