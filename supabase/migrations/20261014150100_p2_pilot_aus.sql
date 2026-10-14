-- P2 · M1: Lenas Board zeigt nur Batus Liste — Pilot-Flag für die 76 übrigen Aufgaben entziehen.
--
-- Nach P1 (20261014140200) trugen 331 Aufgaben pruef_pilot: P1s Zielmenge (255) und 76 Reste des ersten
-- Lena-Board-Piloten (20261005080222, Abschnitt 26). Entscheidung Rasit 14.10.2026: die 76 verlieren das Flag,
-- über denselben Weg wie die Admin-Aktion pilot_aus: pruef_sammel_schreiben('pilot_aus', …) setzt pruef_pilot
-- auf false und schreibt je Aufgabe eine task_admin_protokoll-Zeile (von = null, als Systemaufruf).
-- Rücksetzliste mit Knoten: docs/themen/p2-pilot-entfernt.md. Kein Status, Text oder anderes Feld ändert sich.
--
-- Feste ID-Liste (dbread 14.10.2026), nur Aufgaben, die das Flag noch tragen. Idempotent; im CI-Neuaufbau
-- fehlen die Aufgaben, dann trifft die Schleife nichts. Kein begin/commit: mig klammert mit psql -1.

do $p2m1$
declare
  v_ids uuid[] := array[
    '0644e069-c106-4cb4-8faa-bbad5edddb70',
    '0b3bf2b5-29bc-4b79-9fa5-2e1016d65e97',
    '0c5d8ee8-fed2-4022-9d27-23860d1d7cc7',
    '0cdf2d28-abd3-4931-8b51-81fe03044974',
    '0d01fa82-d4fb-4fc4-ba47-62d7175763ee',
    '1b979a6a-de0f-434e-96c3-c5859a536a36',
    '1d8a70aa-9010-4259-9278-5cbc6425d3c0',
    '20cdce1e-0e9d-478d-820e-b77ff90c94bc',
    '2708a240-7d4b-42bb-a028-d106ebe60765',
    '28ee89d3-0cdc-4842-869e-423c2bf78f8d',
    '3510e4f2-f006-4d20-bdf8-8d8520ed09e1',
    '3b59c4a1-2216-48a5-9462-64c03187acd9',
    '3ba007ed-a9f6-44fd-9800-07b92ffdbb65',
    '4615926e-2f06-4780-9b12-d153117c045e',
    '4f0b933d-3ead-4042-adb9-a1369ba28f39',
    '52f02da3-efb0-4667-8387-506d491e74c5',
    '57246a98-fef1-4beb-b288-24a676d2eeb2',
    '573dd0b7-5fd2-4b4e-9263-3630affba5da',
    '5875fe3f-394d-4a2b-8977-bf825b5f9518',
    '5beb71a7-cbef-4392-bcca-446b1bc97354',
    '5cad7848-0d28-4198-93a0-6232e6f988b1',
    '650eed2a-79e5-4a6f-9ed2-a51053fe75c8',
    '6a448f69-d164-4cf6-82ca-461a8bae980f',
    '7223ee1a-3043-487e-850c-e9da8501d935',
    '743dc783-c0c1-4b97-957c-e8dfff38e3b6',
    '75cb4657-94a9-4348-b6b1-807f241f4914',
    '785c92ab-e234-469f-bb6a-59c0c11db8fd',
    '7875948d-3789-43cb-8e1a-861de7167ece',
    '7d305269-159f-40cc-9965-c343c2bb4c15',
    '7e7ce00a-733b-404a-88fe-b41cf327f2f5',
    '7eba6b75-1852-4713-8f6b-bf0e626fa52b',
    '807dd2a7-18a0-4ff1-93e4-d2d26052cd12',
    '82cb7f14-5213-4aea-a297-c480c557463c',
    '8b4bf5c8-d813-439b-b9a4-5dd412b8b0af',
    '8e1dd449-25bb-4fc1-9d60-d38609216ba5',
    '8e82be72-f8e3-480f-bdef-a4e78ddd060f',
    '90b93e1f-091c-4bbb-a6a7-5d48c9d5b6c1',
    '982be3c3-2d1f-4d59-817a-b7bd45ade1d6',
    '9de789c5-cdc1-45c4-b38f-d809926410f5',
    '9e26a451-8496-4a05-9f4d-752d05fcddf9',
    '9ef4de2a-1a55-49a3-ac80-2a03594006b8',
    '9f7f0cd7-128b-4a4d-9281-16c78804a1b4',
    'a1c6838a-e550-4ed2-92cf-55244acded67',
    'a1d203d7-0d30-42ae-8c54-d3e7dc04a7d6',
    'a1fa4311-c631-47ba-a4a7-15e12149db4c',
    'a30145c7-5bc0-4f21-80ee-5237c1df2756',
    'a35d5827-c2d4-48a9-87b8-6c69c1078abe',
    'a394b2eb-df58-4b57-9c79-ae8ff0c62b24',
    'ae38bcca-7313-4863-95a6-8117a7b524d1',
    'b7b814a6-d2c9-4988-855c-3d51b5148da0',
    'bb650a2d-6122-42ee-9fa1-3a2b1f1eda1e',
    'c0b1c3c5-0c12-4815-bce5-377fca8504c4',
    'ceb26573-de3f-488a-9956-6a8cf7eb81cf',
    'd09b4715-e18d-4588-a00e-fbadaea189e1',
    'd393d7c6-e5ff-43bb-b049-e8ba63aa1cdf',
    'd602bc49-3ee0-48fb-8cd3-467b2ae0abc2',
    'd7f1416b-ee9c-408c-8dd3-7e2bfc623a27',
    'd8195933-ba82-4768-ac40-064da27497a6',
    'd986ca37-4dc0-43c6-a148-153aa8605838',
    'dda4b621-05d8-4390-bf6a-078a4a7bd19b',
    'e04364d3-e946-4be1-8aca-0b3b1c52353d',
    'e0cfc702-9b40-450e-b530-1b6bb53976a8',
    'e61dfd20-5b7c-4f12-94f9-f38a51ab64c5',
    'e63c2e2e-396f-46f6-91d1-c34595a88dbc',
    'e958eb79-345a-4079-867b-46ecb652b478',
    'ea14696a-c3ae-40e4-938a-051a13fdbbd4',
    'ecb3d12b-a21e-4031-b562-a1596deeb815',
    'ee07674f-0846-4f38-a0c7-247fd351b729',
    'f52ef418-8b90-4c8f-903f-975f8bd8da41',
    'f531dcee-04cf-4e14-ad5e-9032f72f0668',
    'f66a50d0-7de9-4cad-89c5-a92028eecf1d',
    'f70e9312-b530-4b4b-9c7a-087ef87fbba9',
    'f91e5425-b56b-434f-9ae1-814649f9aba3',
    'f96d3513-0ae9-4316-a871-4bf72aff96c3',
    'fdd119e8-2192-4691-bda5-d6a5a03317d4',
    'fe3a88b0-7d72-4896-929c-b7f0c379cfa3'
  ]::uuid[];
  v_n integer := 0;
  t public.tasks;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  for t in select * from public.tasks x where x.id = any (v_ids) and x.pruef_pilot order by x.id loop
    perform public.pruef_sammel_schreiben('pilot_aus', t,
      jsonb_build_object('grund', 'P2: Board nur mit Batus Liste, Rücksetzliste docs/themen/p2-pilot-entfernt.md (Rasit, 14.10.2026)'));
    v_n := v_n + 1;
  end loop;
  raise notice 'p2_m1: pruef_pilot entzogen fuer % Aufgabe(n)', v_n;
end $p2m1$;
