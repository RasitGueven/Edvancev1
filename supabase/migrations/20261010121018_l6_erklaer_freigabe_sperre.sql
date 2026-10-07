-- L6 Nachtrag (Entscheidung Rasit 07.10.): Freigegebene Inhalte aendert nur ein Admin, in der Datenbank.
--
-- Titel, Schritte (Text, Bild, Formeln, Fehlbild-Zuordnung, neue oder geloeschte Schritte) und Checks einer
-- freigegebenen Kernidee aendern -> 42501 fuer alle ausser Admin und Systemaufrufe (tools/formeln-svg.mjs,
-- Content-Migrationen; ist_systemaufruf). Lena meldet so etwas als Rueckfrage (erklaer_pruefen 'unsicher'),
-- das bleibt erlaubt.
--
-- Als Trigger, damit es fuer jeden Weg gilt (erklaer_kernidee_speichern, erklaer_schritt_speichern,
-- erklaer_check_setzen, erklaer_formeln_setzen und kuenftige Funktionen). Reine Statuswechsel sind nicht
-- betroffen: die regelt erklaer_status_setzen (freigegeben verlassen nur Admin) und erklaer_pruefen.
-- Loeschen per Kaskade (pg_trigger_depth() > 1) bleibt erlaubt.

create function public.erklaer_freigabe_sperre() returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kernidee uuid;
  v_inhalt   boolean;
begin
  if coalesce(public.get_my_role(), '') = 'admin' or public.ist_systemaufruf()
     or (tg_op = 'DELETE' and pg_trigger_depth() > 1) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_table_name = 'erklaer_kernidee' then
    v_kernidee := old.id;
    v_inhalt := (old.skill_key, old.nr, old.titel, old.quelle) is distinct from (new.skill_key, new.nr, new.titel, new.quelle);
  elsif tg_table_name = 'erklaer_schritt' then
    v_kernidee := case when tg_op = 'INSERT' then new.kernidee_id else old.kernidee_id end;
    v_inhalt := tg_op <> 'UPDATE'
      or (old.kernidee_id, old.variante, old.art, old.inhalt, old.bild, old.fehlbild_slugs, old.formeln)
         is distinct from (new.kernidee_id, new.variante, new.art, new.inhalt, new.bild, new.fehlbild_slugs, new.formeln);
  else
    v_kernidee := case when tg_op = 'INSERT' then new.kernidee_id else old.kernidee_id end;
    v_inhalt := true;
  end if;

  if v_inhalt and exists (select 1 from public.erklaer_kernidee k where k.id = v_kernidee and k.status = 'freigegeben') then
    raise exception 'erklaer: freigegebene Kernidee aendert nur ein Admin (sonst Rueckfrage)'
      using errcode = '42501', hint = 'freigegeben_nur_admin';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger erklaer_kernidee_freigabe_sperre
  before update on public.erklaer_kernidee
  for each row execute function public.erklaer_freigabe_sperre();
create trigger erklaer_schritt_freigabe_sperre
  before insert or update or delete on public.erklaer_schritt
  for each row execute function public.erklaer_freigabe_sperre();
create trigger erklaer_check_freigabe_sperre
  before insert or update or delete on public.erklaer_check
  for each row execute function public.erklaer_freigabe_sperre();

revoke all on function public.erklaer_freigabe_sperre() from public, anon, authenticated;
