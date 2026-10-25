-- L1 Nachtrag (25.10.2026): Rasit gibt die vier Text-Aufgaben direkt frei, statt sie bei Lena zu lassen.
-- Derselbe Weg wie die Admin-Ansicht (pruef_admin_freigeben: Gate, Hinweise geprueft, Protokoll), als Rasit.
-- Erst nach tools/l1b-antworten.sql; danach tools/l1b-antworten-nachtrag.sql.

\set ON_ERROR_STOP on
begin;
select set_config('request.jwt.claims',
                  json_build_object('sub', '35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'role', 'authenticated')::text, true);
set local role authenticated;
select public.get_my_role() as rolle;
select t.id, t.status vorher from public.tasks t
 where t.id in ('3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', '4f0b933d-3ead-4042-adb9-a1369ba28f39',
                'e8348c89-67cb-4650-be91-235e69321776', '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992');
select x.id, public.pruef_admin_freigeben(x.id) ->> 'status' as nachher
  from unnest(array['3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', '4f0b933d-3ead-4042-adb9-a1369ba28f39',
                    'e8348c89-67cb-4650-be91-235e69321776', '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992']::uuid[]) x(id);
commit;
