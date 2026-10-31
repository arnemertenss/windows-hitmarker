Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$source = @'
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class ClickMarker : Form {
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] static extern bool GetCursorPos(out Point point);
    private class Mark { public Point Point; public DateTime Time; }
    readonly List<Mark> marks = new List<Mark>();
    readonly Timer timer = new Timer();
    readonly NotifyIcon tray = new NotifyIcon();
    private class Voice {
        public readonly System.Windows.Media.MediaPlayer Player = new System.Windows.Media.MediaPlayer();
        public bool Busy;
    }
    readonly List<Voice> voices = new List<Voice>();
    bool wasDown;
    bool scoped;
    Rectangle scopeScreen;
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x80; return p; }
    }
    public ClickMarker(string soundPath) {
        for (int i = 0; i < 32; i++) {
            var voice = new Voice();
            voice.Player.Volume = 0.65;
            voice.Player.MediaEnded += delegate { voice.Busy = false; };
            voice.Player.MediaFailed += delegate { voice.Busy = false; };
            voice.Player.Open(new Uri(soundPath));
            voices.Add(voice);
        }
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        Bounds = SystemInformation.VirtualScreen;
        BackColor = Color.Magenta;
        TransparencyKey = Color.Magenta;
        TopMost = true;
        DoubleBuffered = true;
        var menu = new ContextMenuStrip();
        menu.Items.Add("Hitmarker beenden", null, delegate { Close(); });
        tray.Icon = SystemIcons.Application;
        tray.Text = "Hitmarker (Rechtsklick zum Beenden)";
        tray.ContextMenuStrip = menu;
        tray.Visible = true;
        timer.Interval = 10;
        timer.Tick += delegate {
            bool rightDown = (GetAsyncKeyState(2) & 0x8000) != 0;
            if (rightDown && !scoped) {
                Point cursor;
                if (GetCursorPos(out cursor)) {
                    scopeScreen = Screen.FromPoint(cursor).Bounds;
                    scopeScreen.Offset(-Left, -Top);
                }
            }
            scoped = rightDown;
            bool down = (GetAsyncKeyState(1) & 0x8000) != 0;
            if (down && !wasDown) {
                PlaySound();
                Point p;
                if (GetCursorPos(out p)) marks.Add(new Mark {
                    Point = scoped ? new Point(scopeScreen.Left + scopeScreen.Width / 2, scopeScreen.Top + scopeScreen.Height / 2) : new Point(p.X - Left, p.Y - Top),
                    Time = DateTime.UtcNow
                });
            }
            wasDown = down;
            marks.RemoveAll(m => (DateTime.UtcNow - m.Time).TotalMilliseconds > 160);
            Invalidate();
        };
        SystemEventsHook();
        timer.Start();
    }
    void PlaySound() {
        foreach (var voice in voices) {
            if (voice.Busy) continue;
            voice.Busy = true;
            voice.Player.Position = TimeSpan.Zero;
            voice.Player.Play();
            return;
        }
        // Keep existing sounds playing if all 32 voices are occupied.
    }
    void SystemEventsHook() { Microsoft.Win32.SystemEvents.DisplaySettingsChanged += DisplayChanged; }
    void DisplayChanged(object sender, EventArgs e) { Bounds = SystemInformation.VirtualScreen; scoped = false; }
    void DrawScope(Graphics graphics, Rectangle screen) {
        int cx = screen.Left + screen.Width / 2;
        int cy = screen.Top + screen.Height / 2;
        int radius = Math.Max(1, Math.Min(screen.Width, screen.Height) * 40 / 100);
        var lens = new Rectangle(cx - radius, cy - radius, radius * 2, radius * 2);
        using (var mask = new System.Drawing.Drawing2D.GraphicsPath(System.Drawing.Drawing2D.FillMode.Alternate)) {
            mask.AddRectangle(screen);
            mask.AddEllipse(lens);
            graphics.FillPath(Brushes.Black, mask);
        }
        using (var rim = new Pen(Color.FromArgb(40, 40, 40), 6))
        using (var reticle = new Pen(Color.Black, 2)) {
            graphics.DrawEllipse(rim, lens);
            graphics.DrawLine(reticle, cx - radius, cy, cx + radius, cy);
            graphics.DrawLine(reticle, cx, cy - radius, cx, cy + radius);
            for (int i = -3; i <= 3; i++) {
                if (i == 0) continue;
                int offset = i * radius / 5;
                graphics.DrawLine(reticle, cx + offset, cy - 5, cx + offset, cy + 5);
                graphics.DrawLine(reticle, cx - 5, cy + offset, cx + 5, cy + offset);
            }
        }
    }
    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        if (scoped) DrawScope(e.Graphics, scopeScreen);
        foreach (var m in marks) {
            int x = m.Point.X, y = m.Point.Y;
            using (var shadow = new Pen(Color.FromArgb(35,35,35), 5))
            using (var white = new Pen(Color.White, 3)) {
                for (int sx = -1; sx <= 1; sx += 2)
                    for (int sy = -1; sy <= 1; sy += 2) {
                        e.Graphics.DrawLine(shadow, x+sx*7, y+sy*7, x+sx*17, y+sy*17);
                        e.Graphics.DrawLine(white, x+sx*7, y+sy*7, x+sx*17, y+sy*17);
                    }
            }
        }
    }
    protected override void Dispose(bool disposing) {
        if (disposing) {
            timer.Dispose();
            foreach (var voice in voices) voice.Player.Close();
            tray.Visible = false; tray.Dispose();
            Microsoft.Win32.SystemEvents.DisplaySettingsChanged -= DisplayChanged;
        }
        base.Dispose(disposing);
    }
    [STAThread] public static void Run(string soundPath) {
        bool created;
        using (var mutex = new System.Threading.Mutex(true, "Local\\CodexClickHitmarker", out created)) {
            if (!created) return;
            SetProcessDPIAware();
            Application.EnableVisualStyles();
            Application.Run(new ClickMarker(soundPath));
        }
    }
}
'@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms,System.Drawing,PresentationCore,WindowsBase
[ClickMarker]::Run((Join-Path $PSScriptRoot 'mlg-sniper.mp3'))
