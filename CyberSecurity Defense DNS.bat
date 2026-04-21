@echo off
setlocal

set DNS=172.64.36.1
set DNS2=172.64.36.2
set TPL=https://1g07vsk7mz.cloudflare-gateway.com/dns-query

:: Self-elevate to Administrator if not already
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Extract embedded PowerShell script to temp file and run it
set "PSFILE=%TEMP%\cybersecuritydefenseofficial_%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b='%~f0';$t='%PSFILE%';$l=[IO.File]::ReadAllLines($b);$s=0;for($i=0;$i-lt$l.Count;$i++){if($l[$i]-eq'::PSSTART'){$s=$i+1;break}};[IO.File]::WriteAllLines($t,$l[$s..($l.Count-1)],[Text.Encoding]::UTF8)"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"
del "%PSFILE%" 2>nul
exit /b

::PSSTART
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ── Windows version check (requires Windows 10 2004+, build 19041) ───────────
if ([System.Environment]::OSVersion.Version.Build -lt 19041) {
    [System.Windows.Forms.MessageBox]::Show('Windows 10 version 2004 (May 2020) or later is required.', 'CyberSecurity Defense Official DNS', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

$DNS  = $env:DNS
$DNS2 = $env:DNS2
$TPL  = $env:TPL

# ── Warning dialog ────────────────────────────────────────────────────────────
$wPad = 24
$wW   = 380
$wH   = $wPad + 36 + 16 + 80 + $wPad + 32 + $wPad

$warnForm = New-Object System.Windows.Forms.Form
$warnForm.Text            = 'CyberSecurity Defense Cloudflare DNS'
$warnForm.ClientSize      = New-Object System.Drawing.Size($wW, $wH)
$warnForm.StartPosition   = 'CenterScreen'
$warnForm.FormBorderStyle = 'FixedDialog'
$warnForm.MaximizeBox     = $false
$warnForm.MinimizeBox     = $false
$warnForm.BackColor       = [System.Drawing.Color]::White

$wy = $wPad

$wLogo           = New-Object System.Windows.Forms.Label
$wLogo.Text      = 'CyberSecurity Defense Official'
$wLogo.Font      = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$wLogo.ForeColor = [System.Drawing.Color]::FromArgb(27, 27, 32)
$wLogo.AutoSize  = $false
$wLogo.Width     = $wW
$wLogo.Height    = 36
$wLogo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$wLogo.Location  = New-Object System.Drawing.Point(0, $wy)
$warnForm.Controls.Add($wLogo)
$wy += 36 + 16

$wMsg           = New-Object System.Windows.Forms.Label
$wMsg.Text      = "WARNING! All browsers will be restarted to apply the settings.`n`nPlease save all data before continuing."
$wMsg.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
$wMsg.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$wMsg.AutoSize  = $false
$wMsg.Width     = $wW - $wPad * 2
$wMsg.Height    = 80
$wMsg.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
$wMsg.Location  = New-Object System.Drawing.Point($wPad, $wy)
$warnForm.Controls.Add($wMsg)
$wy += 80 + $wPad

$wBtnOk              = New-Object System.Windows.Forms.Button
$wBtnOk.Text         = 'Continue'
$wBtnOk.Width        = 100
$wBtnOk.Height       = 32
$wBtnOk.Location     = New-Object System.Drawing.Point(($wW / 2 + 4), $wy)
$wBtnOk.BackColor    = [System.Drawing.Color]::FromArgb(0, 120, 215)
$wBtnOk.ForeColor    = [System.Drawing.Color]::White
$wBtnOk.FlatStyle    = [System.Windows.Forms.FlatStyle]::Flat
$wBtnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
$warnForm.Controls.Add($wBtnOk)
$warnForm.AcceptButton = $wBtnOk

$wBtnCancel              = New-Object System.Windows.Forms.Button
$wBtnCancel.Text         = 'Cancel'
$wBtnCancel.Width        = 100
$wBtnCancel.Height       = 32
$wBtnCancel.Location     = New-Object System.Drawing.Point(($wW / 2 - 100 - 4), $wy)
$wBtnCancel.FlatStyle    = [System.Windows.Forms.FlatStyle]::Flat
$wBtnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$warnForm.Controls.Add($wBtnCancel)
$warnForm.CancelButton = $wBtnCancel

if ($warnForm.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }

# ── Browser detection ─────────────────────────────────────────────────────────
$lad = $env:LOCALAPPDATA
$pf  = $env:PROGRAMFILES
$pfx = ${env:ProgramFiles(x86)}

$browserDefs = @(
    @{ Name='Google Chrome';  Key='chrome';  Paths=@("$lad\Google\Chrome\Application\chrome.exe", "$pf\Google\Chrome\Application\chrome.exe", "$pfx\Google\Chrome\Application\chrome.exe") },
    @{ Name='Firefox';        Key='firefox'; Paths=@("$pf\Mozilla Firefox\firefox.exe", "$pfx\Mozilla Firefox\firefox.exe") },
    @{ Name='Microsoft Edge'; Key='edge';    Paths=@("$pfx\Microsoft\Edge\Application\msedge.exe", "$pf\Microsoft\Edge\Application\msedge.exe") },
    @{ Name='Opera';          Key='opera';   Paths=@("$lad\Programs\Opera\opera.exe", "$pf\Opera\opera.exe") },
    @{ Name='Opera GX';       Key='operagx'; Paths=@("$lad\Programs\Opera GX\opera.exe") },
    @{ Name='Brave Browser';  Key='brave';   Paths=@("$lad\BraveSoftware\Brave-Browser\Application\brave.exe", "$pf\BraveSoftware\Brave-Browser\Application\brave.exe") },
    @{ Name='Vivaldi';        Key='vivaldi'; Paths=@("$lad\Vivaldi\Application\vivaldi.exe", "$pf\Vivaldi\Application\vivaldi.exe") },
    @{ Name='Arc';            Key='arc';     Paths=@("$lad\Programs\Arc\Arc.exe") }
)
$installed = $browserDefs | Where-Object { ($_.Paths | Where-Object { Test-Path $_ } | Measure-Object).Count -gt 0 }

# ── Build dialog ──────────────────────────────────────────────────────────────
$pad     = 24
$itemH   = 26
$gap     = 6
$cbCount = 1 + ($installed | Measure-Object).Count
$cbAreaH = $cbCount * $itemH + ($cbCount - 1) * $gap
$clientW = 420
$clientH = $pad + 36 + 10 + 38 + 14 + $cbAreaH + $pad + 36 + $pad

$form = New-Object System.Windows.Forms.Form
$form.Text            = 'CyberSecurity Defense Cloudflare DNS'
$form.ClientSize      = New-Object System.Drawing.Size($clientW, $clientH)
$form.StartPosition   = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.BackColor       = [System.Drawing.Color]::White

$y = $pad

# Logo
$logo           = New-Object System.Windows.Forms.Label
$logo.Text      = 'CyberSecurity Defense Official'
$logo.Font      = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$logo.ForeColor = [System.Drawing.Color]::FromArgb(27, 27, 32)
$logo.AutoSize  = $false
$logo.Width     = $clientW
$logo.Height    = 36
$logo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$logo.Location  = New-Object System.Drawing.Point(0, $y)
$form.Controls.Add($logo)
$y += 36 + 10

# Subtitle (centered, secondary)
$subLbl           = New-Object System.Windows.Forms.Label
$subLbl.Text      = 'Check items to enable CyberSecurity Defense Official DNS. Uncheck to disable.'
$subLbl.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
$subLbl.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$subLbl.AutoSize  = $false
$subLbl.Width     = $clientW - $pad * 2
$subLbl.Height    = 38
$subLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$subLbl.Location  = New-Object System.Drawing.Point($pad, $y)
$form.Controls.Add($subLbl)
$y += 38 + 14

# System DNS checkbox
$cbSys          = New-Object System.Windows.Forms.CheckBox
$cbSys.Text     = 'System DNS (all apps)'
$cbSys.Font     = New-Object System.Drawing.Font('Segoe UI', 10)
$cbSys.Checked  = $true
$cbSys.AutoSize = $true
$cbSys.Location = New-Object System.Drawing.Point($pad, $y)
$form.Controls.Add($cbSys)
$y += $itemH + $gap

# Browser checkboxes (installed only)
$browserCbs = @{}
foreach ($b in $installed) {
    $cb          = New-Object System.Windows.Forms.CheckBox
    $cb.Text     = $b.Name
    $cb.Font     = New-Object System.Drawing.Font('Segoe UI', 10)
    $cb.Checked  = $true
    $cb.AutoSize = $true
    $cb.Location = New-Object System.Drawing.Point($pad, $y)
    $form.Controls.Add($cb)
    $browserCbs[$b.Key] = $cb
    $y += $itemH + $gap
}
$y += $pad - $gap

# OK / Cancel buttons
$btnOk              = New-Object System.Windows.Forms.Button
$btnOk.Text         = 'OK'
$btnOk.Width        = 88
$btnOk.Height       = 32
$btnOk.Location     = New-Object System.Drawing.Point(($clientW / 2 + 4), $y)
$btnOk.BackColor    = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnOk.ForeColor    = [System.Drawing.Color]::White
$btnOk.FlatStyle    = [System.Windows.Forms.FlatStyle]::Flat
$btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($btnOk)
$form.AcceptButton  = $btnOk

$btnCancel              = New-Object System.Windows.Forms.Button
$btnCancel.Text         = 'Cancel'
$btnCancel.Width        = 88
$btnCancel.Height       = 32
$btnCancel.Location     = New-Object System.Drawing.Point(($clientW / 2 - 88 - 4), $y)
$btnCancel.FlatStyle    = [System.Windows.Forms.FlatStyle]::Flat
$btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($btnCancel)
$form.CancelButton  = $btnCancel

if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }

# ── Close running browsers before applying settings ───────────────────────────
$procMap = @{
    'chrome'  = 'chrome'
    'firefox' = 'firefox'
    'edge'    = 'msedge'
    'opera'   = 'opera'
    'operagx' = 'opera'
    'brave'   = 'brave'
    'vivaldi' = 'vivaldi'
    'arc'     = 'Arc'
}
foreach ($key in $procMap.Keys) {
    if ($browserCbs.ContainsKey($key) -and $browserCbs[$key].Checked) {
        Get-Process -Name $procMap[$key] -ErrorAction SilentlyContinue |
            ForEach-Object { $_.CloseMainWindow() | Out-Null }
    }
}
Start-Sleep -Seconds 2
foreach ($key in $procMap.Keys) {
    if ($browserCbs.ContainsKey($key) -and $browserCbs[$key].Checked) {
        Stop-Process -Name $procMap[$key] -Force -ErrorAction SilentlyContinue
    }
}

# ── Helper: Chromium DoH registry policy ──────────────────────────────────────
function Set-ChromiumDoh {
    param($regPath, $enable)
    if ($enable) {
        New-Item $regPath -Force | Out-Null
        Set-ItemProperty $regPath DnsOverHttpsMode      'secure'
        Set-ItemProperty $regPath DnsOverHttpsTemplates "$TPL{?dns}"
    } else {
        Remove-ItemProperty -Path $regPath -Name DnsOverHttpsMode      -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $regPath -Name DnsOverHttpsTemplates -ErrorAction SilentlyContinue
    }
}

# ── System DNS ────────────────────────────────────────────────────────────────
if ($cbSys.Checked) {
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' EnableAutoDoh 2
    foreach ($srv in @($DNS, $DNS2)) {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers\$srv"
        New-Item $key -Force | Out-Null
        Set-ItemProperty $key DohTemplate      $TPL
        Set-ItemProperty $key AutoUpgrade       1
        Set-ItemProperty $key AllowFallbackToUdp 0
    }
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddress @($DNS, $DNS2)
    }
} else {
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' EnableAutoDoh 0
    foreach ($srv in @($DNS, $DNS2)) {
        Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers\$srv" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses
    }
}

# ── Browser policies ──────────────────────────────────────────────────────────
if ($browserCbs.ContainsKey('chrome'))  { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Google\Chrome'               $browserCbs['chrome'].Checked  }
if ($browserCbs.ContainsKey('edge'))    { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'              $browserCbs['edge'].Checked    }
if ($browserCbs.ContainsKey('opera'))   { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Opera Software\Opera'        $browserCbs['opera'].Checked   }
if ($browserCbs.ContainsKey('operagx')) { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Opera Software\Opera GX'     $browserCbs['operagx'].Checked }
if ($browserCbs.ContainsKey('brave'))   { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'         $browserCbs['brave'].Checked   }
if ($browserCbs.ContainsKey('vivaldi')) { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Vivaldi'                      $browserCbs['vivaldi'].Checked }
if ($browserCbs.ContainsKey('arc'))     { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\TheBrowserCompany\Arc'       $browserCbs['arc'].Checked     }

if ($browserCbs.ContainsKey('firefox')) {
    if ($browserCbs['firefox'].Checked) {
        $ff = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS'
        New-Item $ff -Force | Out-Null
        Set-ItemProperty $ff Enabled     1
        Set-ItemProperty $ff ProviderURL $TPL
        Set-ItemProperty $ff Locked      0
        $ffProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $ffProfiles) {
            Get-ChildItem -Path $ffProfiles -Directory | ForEach-Object {
                $ujs = Join-Path $_.FullName 'user.js'
                $content = Get-Content $ujs -ErrorAction SilentlyContinue
                $newLines = @(
                    "user_pref(`"network.trr.mode`", 3);",
                    "user_pref(`"network.trr.uri`", `"$TPL`");",
                    "user_pref(`"network.trr.custom_uri`", `"$TPL`");"
                )
                $filtered = $content | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' }
                ($filtered + $newLines) | Set-Content $ujs -Encoding UTF8
            }
        }
    } else {
        Remove-Item 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS' -Recurse -Force -ErrorAction SilentlyContinue
        $ffProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $ffProfiles) {
            Get-ChildItem -Path $ffProfiles -Directory | ForEach-Object {
                $ujs = Join-Path $_.FullName 'user.js'
                if (Test-Path $ujs) {
                    $filtered = Get-Content $ujs | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' }
                    $filtered | Set-Content $ujs -Encoding UTF8
                }
                $pjs = Join-Path $_.FullName 'prefs.js'
                if (Test-Path $pjs) {
                    $filtered = Get-Content $pjs | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' }
                    $filtered | Set-Content $pjs -Encoding UTF8
                }
            }
        }
    }
}

# ── Flush DNS cache ───────────────────────────────────────────────────────────
Clear-DnsClientCache

# ── Success ───────────────────────────────────────────────────────────────────
[System.Windows.Forms.MessageBox]::Show("Settings applied`n`nRestart browsers for changes to take effect.", 'CyberSecurity Defense Official DNS', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null