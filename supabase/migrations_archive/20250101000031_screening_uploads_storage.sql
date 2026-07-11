-- ============================================================================
-- Migration 031 – Foto-Upload Rechenweg (Bucket: screening-uploads)
--
-- Privater Bucket für Foto-Uploads von Schüler:innen — z. B. abfotografierte
-- Rechenwege oder Skizzen aus dem Heft. Bilder sind personenbezogen
-- (Handschrift!), darum nur via Signed URL zugänglich.
--
-- Voraussetzung: Bucket `screening-uploads` ist VOR Ausführung dieser
-- Migration in Supabase Studio (Storage → New bucket) angelegt:
--   - Name:       screening-uploads
--   - Public:     OFF  (privat)
--   - File-size:  ≤ 8 MB
--   - MIME:       image/jpeg, image/png, image/heic, image/webp
--
-- Pfad-Konvention:  {student_id}/{timestamp}-{rand}.{ext}
-- → das erste Segment muss die student_id sein (RLS prüft via foldername()).
-- ============================================================================

-- Schüler:in lädt Fotos für die eigene student_id hoch.
create policy "screening_uploads_insert_own_student"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);

-- Schüler:in liest eigene Uploads.
create policy "screening_uploads_select_own_student"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);

-- Schüler:in darf eigene Uploads vor dem Submit verwerfen.
create policy "screening_uploads_delete_own_student"
on storage.objects for delete to authenticated
using (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);

-- Eltern lesen die Uploads ihrer Kinder.
create policy "screening_uploads_select_parent"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() = 'parent'
  and public.is_parent_of_student(((storage.foldername(name))[1])::uuid)
);

-- Coach + Admin lesen alle Uploads (pädagogische Auswertung).
create policy "screening_uploads_select_coach_admin"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() in ('coach','admin')
);

-- Admin darf Uploads endgültig löschen (DSGVO Art. 17 Lösch-Pfad).
create policy "screening_uploads_delete_admin"
on storage.objects for delete to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() = 'admin'
);
