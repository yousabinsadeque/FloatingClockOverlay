using System;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Threading;

namespace FloatingClockOverlay;

public partial class ClockWindow : Window
{
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TRANSPARENT = 0x20;
    private const int WS_EX_LAYERED = 0x80;
    private const int WM_HOTKEY = 0x0312;
    private const int HOTKEY_ID = 9000;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_ALT = 0x0001;
    private const uint VK_C = 0x43;

    [DllImport("user32.dll")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    private readonly DispatcherTimer _timer;
    private bool _isClickThrough;
    private IntPtr _hwnd;

    public ClockWindow()
    {
        InitializeComponent();

        Left = SystemParameters.WorkArea.Width - 320;
        Top = 40;

        _timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        _timer.Tick += (_, _) => UpdateClock();
        _timer.Start();
        UpdateClock();
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        _hwnd = new WindowInteropHelper(this).Handle;
        HwndSource.FromHwnd(_hwnd)?.AddHook(WndProc);
        RegisterHotKey(_hwnd, HOTKEY_ID, MOD_CONTROL | MOD_ALT, VK_C);
    }

    protected override void OnClosed(EventArgs e)
    {
        UnregisterHotKey(_hwnd, HOTKEY_ID);
        base.OnClosed(e);
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WM_HOTKEY && wParam.ToInt32() == HOTKEY_ID)
        {
            ToggleClickThrough();
            handled = true;
        }
        return IntPtr.Zero;
    }

    private void UpdateClock()
    {
        ClockText.Text = DateTime.Now.ToString("h:mm:ss tt");
    }

    private void Border_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }

    public void ToggleClickThrough()
    {
        _isClickThrough = !_isClickThrough;
        int extendedStyle = GetWindowLong(_hwnd, GWL_EXSTYLE);
        SetWindowLong(_hwnd, GWL_EXSTYLE,
            _isClickThrough
                ? extendedStyle | WS_EX_TRANSPARENT | WS_EX_LAYERED
                : extendedStyle & ~WS_EX_TRANSPARENT);
    }

    public void ToggleVisibility()
    {
        Visibility = Visibility == Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
    }
}
