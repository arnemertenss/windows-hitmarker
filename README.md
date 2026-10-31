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

Granaten fliegen rotierend zum Klickpunkt, prallen leicht auf und zünden nach etwa 0,85 Sekunden. Beim Wurf und bei der Zündung werden getrennte Sounds gespielt. Rauch wächst als bewegte Wolke mit echter Transparenz und weichen Rändern, hält an und löst sich nach insgesamt 9 Sekunden auf. Die Flashbang blendet einmal kurz auf und klingt über etwa 3 Sekunden ab. Laufende Flashbangs werden nicht gestapelt; bis zu 4 Granateneffekte sind gleichzeitig möglich. Alle Effekte lassen Mausklicks durch. Esc entfernt auch laufende Granatensounds.

Es sind Desktop-Effekte, keine Integration in Counter-Strike. Die Granaten verwenden Clips, die von SoundDino als CS:GO-Sounds angeboten werden; die Herkunft aus den Original-Spieldateien wurde nicht unabhängig bestätigt.

## Voraussetzungen
- Windows 10 oder 11 mit Windows PowerShell 5.1 und .NET Framework/WPF.
- Alle Dateien aus dem ZIP müssen zusammenbleiben: Startdatei, PowerShell-Skript sowie `mlg-sniper.mp3`, `csgo-throw.mp3`, `csgo-smoke.mp3` und `csgo-flashbang.mp3`.
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

## Soundquellen
Der mitgelieferte Clip wird als [B2Q – MLG Sniper auf InstantsButton](https://instantsbutton.com/sound/b2q-mlg-sniper) angeboten.
Die Zuordnung zu einer konkreten Call-of-Duty-Version wurde nicht verifiziert. Der Sound ist ein Drittanbieter-Inhalt; dieses Projekt beansprucht daran keine Rechte und erteilt keine eigene Lizenz dafür. Kein offizielles Call-of-Duty- oder Counter-Strike-Projekt.

Wurf-, Rauch- und Flashbang-Sounds: [SoundDino – Counter-Strike](https://sounddino.com/en/effects/counter-strike/). Die heruntergeladenen Clips sind Drittanbieter-Inhalte und werden von diesem Projekt nicht neu lizenziert.

## Prüfung
C#-Kompilierung und Erstellen/Freigeben des Overlay-Fensters unter Windows PowerShell 5.1 wurden geprüft. Zusätzlich wurde geprüft, dass zwei schnelle Klicks zwei unabhängige Audio-Player belegen. Scope-Maske, transparente Linse, Fadenkreuz am Mausziel und Beschneidung am Monitorrand wurden mit gerenderten Bildern geprüft. Zusätzlich geprüft: Waffenwahl, Rauch-/Flash-Zuordnung, Begrenzung gleichzeitiger Flashbangs, Entfernen der Effekte und Sniper-Schüsse. Keine automatisierte Prüfung der hörbaren Ausgabe oder der Darstellung über anderen Programmen.

Die neue Granatendarstellung wurde auf Alpha-Transparenz und Flash-Abklingen geprüft; alle drei CS:GO-Audioclips wurden mit dem Windows-Mediadecoder geladen und ihre Spieldauer geprüft.
