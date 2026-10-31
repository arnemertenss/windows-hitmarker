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

public class GrenadeEffect : Form {
    readonly Timer animation = new Timer();
    readonly DateTime started = DateTime.UtcNow;
    readonly Point target;
    readonly bool flash;
    public bool IsFlash { get { return flash; } }
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x80; return p; }
    }
    public GrenadeEffect(Rectangle monitor, Point click, bool isFlash) {
        flash = isFlash;
        target = new Point(click.X - monitor.Left, click.Y - monitor.Top);
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.Manual;
        Bounds = monitor;
        ShowInTaskbar = false;
        TopMost = true;
        BackColor = Color.Magenta;
        TransparencyKey = Color.Magenta;
        DoubleBuffered = true;
        Opacity = 0.7;
        animation.Interval = 16;
        animation.Tick += delegate {
            double age = (DateTime.UtcNow - started).TotalSeconds;
            double lifetime = flash ? 1.7 : 5.0;
            if (age >= lifetime) { Close(); return; }
            if (age >= 0.45) {
                double remaining = (lifetime - age) / (lifetime - 0.45);
                Opacity = flash ? 0.45 * remaining * remaining : 0.7 * Math.Min(1, remaining * 3);
            }
            Invalidate();
        };
        animation.Start();
    }
    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        double age = (DateTime.UtcNow - started).TotalSeconds;
        if (age < 0.45) {
            double progress = age / 0.45;
            int x = (int)(ClientSize.Width / 2 + (target.X - ClientSize.Width / 2) * progress);
            int y = (int)(ClientSize.Height + (target.Y - ClientSize.Height) * progress - Math.Sin(progress * Math.PI) * 140);
            using (var brush = new SolidBrush(flash ? Color.Bisque : Color.OliveDrab)) e.Graphics.FillEllipse(brush, x-7, y-10, 14, 20);
            return;
        }
        if (flash) { e.Graphics.Clear(Color.FromArgb(255, 246, 220)); return; }
        double expansion = Math.Min(1, (age - 0.45) / 0.65);
        for (int i = 0; i < 22; i++) {
            double angle = i * 2.39996;
            double distance = Math.Sqrt(i / 22.0) * 120 * expansion;
            int size = (int)(95 + 35 * expansion + Math.Sin(age * 2 + i) * 8);
            int x = target.X + (int)(Math.Cos(angle) * distance);
            int y = target.Y + (int)(Math.Sin(angle) * distance - (age - 0.45) * 10);
            int shade = 100 + (i * 17) % 60;
            using (var brush = new SolidBrush(Color.FromArgb(shade, shade, shade))) e.Graphics.FillEllipse(brush, x-size/2, y-size/2, size, size);
        }
    }
    protected override void Dispose(bool disposing) {
        if (disposing) animation.Dispose();
        base.Dispose(disposing);
    }
}

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
    Point scopeAim;
    int weapon = 1;
    readonly bool[] selectionDown = new bool[4];
    readonly List<GrenadeEffect> effects = new List<GrenadeEffect>();
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
        menu.Items.Add("1 - Sniper", null, delegate { SelectWeapon(1); });
        menu.Items.Add("2 - Rauchgranate", null, delegate { SelectWeapon(2); });
        menu.Items.Add("3 - Flashbang", null, delegate { SelectWeapon(3); });
        menu.Items.Add("Effekte entfernen (Esc)", null, delegate { ClearEffects(); });
        menu.Items.Add("Hitmarker beenden", null, delegate { Close(); });
        tray.Icon = SystemIcons.Application;
        tray.Text = "Hitmarker: Sniper | 1/2/3 wechseln";
        tray.ContextMenuStrip = menu;
        tray.Visible = true;
        timer.Interval = 10;
        timer.Tick += delegate {
            for (int key = 1; key <= 3; key++) {
                bool pressed = (GetAsyncKeyState(0x30 + key) & 0x8000) != 0;
                if (pressed && !selectionDown[key]) SelectWeapon(key);
                selectionDown[key] = pressed;
            }
            if ((GetAsyncKeyState(0x1B) & 0x8000) != 0) ClearEffects();
            effects.RemoveAll(effect => effect.IsDisposed);
            bool rightDown = weapon == 1 && (GetAsyncKeyState(2) & 0x8000) != 0;
            if (rightDown) {
                Point cursor;
                if (GetCursorPos(out cursor)) {
                    scopeScreen = Screen.FromPoint(cursor).Bounds;
                    scopeScreen.Offset(-Left, -Top);
                    scopeAim = new Point(cursor.X - Left, cursor.Y - Top);
                }
            }
            scoped = rightDown;
            bool down = (GetAsyncKeyState(1) & 0x8000) != 0;
            if (down && !wasDown) {
                Point p;
                if (GetCursorPos(out p)) Fire(p);
            }
            wasDown = down;
            marks.RemoveAll(m => (DateTime.UtcNow - m.Time).TotalMilliseconds > 160);
            Invalidate();
        };
        SystemEventsHook();
        timer.Start();
    }
    void SelectWeapon(int value) {
        weapon = value;
        scoped = false;
        string name = value == 1 ? "Sniper" : value == 2 ? "Rauchgranate" : "Flashbang";
        tray.Text = "Hitmarker: " + name + " | 1/2/3 wechseln";
    }
    void Fire(Point click) {
        if (weapon == 1) {
            PlaySound();
            marks.Add(new Mark { Point = new Point(click.X - Left, click.Y - Top), Time = DateTime.UtcNow });
            return;
        }
        effects.RemoveAll(effect => effect.IsDisposed);
        if (weapon == 3 && effects.Exists(effect => effect.IsFlash)) return;
        if (effects.Count >= 8) { effects[0].Close(); effects.RemoveAt(0); }
        var grenade = new GrenadeEffect(Screen.FromPoint(click).Bounds, click, weapon == 3);
        effects.Add(grenade);
        grenade.Show();
    }
    void ClearEffects() {
        foreach (var effect in effects) effect.Close();
        effects.Clear();
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
    void DrawScope(Graphics graphics, Rectangle screen, Point aim) {
        int cx = aim.X;
        int cy = aim.Y;
        var savedState = graphics.Save();
        graphics.SetClip(screen);
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
        graphics.Restore(savedState);
    }
    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        if (scoped) DrawScope(e.Graphics, scopeScreen, scopeAim);
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
            ClearEffects();
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
