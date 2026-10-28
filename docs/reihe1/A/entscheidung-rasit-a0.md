# Entscheidung Rasit zum A0-Haltepunkt (27.10.2026, wörtlich)

1. Alle 1184 Aufgaben werden lsa. Der Default {lsa,session} von einsatz entfällt. Neue Aufgaben müssen ihren Pool ausdrücklich angeben, Bauform-Instanzen setzen session. Der CHECK aus A1.2 verbietet beide zugleich.
2. VERA8 wird komplett gelöscht: alle VERA8-Aufgaben samt Teilen, Lösungen, Hinweisen, Figuren (auch die Dateien in Storage), Fehlbild-Zuordnungen, Prüfprotokollen und Einträgen in Item-Pflege und Lena-Board. Für genau diesen Schritt ist die Leitplanke „keine löschenden Anweisungen" aufgehoben, sonst gilt sie weiter.
   a) Per dbread feststellen, woran VERA8-Aufgaben erkennbar sind (Quelle, Charge, Präfix o. ä.). Zahl nennen und mit der Abfrage belegen.
   b) Per pg_constraint und pg_proc alle Tabellen und Funktionen finden, die auf diese Aufgaben verweisen. Verweist eine LSA-Antwort, eine Session-Antwort oder ein Skill-Urteil auf eine VERA8-Aufgabe: Liste ins Protokoll und STOPP für diesen Teil. Nichts kaskadierend mitlöschen.
   c) Vor dem Löschen eine vollständige Sicherung aller betroffenen Zeilen als SQL-Datei nach ~/backups/vera8-<datum>.sql, Storage-Dateien nach ~/backups/vera8-figuren/. Nicht ins Repo committen, die Inhalte sind urheberrechtlich geschützt.
   d) Eigene Migration „VERA8 entfernen" (getrennt von der Pool-Trennung), Löschen in der Reihenfolge der Abhängigkeiten. Rollback-Skript = Wiederherstellung aus der Sicherung.
   e) Zeilenzahlen vorher und nachher in die PR. Danach per Code-Suche (git grep) Reste von VERA8 in beiden Repos auflisten (Filter, Importskripte, Texte). Unbenutztes entfernen, im Zweifel nur auflisten.
3. Nenne in der PR, wie viele der verbleibenden Aufgaben AFB 3 haben.
4. Die 12 schon gezogenen Doppel-Aufgaben sind Testdaten: nur im Bericht nennen.
5. an-C.md: Bis zur ersten Freigabe von Bauform-Instanzen zieht die Session nichts. C zeigt dann einen ruhigen Leerzustand statt eines Fehlers.
Dann weiter mit A1 und den folgenden Phasen.
