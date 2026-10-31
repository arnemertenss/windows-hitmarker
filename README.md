# Windows Hitmarker

Ein kleines Windows-Overlay: Jeder Linksklick zeigt einen weißen Hitmarker am Mauszeiger und spielt den MLG-Sniper-Sound ab.

## Starten
1. Über **Code → Download ZIP** herunterladen und vollständig entpacken.
2. **Hitmarker-starten.cmd** doppelklicken.
3. Mit der linken Maustaste klicken.
4. **Rechte Maustaste gedrückt halten**, um das Zielfernrohr einzublenden; zum Ausblenden loslassen.

Beenden: Rechtsklick auf das Symbol im Windows-Infobereich → **Hitmarker beenden**. Das Symbol kann unter dem kleinen Pfeil für ausgeblendete Symbole liegen.

## Voraussetzungen
- Windows 10 oder 11 mit Windows PowerShell 5.1 und .NET Framework/WPF.
- Alle drei Dateien müssen im selben Ordner liegen: `Hitmarker.ps1`, `Hitmarker-starten.cmd` und `mlg-sniper.mp3`.
- Keine Installation und keine Administratorrechte erforderlich.

## Verhalten und Anpassung
- Der Hitmarker bleibt etwa 160 Millisekunden sichtbar.
- Das Scope erscheint auf dem Monitor, auf dem sich beim Drücken der rechten Maustaste der Mauszeiger befindet. Im Scope erscheint der Hitmarker mittig.
- Das Scope ist ein grafisches Overlay ohne Bildvergrößerung. Mausklicks werden weiterhin an das darunterliegende Programm weitergegeben.
- Neue Klicks spielen zusätzliche Sounds ab; laufende Sounds klingen weiter aus. Bis zu 32 Sounds können gleichzeitig laufen. Sind alle belegt, wird nur der zusätzliche Sound ausgelassen.
- Lautstärke: `voice.Player.Volume = 0.65;` in `Hitmarker.ps1` anpassen (0 bis 1).
- Eine zweite gestartete Instanz wird automatisch beendet.
- Das Programm erfasst den Zustand der linken und rechten Maustaste lokal. Es zeichnet keine Klicks auf und sendet keine Daten.
- Die Startdatei verwendet die PowerShell-Ausführungsrichtlinie Bypass nur für den gestarteten Prozess.

## Grenzen
Exklusives Vollbild, der Windows-Sicherheitsdesktop und manche geschützten Fenster können das Overlay verdecken. Sehr kurze Klicks können durch die Abfrage im Abstand von 10 ms übersehen werden. Kein Autostart.

## Soundquelle
Der mitgelieferte Clip wird als [B2Q – MLG Sniper auf InstantsButton](https://instantsbutton.com/sound/b2q-mlg-sniper) angeboten.
Die Zuordnung zu einer konkreten Call-of-Duty-Version wurde nicht verifiziert. Der Sound ist ein Drittanbieter-Inhalt; dieses Projekt beansprucht daran keine Rechte und erteilt keine eigene Lizenz dafür. Kein offizielles Call-of-Duty-Projekt.

## Prüfung
C#-Kompilierung und Erstellen/Freigeben des Overlay-Fensters unter Windows PowerShell 5.1 wurden geprüft. Zusätzlich wurde geprüft, dass zwei schnelle Klicks zwei unabhängige Audio-Player belegen. Scope-Maske, transparente Linse und Fadenkreuz wurden mit einem gerenderten Bild geprüft. Keine automatisierte Prüfung der hörbaren Ausgabe oder des Scopes über anderen Programmen.
