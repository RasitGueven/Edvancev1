-- Aktiviert alle VERA-8-Items im Screening-Pool. Einmalig im Supabase
-- SQL-Editor ausführen, nachdem `npm run seed:vera8` durchgelaufen ist.
-- Idempotent: das wiederholte Ausführen ändert nichts.
update screening_items
   set active = true
 where iqb_titel is not null
   and active = false;
