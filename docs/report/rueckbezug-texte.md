# Rückbezug-Texte in Prod — was nicht stimmt und was sich ändert (W5-d, Nachtrag 2)

Stand 04.10.2026. Betrifft `report_bausteine`, Slot `rueckbezug` (Abschnitt „So geht es weiter":
die Antwort auf die von den Eltern genannten Punkte). Migrationen `20261004003309_report_bausteine_entwurf`
und `20261004003310_rueckbezug_entwuerfe`.

## Was der Punkt bedeutet

Die 28 Rückbezug-Sätze stammen aus R4/R5 (August 2026) und sind alle abgenommen. Elf davon sprechen
noch die Sprache, die #189 im übrigen Report abgeschafft hat:

1. **„tragen" statt „sicher".** Der Report sagt überall „sicher / noch nicht sicher" (Regel aus #189,
   in INV-4 für alle `suche.*`-Texte abgesichert). Im Schluss stand dann „Alle Bereiche … tragen".
   Für Eltern sind das zwei Wörter für dasselbe, oder schlimmer: zwei verschiedene Befunde.
2. **„Ebenen", „Fundament", „Stufen".** Die Ebenen waren `fundament_tiefe`, eine Position im Graphen.
   #189 hat die Gliederung nach Ebenen entfernt, Abschnitt 02 nennt keine Ebene mehr. Ein Satz über
   „die tiefste Ebene, die wir geprüft haben" verweist auf etwas, das im Dokument nicht mehr vorkommt.
3. **„unterhalb des aktuellen Themas".** Seit W5-d meint der Rückbezug genau die Grundlagen im
   Themenraum. Abschnitt 02 nennt sie „Grundlagen, auf denen das Thema aufbaut"; der Schluss soll
   dasselbe Wort benutzen.
4. **Sitzungen ohne Thema.** Seit W5-d antwortet „Grundlagen fehlen" ohne Thema mit
   `grundlagen_offen` (keine Aussage), denn ohne Thema gibt es keine Grundlagen des Themas. Alle
   21 abgeschlossenen Sitzungen in Prod haben kein Thema. Der heutige Satz sagt dort „Unterhalb des
   aktuellen Themas …", obwohl es keins gab. Der Entwurf kommt ohne Thema aus.

Welcher Fall wann gezogen wird und mit wie vielen Belegen, ändert sich nicht. Die übrigen 17 Sätze
(Textverständnis a, Rechenwege, nicht messbare Punkte) sind in Ordnung.

## Warum eine Spalte `entwurf` und nicht einfach neue Texte

`report_bausteine` hat je Fall genau zwei Zeilen (Variante a/b, per Check und Unique), und der
Lesepfad liefert nur Zeilen mit `freigegeben_am`. Der in R4 dokumentierte Weg („text ändern,
`freigegeben_am` zurücksetzen") hätte die Sätze bis zur Abnahme aus jedem Report genommen. Bei
„Grundlagen fehlen" stünde dann ein genannter Punkt ohne Antwort da, was R5 ausdrücklich verbietet,
und die erste echte LSA steht bevor.

Deshalb gibt es eine nullable Spalte `entwurf` neben `text`. Sie wird nie ausgeliefert (der Lesepfad
wählt sie nicht aus), RLS bleibt unverändert. Ein Check verhindert leere Entwürfe und Entwürfe, die
gleich dem Text sind. Bis zur Abnahme sehen Eltern den alten Satz.

## Abnahme (Lena)

Je Fall eine Anweisung. Sie übernimmt beide Varianten (a und b) und nimmt sie im selben Schritt ab.
Sie gilt für Entwürfe in `entwurf` UND für neue, noch nie abgenommene Zeilen (Slot `ausgangspunkt`,
dort steht der Entwurf in `text`):

```sql
update report_bausteine
   set text = coalesce(entwurf, text), entwurf = null,
       freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
 where slot = '<slot>' and fall = '<fall>'
   and (entwurf is not null or freigegeben_am is null);
```

Neu gegenüber den alten Sätzen: `grundlagen_entlastend` nennt die Zahl der geprüften Grundlagen
(`{belege}`), wie es R4 für entlastende Sätze vorsieht. Der Renderer setzt sie bereits ein.

Einen Entwurf verwerfen: `update report_bausteine set entwurf = null where schluessel = '…';`.
Stand prüfen: `~/bin/dbread -f supabase/checks/rueckbezug_entwuerfe.PRUEFUNG.sql`.
Darum wird je Fall abgenommen: sonst stehen je nach Sitzung alte und neue Sprache nebeneinander.

## Die elf Sätze

### `rueckbezug.grundlagen_bestaetigend_durchgehend.a`

- **Warum:** „tiefste Ebene“, „über mehrere Ebenen“ — Ebenensprache; seit #189 kennt der Report keine Ebenen mehr.
- **Heute (abgenommen):** Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich. Die Lücken reichen bis auf die tiefste Ebene, die wir geprüft haben — dort setzen wir an.
- **Entwurf:** Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich. Selbst bei den grundlegendsten Bereichen, die wir unter dem Thema geprüft haben, ist Ihr Kind noch nicht überall sicher — dort setzen wir an.

### `rueckbezug.grundlagen_bestaetigend_durchgehend.b`

- **Warum:** „tiefste Ebene“, „über mehrere Ebenen“ — Ebenensprache; seit #189 kennt der Report keine Ebenen mehr.
- **Heute (abgenommen):** Sie hatten vermutet, dass Grundlagen fehlen. Die Analyse zeigt das über mehrere Ebenen hinweg, bis ganz nach unten.
- **Entwurf:** Sie hatten vermutet, dass Grundlagen fehlen. Die Analyse zeigt das: Bis hin zu den grundlegendsten Bereichen, auf denen das Thema aufbaut, ist noch nicht alles sicher.

### `rueckbezug.grundlagen_bestaetigend_mitte.a`

- **Warum:** „Ebenen … tragen“, „Fundament“, „Stufen“ — Trage- und Ebenensprache.
- **Heute (abgenommen):** Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich — allerdings nicht ganz unten. Die tiefsten Ebenen, die wir geprüft haben, tragen; die Lücken liegen dazwischen.
- **Entwurf:** Ihr Eindruck, dass Grundlagen fehlen, bestätigt sich — allerdings nicht ganz unten. Die grundlegendsten Bereiche, die wir unter dem Thema geprüft haben, sind sicher; noch nicht sicher ist Ihr Kind bei einzelnen Schritten dazwischen.

### `rueckbezug.grundlagen_bestaetigend_mitte.b`

- **Warum:** „Ebenen … tragen“, „Fundament“, „Stufen“ — Trage- und Ebenensprache.
- **Heute (abgenommen):** Sie hatten vermutet, dass Grundlagen fehlen. Das trifft zu, aber genauer gesagt: Nicht das Fundament als Ganzes fehlt, sondern einzelne Stufen darin.
- **Entwurf:** Sie hatten vermutet, dass Grundlagen fehlen. Das trifft zu, aber genauer gesagt: Nicht die Grundlagen als Ganzes fehlen, sondern einzelne Schritte zwischen ihnen und dem Thema.

### `rueckbezug.grundlagen_entlastend.a`

- **Warum:** „getragen“, „tragen“ statt „sicher“; „unterhalb des aktuellen Themas“ statt „Grundlagen, auf denen das Thema aufbaut“.
- **Heute (abgenommen):** Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas hat jeder geprüfte Bereich getragen — dieser Punkt hat sich so nicht bestätigt.
- **Entwurf:** Sie hatten vermutet, dass Grundlagen fehlen. Bei den Grundlagen, auf denen das Thema aufbaut, war Ihr Kind in allen {belege} Bereichen sicher, die wir geprüft haben — dieser Punkt hat sich so nicht bestätigt.

### `rueckbezug.grundlagen_entlastend.b`

- **Warum:** „getragen“, „tragen“ statt „sicher“; „unterhalb des aktuellen Themas“ statt „Grundlagen, auf denen das Thema aufbaut“.
- **Heute (abgenommen):** Zu Ihrer Vermutung, dass Grundlagen fehlen: Alle Bereiche unterhalb des aktuellen Themas, die wir geprüft haben, tragen.
- **Entwurf:** Zu Ihrer Vermutung, dass Grundlagen fehlen: Alle {belege} Bereiche, auf denen das Thema aufbaut und die wir geprüft haben, sind sicher.

### `rueckbezug.grundlagen_entlastend_schmal.a`

- **Warum:** „trägt“, „hat getragen“, „die Ebenen darunter“.
- **Heute (abgenommen):** Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich unterhalb des aktuellen Themas, den wir geprüft haben, trägt. Das ist noch kein vollständiges Bild — der Coach geht die Ebenen darunter im Unterricht durch.
- **Entwurf:** Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich, auf dem das Thema aufbaut und den wir geprüft haben, ist sicher. Das ist noch kein vollständiges Bild — der Coach geht die übrigen Grundlagen im Unterricht durch.

### `rueckbezug.grundlagen_entlastend_schmal.b`

- **Warum:** „trägt“, „hat getragen“, „die Ebenen darunter“.
- **Heute (abgenommen):** Zu Ihrer Vermutung, dass Grundlagen fehlen: Was wir unterhalb des aktuellen Themas angesehen haben, hat getragen. Es war allerdings nur ein Bereich — mehr sagt diese Analyse dazu nicht.
- **Entwurf:** Zu Ihrer Vermutung, dass Grundlagen fehlen: Was wir von den Grundlagen des Themas angesehen haben, war sicher. Es war allerdings nur ein Bereich — mehr sagt diese Analyse dazu nicht.

### `rueckbezug.grundlagen_offen.a`

- **Warum:** „unterhalb des aktuellen Themas“, „Ebenen darunter“. Seit W5-d bekommen auch Sitzungen OHNE Thema diesen Satz — dort gibt es kein „aktuelles Thema“.
- **Heute (abgenommen):** Sie hatten vermutet, dass Grundlagen fehlen. Unterhalb des aktuellen Themas ist in dieser Analyse zu wenig geprüft worden, um das zu beantworten. Der Coach geht die Ebenen darunter im Unterricht durch.
- **Entwurf:** Sie hatten vermutet, dass Grundlagen fehlen. Dafür hat diese Analyse die Grundlagen zu wenig geprüft, um es zu beantworten. Der Coach geht sie im Unterricht durch.

### `rueckbezug.grundlagen_offen.b`

- **Warum:** „unterhalb des aktuellen Themas“, „Ebenen darunter“. Seit W5-d bekommen auch Sitzungen OHNE Thema diesen Satz — dort gibt es kein „aktuelles Thema“.
- **Heute (abgenommen):** Zu Ihrer Vermutung, dass Grundlagen fehlen: Diese Analyse ist unterhalb des aktuellen Themas nicht weit genug gekommen, um dazu etwas zu sagen.
- **Entwurf:** Zu Ihrer Vermutung, dass Grundlagen fehlen: Diese Analyse hat die Grundlagen nicht ausreichend geprüft, um dazu etwas zu sagen.

### `rueckbezug.textverstaendnis_bestaetigend.b`

- **Warum:** „trägt noch nicht“ statt „noch nicht sicher“ (Variante a ist schon richtig).
- **Heute (abgenommen):** Was Sie zum Textverständnis gesagt haben, findet sich in der Analyse wieder — der Schritt vom Text zur Rechnung trägt noch nicht.
- **Entwurf:** Was Sie zum Textverständnis gesagt haben, findet sich in der Analyse wieder — beim Schritt vom Text zur Rechnung ist Ihr Kind noch nicht sicher.

## Teil 5: Ausgangspunkt statt Wahl, Fazit ohne „aktuelles Thema"

Migration `20261004093449_report_ausgangspunkt_entwuerfe`. Vier alte Sitzungen bekommen nachträglich
das Thema „Terme und Gleichungen" (`stand = 'nachgetragen'`). Gewählt hat es niemand, denn die alte
LSA begann für alle bei den Gleichungen. Deshalb sagt der Report dort nie „Gewählt war das Thema …".
Er zieht stattdessen den Slot `ausgangspunkt`. Solange der nicht abgenommen ist, **entfällt der Satz**.

### `ausgangspunkt.thema` (Einstieg geprüft; steht vor „Beim Thema … war Ihr Kind …")

- **a:** Ausgangspunkt der Analyse war das Thema „{thema}“.
- **b:** Die Analyse hat beim Thema „{thema}“ begonnen.

### `ausgangspunkt.ungeprueft` (Einstieg nicht geprüft; ersetzt „Gewählt war das Thema …")

- **a:** Ausgangspunkt der Analyse war das Thema „{thema}“. Aufgaben direkt zu diesem Thema kamen darin nicht vor.
- **b:** Die Analyse hat im Umfeld des Themas „{thema}“ begonnen; Aufgaben direkt zu diesem Thema kamen dabei nicht vor.

### `fazit.keine.a` (Entwurf in `entwurf`)

- **Warum:** „Das aktuelle Thema steht" setzt ein gewähltes, aktuelles Thema voraus; „tragen".
- **Heute (abgenommen):** Das aktuelle Thema steht, und die Grundlagen darunter tragen. Wir halten dieses Niveau und arbeiten am kommenden Stoff weiter.
- **Entwurf:** In den Bereichen, die wir geprüft haben, ist Ihr Kind sicher. Wir halten dieses Niveau und arbeiten am kommenden Stoff weiter.

### Geprüft, ohne Entwurf

- Die i18n-Texte, die eine Wahl voraussetzen, sind keine Bausteine. Bei nachgetragenem Raum wechselt der
  Code sie aus:
  - Kopf „Aktuelles Thema" → „Ausgangspunkt der Analyse"
  - „… — genau dort haben wir angesetzt." → nur „Als nächstes Thema steht … an."
  - „Diese Bereiche liegen unter dem aktuellen Thema" entfällt.
- `empfehlung.mehrere.a` („unter dem aktuellen Stoff") meint den Schulstoff und setzt keine Wahl voraus.
- Ohne Wahl-Bezug, aber noch mit „tragen": `befund_traegt.standard.a/b`, `empfehlung.keine.b`,
  `fazit.mehrere.b`, `fazit.zwei.b`. Siehe den nächsten Abschnitt.

## Weitere Bausteine mit „tragen" (Migration `20261004095314_bausteine_tragen_entwuerfe`)

Es sind die letzten fünf gerenderten Bausteine, die noch „tragen" sagen. Der Inhalt bleibt gleich, nur
das Wort wechselt zu „sicher". Die Platzhalter (`{traegt}`, `{geprueft}`) bleiben; sie sind interne
Namen und erscheinen nicht im Text. Abnahme je Fall mit derselben Anweisung wie oben
(`slot = 'befund_traegt' and fall = 'standard'`, `slot = 'fazit' and fall = 'zwei'` usw.).

Damit spricht kein Baustein mehr von „tragen". Die i18n-Texte tun es noch, und zwar ausgerechnet
neben `befund_traegt`: die Überschriften „Das trägt" und „Das trägt noch nicht", die Lesehilfe und
Legende des Profils sowie `befund.description`. Das sind Code-Texte, keine Bausteine; sie bekommen
einen eigenen Schritt.

### `befund_traegt.standard.a`

- **Wo:** Fuß unter der Liste „Das trägt“ (Abschnitt 03)
- **Heute (abgenommen):** {traegt} von {geprueft} geprüften Bereichen tragen sicher.
- **Entwurf:** {traegt} von {geprueft} geprüften Bereichen sind sicher.

### `befund_traegt.standard.b`

- **Wo:** Fuß unter der Liste „Das trägt“ (Abschnitt 03)
- **Heute (abgenommen):** Von {geprueft} geprüften Bereichen tragen {traegt}.
- **Entwurf:** Von {geprueft} geprüften Bereichen sind {traegt} sicher.

### `empfehlung.keine.b`

- **Wo:** Empfehlung im Schluss
- **Heute (abgenommen):** Der Lernstand trägt. Dieser Rhythmus genügt, um ihn zu halten.
- **Entwurf:** Was wir geprüft haben, ist sicher. Dieser Rhythmus genügt, um diesen Stand zu halten.

### `fazit.mehrere.b`

- **Wo:** Fazit im Schluss
- **Heute (abgenommen):** Was noch nicht trägt, liegt in mehreren Themen verteilt. Deshalb gehen wir der Reihe nach vor und fangen bei den Grundlagen an, auf denen das Übrige aufbaut.
- **Entwurf:** Was noch nicht sicher ist, liegt in mehreren Themen verteilt. Deshalb gehen wir der Reihe nach vor und fangen bei den Grundlagen an, auf denen das Übrige aufbaut.

### `fazit.zwei.b`

- **Wo:** Fazit im Schluss
- **Heute (abgenommen):** Was noch nicht trägt, liegt in zwei Themen. Wir beginnen mit dem, was weiter unten liegt, und gehen von dort nach oben.
- **Entwurf:** Was noch nicht sicher ist, liegt in zwei Themen. Wir beginnen mit dem, was weiter unten liegt, und gehen von dort nach oben.
