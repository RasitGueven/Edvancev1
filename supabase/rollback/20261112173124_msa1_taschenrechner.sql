-- Rollback zu 20261112173124_msa1_taschenrechner: Kennzeichen für genau diese 15 Aufgaben zurück auf false.
-- Den Eintrag in supabase_migrations.schema_migrations danach von Hand entfernen.
update public.tasks set taschenrechner = false where id = any (array[
    '0054a031-7aae-4035-a3e5-1e3c698c35d6', '13d6dc4d-737e-4fd3-a67d-fb401ff5e223', '167c44e0-d197-4696-951a-a17b5f8337c4',
    '17b68c02-51e8-4484-b955-5ee77729c024', '32f15d20-ea8e-4ff0-9d43-d10daa9500bc', '33bdde50-6f8d-4d2e-a80c-62601488e4a2',
    '380b85ad-3967-4fad-b370-e113276310a6', '3ba41acb-6f44-46cf-bfb8-006789699045', '3e496b46-156d-45cc-9b77-596261829fb8',
    '52d18200-7696-4bed-bba7-352cbb35436c', '6778b0b4-e325-4ce4-b2a9-c083b57a5987', '7a00ab4b-d497-46fc-87c4-8e706fc3aaff',
    'a21f48d2-f097-495a-91ed-093327524d91', 'a8e2cd6c-586b-46d4-a25e-55aa33f9e02d', 'ccd00ca0-8589-4826-9f85-ed97dbb37116'
  ]::uuid[]);
