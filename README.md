# Windows Hitmarker

Ein kleines Windows-Overlay: Jeder Linksklick zeigt einen weißen Hitmarker am Mauszeiger und spielt den MLG-Sniper-Sound ab.

## Starten
1. Über **Code → Download ZIP** herunterladen und vollständig entpacken.
2. **Hitmarker-starten.cmd** doppelklicken.
3. Mit der linken Maustaste klicken.
4. **Rechte Maustaste gedrückt halten**, um das Zielfernrohr einzublenden; zum Ausblenden loslassen.

Beenden: Rechtsklick auf das Symbol im Windows-Infobereich → **Hitmarker beenden**. Das Symbol kann unter dem kleinen Pfeil für ausgeblendete Symbole liegen.

## Waffen und Granaten
| Taste | Auswahl / Aktion |
| --- | --- |
| 1 | Sniper |
| 2 | Rauchgranate |
| 3 | Flashbang |
| Linksklick | Schießen oder gewählte Granate werfen |
| Rechte Maustaste halten | Scope bei ausgewählter Sniper |
| Esc | Alle Granateneffekte entfernen |

Die Auswahl ist auch über das Symbol im Infobereich möglich. Die Zahlentasten gelten global und werden weiterhin an das aktive Programm weitergegeben. Die aktuelle Auswahl steht im Tooltip des Symbols.

Granaten fliegen in etwa 0,45 Sekunden zum Klickpunkt. Rauch löst sich nach insgesamt 5 Sekunden auf. Die Flashbang zeigt eine warme, halbtransparente Aufhellung des betroffenen Monitors, die nach insgesamt 1,7 Sekunden verschwindet. Laufende Flashbangs werden nicht gestapelt; bis zu 8 Granateneffekte sind gleichzeitig möglich. Alle Effekte lassen Mausklicks durch.

Es sind Desktop-Effekte, keine Integration in Counter-Strike. Die Granaten verwenden keine originalen Counter-Strike-Sounds.

## Voraussetzungen
- Windows 10 oder 11 mit Windows PowerShell 5.1 und .NET Framework/WPF.
- Alle drei Dateien müssen im selben Ordner liegen: `Hitmarker.ps1`, `Hitmarker-starten.cmd` und `mlg-sniper.mp3`.
- Keine Installation und keine Administratorrechte erforderlich.

## Verhalten und Anpassung
- Der Hitmarker bleibt etwa 160 Millisekunden sichtbar.
- Das Scope folgt dem Mauszeiger, auch beim Wechsel zwischen Monitoren. Das Fadenkreuz und die Hitmarker liegen am tatsächlichen Klickpunkt. Am Bildschirmrand wird das Scope abgeschnitten, damit das Ziel exakt unter dem Mauszeiger bleibt.
- Das Scope ist ein grafisches Overlay ohne Bildvergrößerung. Mausklicks werden weiterhin an das darunterliegende Programm weitergegeben.
- Neue Klicks spielen zusätzliche Sounds ab; laufende Sounds klingen weiter aus. Bis zu 32 Sounds können gleichzeitig laufen. Sind alle belegt, wird nur der zusätzliche Sound ausgelassen.
- Lautstärke: `voice.Player.Volume = 0.65;` in `Hitmarker.ps1` anpassen (0 bis 1).
- Eine zweite gestartete Instanz wird automatisch beendet.
- Das Programm erfasst den Zustand der linken und rechten Maustaste sowie der Tasten 1, 2, 3 und Esc lokal. Es zeichnet keine Klicks auf und sendet keine Daten.
- Die Startdatei verwendet die PowerShell-Ausführungsrichtlinie Bypass nur für den gestarteten Prozess.

## Grenzen
Exklusives Vollbild, der Windows-Sicherheitsdesktop und manche geschützten Fenster können das Overlay verdecken. Sehr kurze Klicks können durch die Abfrage im Abstand von 10 ms übersehen werden. Kein Autostart.

## Soundquelle
Der mitgelieferte Clip wird als [B2Q – MLG Sniper auf InstantsButton](https://instantsbutton.com/sound/b2q-mlg-sniper) angeboten.
Die Zuordnung zu einer konkreten Call-of-Duty-Version wurde nicht verifiziert. Der Sound ist ein Drittanbieter-Inhalt; dieses Projekt beansprucht daran keine Rechte und erteilt keine eigene Lizenz dafür. Kein offizielles Call-of-Duty-Projekt.

## Prüfung
C#-Kompilierung und Erstellen/Freigeben des Overlay-Fensters unter Windows PowerShell 5.1 wurden geprüft. Zusätzlich wurde geprüft, dass zwei schnelle Klicks zwei unabhängige Audio-Player belegen. Scope-Maske, transparente Linse, Fadenkreuz am Mausziel und Beschneidung am Monitorrand wurden mit gerenderten Bildern geprüft. Zusätzlich geprüft: Waffenwahl, Rauch-/Flash-Zuordnung, Begrenzung gleichzeitiger Flashbangs, Entfernen der Effekte und Sniper-Schüsse. Keine automatisierte Prüfung der hörbaren Ausgabe oder der Darstellung über anderen Programmen.
