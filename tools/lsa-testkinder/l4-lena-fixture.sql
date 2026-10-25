-- LSA-L4 Teil C (11): „Batu nach Lenas Freigaben“ = l4-fixture.sql plus die 36 Entwürfe aus
-- docs/lsa/freigabeliste-batu-1025.md als freigegeben (je Bereich zwei, darunter der ohne MC). NUR für eine Wegwerf-DB.
\set l4_mit_lena 1
\ir l4-fixture.sql
\unset l4_mit_lena
