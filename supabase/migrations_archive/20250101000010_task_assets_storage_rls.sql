-- Migration 010: RLS-Policies fuer den 'task-assets' Storage-Bucket.
-- Voraussetzung: Bucket 'task-assets' wurde via Supabase Studio bereits angelegt
-- (in der Regel als "public bucket" -> Public-Read ist bereits aktiv).
--
-- Ausfuehrung: Manuell im Supabase Studio SQL Editor.
--
-- Ziel: Admins (profiles.role = 'admin') koennen Bilder via Frontend-Client
-- hochladen, aktualisieren und loeschen. Lesen bleibt public (kommt vom Bucket).

-- Admins koennen Objekte in 'task-assets' hochladen
create policy "admin_insert_task_assets"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);

-- Admins koennen Objekte in 'task-assets' aktualisieren
create policy "admin_update_task_assets"
on storage.objects for update to authenticated
using (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);

-- Admins koennen Objekte in 'task-assets' loeschen
create policy "admin_delete_task_assets"
on storage.objects for delete to authenticated
using (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);

-- Optional: Public-Read explizit setzen, falls beim Bucket-Anlegen die
-- "public bucket" Toggle nicht gesetzt wurde. Bei "public bucket" nicht
-- noetig - dann diesen Block auskommentiert lassen.
-- create policy "public_read_task_assets"
-- on storage.objects for select to public
-- using (bucket_id = 'task-assets');
