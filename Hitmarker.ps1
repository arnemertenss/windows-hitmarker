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
    [StructLayout(LayoutKind.Sequential)] struct Blend { public byte Operation, Flags, Alpha, Format; }
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr window);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr window, IntPtr dc);
    [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleDC(IntPtr dc);
    [DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr dc, IntPtr value);
    [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr value);
    [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr dc);
    [DllImport("user32.dll")] static extern bool UpdateLayeredWindow(IntPtr window, IntPtr dst, ref Point pos, ref Size size, IntPtr src, ref Point origin, int key, ref Blend blend, int flags);
    readonly Timer animation = new Timer();
    readonly DateTime started = DateTime.UtcNow;
    readonly Point target;
    readonly bool flash;
    readonly System.Windows.Media.MediaPlayer throwSound = new System.Windows.Media.MediaPlayer();
    readonly System.Windows.Media.MediaPlayer burstSound = new System.Windows.Media.MediaPlayer();
    readonly Bitmap frame;
    bool detonated;
    public bool IsFlash { get { return flash; } }
    public const double Fuse = 0.85;
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x80; return p; }
    }
    public GrenadeEffect(Rectangle monitor, Point click, bool isFlash, string audioDirectory) {
        flash = isFlash;
        target = new Point(click.X - monitor.Left, click.Y - monitor.Top);
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.Manual;
        Bounds = monitor;
        ShowInTaskbar = false;
        TopMost = true;
        frame = new Bitmap(monitor.Width, monitor.Height, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
        throwSound.Volume = 0.45;
        burstSound.Volume = flash ? 0.4 : 0.55;
        throwSound.Open(new Uri(System.IO.Path.Combine(audioDirectory, "csgo-throw.mp3")));
        burstSound.Open(new Uri(System.IO.Path.Combine(audioDirectory, flash ? "csgo-flashbang.mp3" : "csgo-smoke.mp3")));
        Shown += delegate { throwSound.Play(); Present(0); };
        animation.Interval = 33;
        animation.Tick += delegate {
            double age = (DateTime.UtcNow - started).TotalSeconds;
            if (age >= (flash ? 4.0 : 9.0)) { Close(); return; }
            if (age >= Fuse && !detonated) { detonated = true; burstSound.Play(); }
            Present(age);
        };
        animation.Start();
    }
    void Present(double age) {
        using (var g = Graphics.FromImage(frame)) {
            g.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
            g.Clear(Color.Transparent);
            g.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceOver;
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            DrawEffect(g, age);
        }
        IntPtr screen = GetDC(IntPtr.Zero), memory = CreateCompatibleDC(screen);
        IntPtr bitmap = frame.GetHbitmap(Color.FromArgb(0));
        IntPtr old = SelectObject(memory, bitmap);
        try {
            Point pos = Location, origin = Point.Empty;
            Size size = frame.Size;
            var blend = new Blend { Operation = 0, Alpha = 255, Format = 1 };
            UpdateLayeredWindow(Handle, screen, ref pos, ref size, memory, ref origin, 0, ref blend, 2);
        } finally { SelectObject(memory, old); DeleteObject(bitmap); DeleteDC(memory); ReleaseDC(IntPtr.Zero, screen); }
    }
    void DrawCanister(Graphics g, float x, float y, float angle) {
        var state = g.Save();
        g.TranslateTransform(x, y);
        g.RotateTransform(angle);
        var body = new Rectangle(-8, -17, 16, 34);
        using (var metal = new System.Drawing.Drawing2D.LinearGradientBrush(body, Color.FromArgb(65,69,64), Color.FromArgb(190,193,181), 0f)) g.FillRectangle(metal, body);
        using (var stripe = new SolidBrush(flash ? Color.FromArgb(190,178,137) : Color.FromArgb(54,85,51))) g.FillRectangle(stripe, -8, -5, 16, 10);
        using (var edge = new Pen(Color.FromArgb(45,48,43), 2)) {
            g.DrawRectangle(edge, body);
            g.DrawLine(edge, -8, -12, 8, -12);
            g.DrawLine(edge, -8, 12, 8, 12);
        }
        g.FillRectangle(Brushes.DimGray, -5, -22, 10, 5);
        using (var pin = new Pen(Color.Silver, 2)) { g.DrawEllipse(pin, 3, -27, 10, 10); g.DrawLine(pin, -6, -21, 11, -13); }
        g.Restore(state);
    }
    void DrawEffect(Graphics g, double age) {
        if (age < Fuse) {
            double t = Math.Min(1, age / 0.65);
            float x = (float)(ClientSize.Width * 0.65 + (target.X - ClientSize.Width * 0.65) * t);
            float y = (float)(ClientSize.Height + 25 + (target.Y - ClientSize.Height - 25) * t - Math.Sin(t * Math.PI) * 190);
            if (age > 0.65) y -= (float)(Math.Sin((age-0.65)/0.2*Math.PI)*24);
            DrawCanister(g, x, y, (float)(t*490));
            return;
        }
        double elapsed = age - Fuse;
        if (flash) {
            // One continuous bloom, short hold, then gradual recovery.
            double strength = elapsed < 0.08 ? elapsed/0.08 : elapsed < 0.25 ? 1 : Math.Exp(-(elapsed-0.25)*1.6);
            using (var wash = new SolidBrush(Color.FromArgb((int)(215*strength), 250,250,245))) g.FillRectangle(wash, ClientRectangle);
            Glow(g, target.X, target.Y, 200+(float)(elapsed*80), (int)(30*strength), 255);
            return;
        }
        double expansion = 1-Math.Exp(-elapsed*2.2);
        double fade = Math.Min(1, (9.0-age)/2.5);
        double density = Math.Min(1, elapsed*2) * Math.Max(0,fade);
        for (int i=0; i<64; i++) {
            double angle = i*2.399963;
            double distance = Math.Sqrt((i+0.5)/64.0)*165*expansion;
            float x = target.X+(float)(Math.Cos(angle)*distance+Math.Sin(elapsed*0.7+i)*12*expansion);
            float y = target.Y+(float)(Math.Sin(angle)*distance*0.72-elapsed*8+Math.Cos(i+elapsed)*7);
            float radius = (float)((65+(i*13)%45)*(.3+.7*expansion));
            int shade = 112+(i*19)%58;
            Glow(g,x,y,radius,(int)((42+(i%5)*6)*density),shade);
        }
    }
    static void Glow(Graphics g, float x, float y, float radius, int alpha, int shade) {
        using (var path = new System.Drawing.Drawing2D.GraphicsPath()) {
            path.AddEllipse(x-radius,y-radius,radius*2,radius*2);
            using (var brush = new System.Drawing.Drawing2D.PathGradientBrush(path)) {
                brush.CenterColor = Color.FromArgb(Math.Max(0,Math.Min(255,alpha)),shade,shade,shade);
                brush.SurroundColors = new Color[] { Color.FromArgb(0,shade,shade,shade) };
                g.FillPath(brush,path);
            }
        }
    }
    protected override void Dispose(bool disposing) {
        if (disposing) { animation.Dispose(); throwSound.Close(); burstSound.Close(); frame.Dispose(); }
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
    readonly string audioDirectory;
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x80; return p; }
    }
    public ClickMarker(string soundPath) {
        audioDirectory = System.IO.Path.GetDirectoryName(soundPath);
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
        if (effects.Count >= 4) { effects[0].Close(); effects.RemoveAt(0); }
        var grenade = new GrenadeEffect(Screen.FromPoint(click).Bounds, click, weapon == 3, audioDirectory);
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

