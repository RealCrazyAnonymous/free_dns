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

:: Embedded PowerShell script to do GUI and system changes
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    # Check Windows version (Windows 10 2004+)
    if ([System.Environment]::OSVersion.Version.Build -lt 19041) {
        [System.Windows.Forms.MessageBox]::Show('Windows 10 version 2004 (May 2020) or later is required.', 'CyberSecurity Defense Official DNS', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        exit
    }

    # Variables from batch environment
    $DNS = '%DNS%'
    $DNS2 = '%DNS2%'
    $TPL = '%TPL%'

    # Warning dialog
    $wPad = 24
    $wW = 380
    $wH = $wPad + 36 + 16 + 80 + $wPad + 32 + $wPad
    $warnForm = New-Object System.Windows.Forms.Form
    $warnForm.Text = 'CyberSecurity Defense Cloudflare DNS'
    $warnForm.ClientSize = New-Object System.Drawing.Size($wW, $wH)
    $warnForm.StartPosition = 'CenterScreen'
    $warnForm.FormBorderStyle = 'FixedDialog'
    $warnForm.MaximizeBox = $false
    $warnForm.MinimizeBox = $false
    $warnForm.BackColor = [System.Drawing.Color]::White

    $wy = $wPad

    # Title Label
    $wLogo = New-Object System.Windows.Forms.Label
    $wLogo.Text = 'CyberSecurity Defense Official'
    $wLogo.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
    $wLogo.ForeColor = [System.Drawing.Color]::FromArgb(27, 27, 32)
    $wLogo.AutoSize = $false
    $wLogo.Width = $wW
    $wLogo.Height = 36
    $wLogo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $wLogo.Location = New-Object System.Drawing.Point(0, $wy)
    $warnForm.Controls.Add($wLogo)
    $wy += 36 + 16

    # Warning message
    $wMsg = New-Object System.Windows.Forms.Label
    $wMsg.Text = "WARNING! All browsers will be restarted to apply the settings.`n`nPlease save all data before continuing."
    $wMsg.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $wMsg.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $wMsg.AutoSize = $false
    $wMsg.Width = $wW - $wPad * 2
    $wMsg.Height = 80
    $wMsg.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $wMsg.Location = New-Object System.Drawing.Point($wPad, $wy)
    $warnForm.Controls.Add($wMsg)
    $wy += 80 + $wPad

    # Continue Button
    $wBtnOk = New-Object System.Windows.Forms.Button
    $wBtnOk.Text = 'Continue'
    $wBtnOk.Width = 100
    $wBtnOk.Height = 32
    $wBtnOk.Location = New-Object System.Drawing.Point(($wW / 2 + 4), $wy)
    $wBtnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $wBtnOk.ForeColor = [System.Drawing.Color]::White
    $wBtnOk.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $wBtnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $warnForm.Controls.Add($wBtnOk)
    $warnForm.AcceptButton = $wBtnOk

    # Cancel Button
    $wBtnCancel = New-Object System.Windows.Forms.Button
    $wBtnCancel.Text = 'Cancel'
    $wBtnCancel.Width = 100
    $wBtnCancel.Height = 32
    $wBtnCancel.Location = New-Object System.Drawing.Point(($wW / 2 - 100 - 4), $wy)
    $wBtnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $wBtnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $warnForm.Controls.Add($wBtnCancel)
    $warnForm.CancelButton = $wBtnCancel

    if ($warnForm.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }

    # Browser detection
    $env:LOCALAPPDATA = [Environment]::GetFolderPath('LocalApplicationData')
    $env:PROGRAMFILES = ${env:ProgramFiles}
    $env:ProgramFilesX86 = ${env:ProgramFiles(x86)}

    $browserDefs = @(
        @{ Name='Google Chrome';  Key='chrome';  Paths=@("$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe", "$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe", "$env:ProgramFilesX86\Google\Chrome\Application\chrome.exe") },
        @{ Name='Firefox';        Key='firefox'; Paths=@("$env:ProgramFiles\Mozilla Firefox\firefox.exe", "$env:ProgramFilesX86\Mozilla Firefox\firefox.exe") },
        @{ Name='Microsoft Edge'; Key='edge';    Paths=@("$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFilesX86\Microsoft\Edge\Application\msedge.exe") },
        @{ Name='Opera';          Key='opera';   Paths=@("$env:LOCALAPPDATA\Programs\Opera\opera.exe", "$env:ProgramFiles\Opera\opera.exe") },
        @{ Name='Opera GX';       Key='operagx'; Paths=@("$env:LOCALAPPDATA\Programs\Opera GX\opera.exe") },
        @{ Name='Brave Browser';  Key='brave';   Paths=@("$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe") },
        @{ Name='Vivaldi';        Key='vivaldi'; Paths=@("$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe", "$env:ProgramFiles\Vivaldi\Application\vivaldi.exe") },
        @{ Name='Arc';            Key='arc';     Paths=@("$env:LOCALAPPDATA\Programs\Arc\Arc.exe") }
    )

    $installed = $browserDefs | Where-Object {
        $_.Paths | Where-Object { Test-Path $_ } | Measure-Object | Select-Object -ExpandProperty Count
    }

    # Build GUI for checkboxes
    $pad = 24
    $itemH = 26
    $gap = 6
    $cbCount = 1 + ($installed | Measure-Object).Count
    $cbAreaH = $cbCount * $itemH + ($cbCount - 1) * $gap
    $clientW = 420
    $clientH = $pad + 36 + 10 + 38 + 14 + $cbAreaH + $pad + 36 + $pad

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'CyberSecurity Defense Cloudflare DNS'
    $form.ClientSize = New-Object System.Drawing.Size($clientW, $clientH)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::White

    $y = $pad

    # Logo Label
    $logo = New-Object System.Windows.Forms.Label
    $logo.Text = 'CyberSecurity Defense Official'
    $logo.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
    $logo.ForeColor = [System.Drawing.Color]::FromArgb(27, 27, 32)
    $logo.AutoSize = $false
    $logo.Width = $clientW
    $logo.Height = 36
    $logo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $logo.Location = New-Object System.Drawing.Point(0, $y)
    $form.Controls.Add($logo)
    $y += 36 + 10

    # Subtitle Label
    $subLbl = New-Object System.Windows.Forms.Label
    $subLbl.Text = 'Check items to enable CyberSecurity Defense Official DNS. Uncheck to disable.'
    $subLbl.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $subLbl.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $subLbl.AutoSize = $false
    $subLbl.Width = $clientW - $pad * 2
    $subLbl.Height = 38
    $subLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $subLbl.Location = New-Object System.Drawing.Point($pad, $y)
    $form.Controls.Add($subLbl)
    $y += 38 + 14

    # System DNS checkbox
    $cbSys = New-Object System.Windows.Forms.CheckBox
    $cbSys.Text = 'System DNS (all apps)'
    $cbSys.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $cbSys.Checked = $true
    $cbSys.AutoSize = $true
    $cbSys.Location = New-Object System.Drawing.Point($pad, $y)
    $form.Controls.Add($cbSys)
    $y += $itemH + $gap

    # Browser checkboxes
    $browserCbs = @{}
    foreach ($b in $installed) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $b.Name
        $cb.Font = New-Object System.Drawing.Font('Segoe UI', 10)
        $cb.Checked = $true
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point($pad, $y)
        $form.Controls.Add($cb)
        $browserCbs[$b.Key] = $cb
        $y += $itemH + $gap
    }
    $y += $pad - $gap

    # OK and Cancel buttons
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = 'OK'
    $btnOk.Width = 88
    $btnOk.Height = 32
    $btnOk.Location = New-Object System.Drawing.Point(($clientW / 2 + 4), $y)
    $btnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnOk.ForeColor = [System.Drawing.Color]::White
    $btnOk.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOk)
    $form.AcceptButton = $btnOk

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Width = 88
    $btnCancel.Height = 32
    $btnCancel.Location = New-Object System.Drawing.Point(($clientW / 2 - 88 - 4), $y)
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)
    $form.CancelButton = $btnCancel

    if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }

    # Close browsers
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
            Get-Process -Name $procMap[$key] -ErrorAction SilentlyContinue | ForEach-Object { $_.CloseMainWindow() | Out-Null }
        }
    }
    Start-Sleep -Seconds 2
    foreach ($key in $procMap.Keys) {
        if ($browserCbs.ContainsKey($key) -and $browserCbs[$key].Checked) {
            Stop-Process -Name $procMap[$key] -Force -ErrorAction SilentlyContinue
        }
    }

    # Functions to set Chromium DoH policies
    function Set-ChromiumDoh {
        param($regPath, $enable)
        if ($enable) {
            New-Item -Path $regPath -Force | Out-Null
            Set-ItemProperty -Path $regPath -Name 'DnsOverHttpsMode' -Value 'secure'
            Set-ItemProperty -Path $regPath -Name 'DnsOverHttpsTemplates' -Value $TPL'{?dns}'
        } else {
            Remove-ItemProperty -Path $regPath -Name 'DnsOverHttpsMode' -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name 'DnsOverHttpsTemplates' -ErrorAction SilentlyContinue
        }
    }

    # Apply System DNS settings
    if ($cbSys.Checked) {
        # Enable DoH
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'EnableAutoDoh' -Value 2 -Force
        foreach ($srv in @($DNS, $DNS2)) {
            $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers\$srv"
            New-Item -Path $key -Force | Out-Null
            Set-ItemProperty -Path $key -Name 'DohTemplate' -Value $TPL
            Set-ItemProperty -Path $key -Name 'AutoUpgrade' -Value 1
            Set-ItemProperty -Path $key -Name 'AllowFallbackToUdp' -Value 0
        }
        # Set DNS addresses
        Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddress @($DNS, $DNS2)
        }
    } else {
        # Disable DoH
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'EnableAutoDoh' -Value 0 -Force
        foreach ($srv in @($DNS, $DNS2)) {
            Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DohWellKnownServers\$srv" -Recurse -Force -ErrorAction SilentlyContinue
        }
        # Reset DNS
        Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses
        }
    }

    # Apply browser policies
    if ($browserCbs.ContainsKey('chrome'))  { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Google\Chrome'               $browserCbs['chrome'].Checked  }
    if ($browserCbs.ContainsKey('edge'))    { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'              $browserCbs['edge'].Checked    }
    if ($browserCbs.ContainsKey('opera'))   { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Opera Software\Opera'        $browserCbs['opera'].Checked   }
    if ($browserCbs.ContainsKey('operagx')) { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Opera Software\Opera GX'     $browserCbs['operagx'].Checked }
    if ($browserCbs.ContainsKey('brave'))   { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'         $browserCbs['brave'].Checked   }
    if ($browserCbs.ContainsKey('vivaldi')) { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\Vivaldi'                      $browserCbs['vivaldi'].Checked }
    if ($browserCbs.ContainsKey('arc'))     { Set-ChromiumDoh 'HKLM:\SOFTWARE\Policies\TheBrowserCompany\Arc'       $browserCbs['arc'].Checked     }

    # Firefox DNS Over HTTPS
    if ($browserCbs.ContainsKey('firefox')) {
        if ($browserCbs['firefox'].Checked) {
            $ffRegPath = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS'
            New-Item -Path $ffRegPath -Force | Out-Null
            Set-ItemProperty -Path $ffRegPath -Name 'Enabled' -Value 1
            Set-ItemProperty -Path $ffRegPath -Name 'ProviderURL' -Value $TPL
            Set-ItemProperty -Path $ffRegPath -Name 'Locked' -Value 0
            # Update user.js in Firefox profiles
            $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
            if (Test-Path $profilesPath) {
                Get-ChildItem -Path $profilesPath -Directory | ForEach-Object {
                    $userJs = Join-Path $_.FullName 'user.js'
                    $content = @(
                        'user_pref("network.trr.mode", 3);'
                        'user_pref("network.trr.uri", "' + $TPL + '");'
                        'user_pref("network.trr.custom_uri", "' + $TPL + '");'
                    )
                    $filtered = if (Test-Path $userJs) { Get-Content $userJs | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' } } else { @() }
                    $filtered + $content | Set-Content -Path $userJs -Encoding UTF8
                }
            }
        } else {
            # Remove policies and reset Firefox configs
            Remove-Item 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\DNSOverHTTPS' -Recurse -Force -ErrorAction SilentlyContinue
            $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
            if (Test-Path $profilesPath) {
                Get-ChildItem -Path $profilesPath -Directory | ForEach-Object {
                    $userJs = Join-Path $_.FullName 'user.js'
                    if (Test-Path $userJs) {
                        $content = Get-Content $userJs | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' }
                        $content | Set-Content -Path $userJs -Encoding UTF8
                    }
                    $prefsJs = Join-Path $_.FullName 'prefs.js'
                    if (Test-Path $prefsJs) {
                        $content = Get-Content $prefsJs | Where-Object { $_ -notmatch 'network.trr.(mode|uri|custom_uri)' }
                        $content | Set-Content -Path $prefsJs -Encoding UTF8
                    }
                }
            }
        }
    }

    # Flush DNS cache
    Clear-DnsClientCache

    # Notify user
    [System.Windows.Forms.MessageBox]::Show("Settings applied`n`nRestart browsers for changes to take effect.", 'CyberSecurity Defense Official DNS', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}"