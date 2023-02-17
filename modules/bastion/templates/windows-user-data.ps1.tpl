<powershell>
# Download and extract quaterly STIG GPO package
$url = "https://public.cyber.mil/stigs/gpo/"
$html = Invoke-WebRequest -Uri $url -UseBasicParsing
$lines = $html.Content.Split("`n")
$filteredLines = $lines | Where-Object { $_ -like "*stigs/zip*" }
$zipFile = $filteredLines.TrimStart().Replace("<a href=", "").Replace(" target=", "").Replace("`"_blank`">", "").Replace(" ", "").Replace("`"", "")
$outputFile = $zipFile.Replace("https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/", "")
$localGpoZipFile = "C:\Users\Public\Downloads\$outputFile"

Invoke-WebRequest -Uri $zipFile -OutFile $localGpoZipFile -ErrorAction Stop

Expand-Archive -Path $localGpoZipFile -DestinationPath C:\Temp -Force

# Download LGPO and extract executable
Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip" -OutFile "C:\Users\Public\Downloads\LGPO.zip" -ErrorAction Stop
Expand-Archive -Path C:\Users\Public\Downloads\LGPO.zip -DestinationPath C:\Users\Public\Downloads -Force

# Uninstall Internet Explorer
Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 –Online -NoRestart

# Install Microsoft Edge
md -Path $env:temp\edgeinstall -erroraction SilentlyContinue | Out-Null
$Download = join-path $env:temp\edgeinstall MicrosoftEdgeEnterpriseX64.msi
(new-object System.Net.WebClient).DownloadFile('https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/cae8ab77-630c-402e-8fac-829629b974be/MicrosoftEdgeEnterpriseX64.msi',$Download)
Start-Process "$Download" -ArgumentList "/quiet" -Wait

# Reboot OS
Restart-Computer -Force

# Execute quaterly STIG GPO package
# Remove existing STIG GPOs
$excludeFolders = @("DoD Windows Server 2019 MS v2r5")
Get-ChildItem -Path "C:\Temp\Support Files\Local Policies" -Directory | Where-Object { $_.Name -notin $excludeFolders } | Remove-Item -Recurse -Force

# Copy STIG GPOs to local policies folder
Copy-Item -Path "C:\Temp\DoD Microsoft Defender Antivirus*" -Destination "C:\Temp\Support Files\Local Policies" -Recurse -Force
Copy-Item -Path "C:\Temp\DoD Microsoft Edge*" -Destination "C:\Temp\Support Files\Local Policies" -Recurse -Force
Copy-Item -Path "C:\Temp\DoD Windows Firewall*" -Destination "C:\Temp\Support Files\Local Policies" -Recurse -Force

# Copy LGPO.exe to support files folder
Copy-Item -Path "C:\Users\Public\Downloads\LGPO_30\LGPO.exe" -Destination "C:\Temp\Support Files\LGPO.exe" -Force

# Execute GPO update batch file
$batch = "C:\Temp\Support Files\Sample_LGPO.bat"
$content = Get-Content $batch
$content = $content | Where-Object { $_ -notlike "pause" }
$content | Set-Content $batch

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c C:\Temp\SUPPOR~1\Sample_LGPO.bat"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet
$task = Register-ScheduledTask -TaskName "GPO Update" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
Start-ScheduledTask -TaskName "GPO Update"
Start-Sleep -Seconds 60

# Disable scheduled task
Disable-ScheduledTask -TaskName "GPO Update"
Start-Sleep -Seconds 3
</powershell>



# Create new user and add to local admin/rdp group
$Password = Read-Host -AsSecureString
<enter a password>
New-LocalUser "cyber" -Password $Password
net user cyber /passwordreq:yes
net localgroup "Remote Desktop Users" cyber /add
net localgroup "administrators" cyber /add
