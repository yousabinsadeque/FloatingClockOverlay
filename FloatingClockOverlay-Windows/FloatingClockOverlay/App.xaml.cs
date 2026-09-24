using System.Windows;
using Forms = System.Windows.Forms;

namespace FloatingClockOverlay;

public partial class App : System.Windows.Application
{
    private Forms.NotifyIcon? _trayIcon;
    private ClockWindow? _clockWindow;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        _clockWindow = new ClockWindow();
        _clockWindow.Show();

        _trayIcon = new Forms.NotifyIcon
        {
            Icon = System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = "Floating Clock Overlay"
        };

        var menu = new Forms.ContextMenuStrip();

        var toggleClickThroughItem = new Forms.ToolStripMenuItem("Click-Through (Ctrl+Alt+C)");
        toggleClickThroughItem.Click += (_, _) => _clockWindow?.ToggleClickThrough();
        menu.Items.Add(toggleClickThroughItem);

        var showHideItem = new Forms.ToolStripMenuItem("Show/Hide");
        showHideItem.Click += (_, _) => _clockWindow?.ToggleVisibility();
        menu.Items.Add(showHideItem);

        menu.Items.Add(new Forms.ToolStripSeparator());

        var quitItem = new Forms.ToolStripMenuItem("Quit");
        quitItem.Click += (_, _) => Shutdown();
        menu.Items.Add(quitItem);

        _trayIcon.ContextMenuStrip = menu;
        _trayIcon.DoubleClick += (_, _) => _clockWindow?.ToggleVisibility();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _trayIcon?.Dispose();
        base.OnExit(e);
    }
}
