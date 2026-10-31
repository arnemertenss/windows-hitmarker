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
    readonly System.Windows.Media.MediaPlayer sound;
    bool wasDown;
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x08000000 | 0x80; return p; }
    }
    public ClickMarker(string soundPath) {
        sound = new System.Windows.Media.MediaPlayer();
        sound.Volume = 0.65;
        sound.Open(new Uri(soundPath));
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
            bool down = (GetAsyncKeyState(1) & 0x8000) != 0;
            if (down && !wasDown) {
                sound.Position = TimeSpan.Zero;
                sound.Play();
                Point p;
                if (GetCursorPos(out p)) marks.Add(new Mark { Point = new Point(p.X - Left, p.Y - Top), Time = DateTime.UtcNow });
            }
            wasDown = down;
            marks.RemoveAll(m => (DateTime.UtcNow - m.Time).TotalMilliseconds > 160);
            Invalidate();
        };
        SystemEventsHook();
        timer.Start();
    }
    void SystemEventsHook() { Microsoft.Win32.SystemEvents.DisplaySettingsChanged += DisplayChanged; }
    void DisplayChanged(object sender, EventArgs e) { Bounds = SystemInformation.VirtualScreen; }
    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
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
            timer.Dispose(); sound.Close(); tray.Visible = false; tray.Dispose();
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
