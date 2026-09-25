-- vertraege_aktuell: laufzeit_monat ist NULL, solange der Vertrag noch nicht
-- begonnen hat.
--
-- Beim Einspielen von P3a zeigte die Sicht fuer die drei echten Vertraege aus
-- dem Klicktest "-4" und "0" — alle drei beginnen erst im naechsten Quartal.
-- Die Formel war nicht falsch, sie beantwortete nur eine Frage, die vor dem
-- Beginn keinen Sinn ergibt: Im wievielten Laufzeitmonat steht ein Vertrag,
-- der noch gar nicht laeuft? In keinem. Also NULL.
--
-- Die Oberflaeche zeigt an dieser Stelle "beginnt am TT.MM.JJJJ" statt einer
-- negativen Zahl. beitrag_diesen_monat_cents bleibt unveraendert — es faellt
-- schon vorher auf 0, wenn laufzeit_monat NULL ist.

begin;

create or replace view public.vertraege_aktuell
with (security_invoker = true) as
with basis as (
  select
    v.*,
    public.vertrag_wirksamer_status(
      v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis
    ) as wirksamer_status,
    -- 1 im Startmonat, NULL davor. Ueber Jahr und Monat gerechnet, nicht ueber
    -- Tage: ein Vertrag ab dem 1. Maerz ist am 1. September im 7. Monat, egal
    -- wie viele Tage dazwischenliegen.
    case
      when v.vertragsbeginn is null or current_date < v.vertragsbeginn then null
      else 1
           + (extract(year  from current_date)::integer * 12
              + extract(month from current_date)::integer)
           - (extract(year  from v.vertragsbeginn)::integer * 12
              + extract(month from v.vertragsbeginn)::integer)
    end as laufzeit_monat
  from public.vertraege v
  where v.status = 'abgeschlossen'
)
select
  b.*,

  -- Der juengste abgeschlossene Vertrag je Kind. Die Uebersicht zeigt
  -- standardmaessig nur ihn; Vorgaenger liegen darunter in der Historie.
  row_number() over (
    partition by coalesce(b.student_id, b.id)
    order by b.vertragsbeginn desc nulls last,
             b.abgeschlossen_am desc nulls last,
             b.created_at desc
  ) = 1 as ist_aktueller_vertrag,

  -- Was in diesem Kalendermonat abgebucht wird. Beim Jahresvertrag sind das
  -- zwoelf Monate, beim Halbjahr sechs — danach laeuft der Vertrag weiter,
  -- aber beitragsfrei (Entscheidung 5).
  case
    when b.preis_cents is null or b.laufzeit_monat is null or b.laufzeit_monate is null
      then 0
    when b.laufzeit_monat between 1 and b.laufzeit_monate then b.preis_cents
    else 0
  end as beitrag_diesen_monat_cents,

  -- Der Code oeffnet nur, solange der Vertrag traegt. Gesperrt wird zusaetzlich
  -- von Hand (zugangscode_gesperrt_am), etwa nach einem Widerruf.
  (b.zugangscode is not null
   and b.zugangscode_gesperrt_am is null
   and b.wirksamer_status in ('im_widerruf', 'aktiv')) as zugangscode_gueltig,

  -- Negativ, sobald das Ende vorbei ist. Die Liste "Auslaufende Vertraege"
  -- filtert darauf (acht Wochen = 56).
  (b.vertrag_ende - current_date) as endet_in_tagen
from basis b;

commit;
