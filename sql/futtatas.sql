-- Lumen Klinika
-- Teljes telepítés egy már létező, üres adatbázisba.
-- psql -v ON_ERROR_STOP=1 -d lumen_klinika -f sql/futtatas.sql
--
-- Ne add meg a --single-transaction kapcsolót: a mintaadat saját tranzakciót használ.

\ir init/01_sema.sql
\ir init/02_indexek.sql
\ir init/03_nezetek.sql
\ir init/04_triggerek.sql
\ir init/05_eljarasok.sql
\ir init/06_adatok.sql
\ir init/07_jogosultsag.sql
\ir init/08_ellenorzes.sql
