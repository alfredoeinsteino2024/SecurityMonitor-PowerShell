# monitor.ps1 - C:\SecurityCam\monitor.ps1
# Run as Administrator

# EMAIL CONFIG
$gmailFrom  = "toluwanimi.m2300586@st.futminna.edu.ng"
$gmailPass  = "xxxxxxxxxxx"
$alertTo1   = "toluwanimi.m2300586@st.futminna.edu.ng"
$alertTo2   = "alfredfadipe09@gmail.com"

# SYSTEM CONFIG
$footage    = "C:\SecurityCam\footage"
$logFile    = "C:\SecurityCam\logs\monitor.log"
$ffmpegPath = "C:\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$webcam     = "Integrated Webcam"
$threshold  = 2
$lookback   = 30
$pollSecs   = 5

New-Item -ItemType Directory -Force -Path $footage               | Out-Null
New-Item -ItemType Directory -Force -Path "C:\SecurityCam\logs" | Out-Null

$ffmpegProcess = $null
$recording     = $false
$emailSent     = $false

function Write-Log {
    param([string]$msg)
    $line = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " " + $msg
    Write-Host $line
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

function Send-Alert {
    param([string]$Subject, [string]$Body)
    $recipients = @($alertTo1, $alertTo2)
    foreach ($recipient in $recipients) {
        try {
            $smtp             = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
            $smtp.EnableSsl   = $true
            $smtp.Credentials = New-Object System.Net.NetworkCredential($gmailFrom, $gmailPass)
            $msg              = New-Object System.Net.Mail.MailMessage
            $msg.From         = $gmailFrom
            $msg.To.Add($recipient)
            $msg.Subject      = $Subject
            $msg.Body         = $Body
            $msg.IsBodyHtml   = $false
            $smtp.Send($msg)
            Write-Log "EMAIL SENT to $recipient"
        } catch {
            Write-Log "EMAIL FAILED to ${recipient}: $_"
        }
    }
}

function Start-Recording {
    $timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $outputFile = "$footage\capture_$timestamp.mp4"

    # FIX: Use ProcessStartInfo directly for full control over the process
    # Removed conflicting -NoNewWindow + -WindowStyle Hidden combination
    # DirectShow requires its own process context to access the webcam
    $psi                        = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $ffmpegPath
    $psi.Arguments              = "-rtbufsize 100M -f dshow -i video=`"$webcam`" -vcodec libx264 -preset ultrafast `"$outputFile`""
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $false
    $psi.WindowStyle            = [System.Diagnostics.ProcessWindowStyle]::Minimized
    $psi.RedirectStandardInput  = $false
    $psi.RedirectStandardError  = $true
    $psi.RedirectStandardOutput = $false

    $proc = [System.Diagnostics.Process]::Start($psi)

    Start-Sleep -Seconds 4

    if ($proc.HasExited) {
        $errOutput = $proc.StandardError.ReadToEnd()
        Write-Log "ERROR: FFmpeg crashed (code $($proc.ExitCode))"
        Write-Log "FFmpeg error: $errOutput"
        return $null
    }

    Write-Log "Recording started (PID $($proc.Id)) - $outputFile"
    return $proc
}

Write-Log "=== Monitor started === threshold=$threshold lookback=${lookback}s poll=${pollSecs}s"
Write-Log "Alerts will be sent to: $alertTo1 AND $alertTo2"

while ($true) {
    try {
        $since  = (Get-Date).AddSeconds(-$lookback)
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = "Security"
            Id        = 4625
            StartTime = $since
        } -ErrorAction SilentlyContinue

        $count = @($events).Count
        $ts    = Get-Date -Format "HH:mm:ss"
        Write-Host "$ts  Failed logins in last ${lookback}s: $count  |  Recording: $recording"

        if ($count -ge $threshold -and -not $recording) {
            Write-Log "THRESHOLD HIT - $count failed logins - sending alert and starting recording"

            if (-not $emailSent) {
                $d1 = Get-Date -Format "dddd MMMM dd yyyy"
                $d2 = Get-Date -Format "HH:mm:ss"
                $d3 = Get-Date -Format "yyyy-MM-dd"
                $nl = [Environment]::NewLine

                $subject = "SECURITY ALERT: Failed Login Attempts on Your PC"
                $body    = "SECURITY ALERT" + $nl
                $body   += "$d1 $d2" + $nl + $nl
                $body   += "$count failed login attempts detected on your PC." + $nl + $nl
                $body   += "Computer : $env:COMPUTERNAME" + $nl
                $body   += "Account  : $env:USERNAME" + $nl
                $body   += "Date     : $d3" + $nl
                $body   += "Time     : $d2" + $nl + $nl
                $body   += "Webcam recording has started automatically." + $nl
                $body   += "Footage saved to: $footage" + $nl + $nl
                $body   += "If this was not you, your PC may be under unauthorized access." + $nl
                $body   += "-- SecurityMonitor"

                Send-Alert -Subject $subject -Body $body
                $emailSent = $true
            }

            $ffmpegProcess = Start-Recording
            if ($null -ne $ffmpegProcess) {
                $recording = $true
            }
        }

        if ($recording -and (Test-Path "C:\SecurityCam\stop.flag")) {
            Write-Log "Stop flag detected - stopping recording"
            if ($ffmpegProcess -and -not $ffmpegProcess.HasExited) {
                $ffmpegProcess.Kill()
                $ffmpegProcess.WaitForExit(5000) | Out-Null
            }
            Remove-Item "C:\SecurityCam\stop.flag" -Force -ErrorAction SilentlyContinue

            $d4      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $nl      = [Environment]::NewLine
            $subStop = "SecurityMonitor: Recording Stopped on $env:COMPUTERNAME"
            $bodStop = "Recording stopped manually." + $nl + $nl
            $bodStop += "Computer : $env:COMPUTERNAME" + $nl
            $bodStop += "Time     : $d4"
            Send-Alert -Subject $subStop -Body $bodStop

            $recording     = $false
            $ffmpegProcess = $null
            $emailSent     = $false
            Write-Log "Recording stopped. Ready for next incident."
        }

        if ($recording -and $ffmpegProcess -and $ffmpegProcess.HasExited) {
            Write-Log "FFmpeg ended on its own (exit code $($ffmpegProcess.ExitCode))"
            $recording     = $false
            $ffmpegProcess = $null
            $emailSent     = $false
        }

    } catch {
        Write-Log "ERROR: $_"
    }

    Start-Sleep -Seconds $pollSecs
}
