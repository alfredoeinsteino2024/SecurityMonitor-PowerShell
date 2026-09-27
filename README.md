# SecurityMonitor-PowerShell

A Windows PowerShell security monitoring tool that automatically detects
failed login attempts on your PC and responds by:
- Starting webcam recording via FFmpeg
- Sending instant email alerts to multiple addresses
- Logging all activity with timestamps

Built as a solo side project by Fadipe Toluwanimi Alfred (ChainEngineers).

---

## How It Works

```
Windows Security Event Log
        |
Event ID 4625 detected (failed login)
        |
Threshold reached (2 failed attempts in 30 seconds)
        |
Email alert sent to configured addresses
        |
Webcam recording starts automatically via FFmpeg
        |
Footage saved to C:\SecurityCam\footage\
        |
Stop via Ctrl+Alt+S or stop.ps1
```

---

## Features

- Monitors Windows Security Event Log in real time
- Sliding 30-second detection window (no false accumulation)
- Automatic webcam recording via FFmpeg DirectShow
- Email alerts via Gmail SMTP to multiple addresses
- Timestamped logging of all events
- Hotkey support (Ctrl+Alt+S) to stop recording
- Manual stop script with acknowledgement feedback
- Duplicate trigger protection (one recording per incident)
- FFmpeg crash detection with error logging

---

## Requirements

- Windows 10 or Windows 11
- PowerShell (must be run as Administrator)
- FFmpeg installed from https://www.gyan.dev/ffmpeg/builds/
- Gmail account with 2-Step Verification enabled
- Gmail App Password from myaccount.google.com/apppasswords
- Webcam (built-in or external)

---

## Folder Structure

```
C:\SecurityCam\
|-- monitor.ps1          main monitoring script
|-- hotkey.ps1           hotkey listener (Ctrl+Alt+S)
|-- stop.ps1             manual stop script
|-- footage\             recorded video files saved here
|-- logs\
    |-- monitor.log      full event log
    |-- ffmpeg_error.log FFmpeg error output
```

---

## Setup

### 1. Install FFmpeg
Download from https://www.gyan.dev/ffmpeg/builds/ and extract to:
```
C:\ffmpeg-8.1.1-essentials_build\
```
Verify installation:
```powershell
ffmpeg -version
```

### 2. Find your exact webcam name
```powershell
ffmpeg -list_devices true -f dshow -i dummy 2>&1
```
Look for your webcam name under the (video) devices section.

### 3. Configure monitor.ps1
Open monitor.ps1 in Notepad and update these lines at the top:
```powershell
$gmailFrom  = "your-email@gmail.com"
$gmailPass  = "your-app-password-here"
$alertTo1   = "your-email@gmail.com"
$alertTo2   = "second-email@gmail.com"
$webcam     = "Your Webcam Name Here"
$ffmpegPath = "C:\path\to\ffmpeg.exe"
```

### 4. Create the SecurityCam folder
```powershell
New-Item -ItemType Directory -Force -Path C:\SecurityCam\footage
New-Item -ItemType Directory -Force -Path C:\SecurityCam\logs
```
Copy all three scripts into C:\SecurityCam\

---

## Usage

### Start monitoring
```powershell
# Open PowerShell as Administrator
cd C:\SecurityCam
Set-ExecutionPolicy Bypass -Scope Process -Force
.\monitor.ps1
```

### Start hotkey listener (optional, separate window)
```powershell
.\hotkey.ps1
```

### Stop recording manually
```powershell
.\stop.ps1
```
Or press Ctrl+Alt+S if hotkey.ps1 is running.

---

## Expected Console Output

```
2026-05-15 10:00:00 === Monitor started === threshold=2 lookback=30s poll=5s
2026-05-15 10:00:00 Alerts will be sent to: email1 AND email2
10:00:05  Failed logins in last 30s: 0  |  Recording: False
10:00:10  Failed logins in last 30s: 2  |  Recording: False
2026-05-15 10:00:10 THRESHOLD HIT - 2 failed logins - sending alert and starting recording
2026-05-15 10:00:11 EMAIL SENT to email1
2026-05-15 10:00:12 EMAIL SENT to email2
2026-05-15 10:00:14 Recording started (PID 5432) - C:\SecurityCam\footage\capture_2026-05-15_10-00-10.mp4
10:00:19  Failed logins in last 30s: 2  |  Recording: True
```

---

## Email Alert Format

```
SECURITY ALERT
Thursday May 15 2026 10:00:10

2 failed login attempts detected on your PC.

Computer : DESKTOP-XXXXX
Account  : YourUsername
Date     : 2026-05-15
Time     : 10:00:10

Webcam recording has started automatically.
Footage saved to: C:\SecurityCam\footage

If this was not you, your PC may be under unauthorized access.
-- SecurityMonitor
```

---

## Limitations

- Requires user to be logged in (PowerShell must be running)
- Webcam cannot be accessed at the Windows login screen (OS-level restriction)
- DirectShow webcam access requires a user session context
- Gmail App Password must be kept private inside the script

---

## Planned Improvements

- [ ] Convert to Windows Service for pre-login monitoring
- [ ] SMS alerts via Twilio
- [ ] Email video attachment when recording finishes
- [ ] Auto-start via Task Scheduler on login
- [ ] Telegram bot notifications

---

## Tech Stack

- PowerShell
- Windows Event Log (Event ID 4625)
- FFmpeg + DirectShow
- Gmail SMTP (System.Net.Mail)
- Windows Forms (hotkey listener)
- Win32 API via C# (RegisterHotKey)

---

## Author

Fadipe Toluwanimi Alfred
Mechatronics Engineering - Federal University of Technology, Minna
GitHub: https://github.com/alfredoeinsteino2024
LinkedIn: https://linkedin.com/in/toluwanimialfred
Built under ChainEngineers

---

<img width="572" height="1279" alt="WhatsApp Image 2026-09-27 at 7 59 21 PM" src="https://github.com/user-attachments/assets/de3e2e7f-cc39-4119-82d9-9ae36be93b95" />
<img width="572" height="1279" alt="WhatsApp Image 2026-09-27 at 7 59 20 PM (1)" src="https://github.com/user-attachments/assets/89eedf4e-d1ab-429a-8727-e037a1f1ec2e" />
<img width="572" height="1279" alt="WhatsApp Image 2026-09-27 at 7 59 20 PM" src="https://github.com/user-attachments/assets/be8b9895-3b17-4112-bc99-b7bf7f75c93f" />
<img width="572" height="1279" alt="WhatsApp Image 2026-09-27 at 7 59 21 PM (1)" src="https://github.com/user-attachments/assets/791a96d0-9d70-453e-829e-e6c9207ebbb2" />

## License

MIT License - free to use, modify and distribute.


