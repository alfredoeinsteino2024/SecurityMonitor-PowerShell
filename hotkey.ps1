# =============================================================================
# hotkey.ps1  —  C:\SecurityCam\hotkey.ps1
# Runs in the background and listens for Ctrl+Alt+S.
# When pressed, writes C:\SecurityCam\stop.flag so monitor.ps1 stops recording.
#
# Run in a SEPARATE PowerShell window (does not need to be Administrator).
# =============================================================================

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class HotkeyListener : Form {

    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, int fsModifiers, int vk);

    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    // Modifier constants
    // MOD_ALT     = 0x0001
    // MOD_CONTROL = 0x0002
    private const int MOD_ALT     = 0x0001;
    private const int MOD_CONTROL = 0x0002;
    private const int VK_S        = 0x53;   // 'S' key
    private const int HOTKEY_ID   = 1;
    private const int WM_HOTKEY   = 0x0312;

    private string flagFile  = @"C:\SecurityCam\stop.flag";
    private string logFile   = @"C:\SecurityCam\logs\monitor.log";

    public HotkeyListener() {
        // Keep window completely invisible
        this.WindowState   = FormWindowState.Minimized;
        this.ShowInTaskbar = false;
        this.Opacity       = 0;
        this.FormBorderStyle = FormBorderStyle.None;
        this.Size          = new System.Drawing.Size(1, 1);
    }

    // FIX: Register the hotkey here, NOT in the constructor.
    // OnHandleCreated fires once the Win32 window handle actually exists,
    // which is required for RegisterHotKey to succeed.
    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        bool ok = RegisterHotKey(this.Handle, HOTKEY_ID, MOD_CONTROL | MOD_ALT, VK_S);
        if (ok) {
            Log("Hotkey registered: Ctrl+Alt+S — press to stop recording.");
        } else {
            Log("WARNING: Hotkey registration failed (another app may own Ctrl+Alt+S).");
        }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HOTKEY_ID) {
            Log("Ctrl+Alt+S pressed — writing stop flag.");
            try {
                File.WriteAllText(flagFile, "stop");
            } catch (Exception ex) {
                Log("ERROR writing stop flag: " + ex.Message);
            }
        }
        base.WndProc(ref m);
    }

    protected override void OnFormClosed(FormClosedEventArgs e) {
        UnregisterHotKey(this.Handle, HOTKEY_ID);
        Log("Hotkey listener stopped.");
        base.OnFormClosed(e);
    }

    private void Log(string msg) {
        try {
            string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " [HOTKEY] " + msg;
            Console.WriteLine(line);
            File.AppendAllText(logFile, line + Environment.NewLine);
        } catch {}
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms"

Write-Host "Hotkey listener starting... Press Ctrl+Alt+S to stop recording."
Write-Host "Close this window to stop the hotkey listener."

$form = New-Object HotkeyListener
[System.Windows.Forms.Application]::Run($form)
