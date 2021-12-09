param (
    [string]$VMLinuxPrivateIP
)

# Creating InstallDir
$Downloaddir = "C:\InstallDir"
if ((Test-Path -Path $Downloaddir) -ne $true) {
    mkdir $Downloaddir
}
cd $Downloaddir

Start-Transcript ($Downloaddir+".\InstallPSScript.log")

function Log($Message){
    Write-Output (([System.DateTime]::Now).ToString() + " " + $Message)
}

function Add-SystemPaths([array] $PathsToAdd) {
    $VerifiedPathsToAdd = ""
    foreach ($Path in $PathsToAdd) {
        if ($Env:Path -like "*$Path*") {
            Log("  Path to $Path already added")
        }
        else {
            $VerifiedPathsToAdd += ";$Path";Log("  Path to $Path needs to be added")
        }
    }
    if ($VerifiedPathsToAdd -ne "") {
        Log("Adding paths: $VerifiedPathsToAdd")
        [System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + "$VerifiedPathsToAdd","Machine")
        Log("Note: Reloading Path env to the current script")
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Log("##########################")
Log("# Adding Host Entry")
Log("##########################")
Add-Content C:\Windows\system32\drivers\etc\hosts ""
Add-Content C:\Windows\system32\drivers\etc\hosts "$VMLinuxPrivateIP       contoso.com"
Add-Content C:\Windows\system32\drivers\etc\hosts "$VMLinuxPrivateIP       www.contoso.com"
Get-Content C:\Windows\system32\drivers\etc\hosts

Log("##########################")
Log("# Downloading Source Code Apps")
Log("##########################")
Invoke-WebRequest -Uri "https://github.com/edisga/test1/raw/master/oss-labs.zip" -OutFile ($Downloaddir+"\oss-labs.zip")
Log("Extracting source Code Files")
Expand-Archive -Path ($Downloaddir+"\oss-labs.zip") -DestinationPath $Downloaddir
Log("Cleaning...")
Remove-Item ($Downloaddir+"\oss-labs\VMTemplate") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\StaticDesign") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.gitignore") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\README.md") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.vscode") -Recurse -Confirm:$False
Remove-Item ($Downloaddir+"\oss-labs\.git") -Recurse -Confirm:$False
Move-Item ($Downloaddir+"\oss-labs") ($Downloaddir+"\apps")

Log("##########################")
Log("# Installing VSCode")
Log("##########################")
#$url = "https://aka.ms/win32-x64-user-stable"
#$url = "https://vscode-update.azurewebsites.net/latest/win32-x64-user/stable"
#$url = "https://go.microsoft.com/fwlink/?Linkid=852157"
$url = "https://vscode-update.azurewebsites.net/latest/win32-x64/stable"

Log("Downloading VSCode from $url to VSCodeSetup.exe")
Invoke-WebRequest -Uri $url -OutFile ($Downloaddir+"\VSCodeSetup.exe")
Unblock-File ($Downloaddir+"\VSCodeSetup.exe")
Log("Installing VSCode Using the command: $Downloaddir\VSCodeSetup.exe /verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath")
$VSCodeInstallResult = (Start-Process ($Downloaddir+"\VSCodeSetup.exe") '/verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath,desktopicon,quicklaunchicon' -Wait -Passthru).ExitCode
if ($VSCodeInstallResult -eq 0) {
    Log("Install VSCode Success")
}
Log("Installing VSCode Extensions")
$VSCodeInstallPath = "C:\Program Files\Microsoft VS Code\bin"
cd $VSCodeInstallPath
.\code --install-extension ms-vscode.powershell -force
.\code --install-extension ms-azuretools.vscode-docker -force
.\code --install-extension ms-vscode.csharp -force
.\code --install-extension ms-python.python -force
.\code --install-extension vscode-icons-team.vscode-icons -force
.\code --install-extension visualstudioexptteam.vscodeintellicode -force
.\code --install-extension vscjava.vscode-maven -force
.\code --install-extension vscjava.vscode-spring-boot-dashboard -force
.\code --install-extension pivotal.vscode-spring-boot -force
.\code --install-extension vscjava.vscode-spring-initializr -force
.\code --install-extension vscjava.vscode-java-debug -force
cd $Downloaddir

Log("##########################")
Log("# Installing Google Chrome")
Log("##########################")
Invoke-WebRequest 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile ($Downloaddir+"\chrome_installer.exe")
Unblock-File ($Downloaddir+"\chrome_installer.exe")
$ChromeInstallResult = (Start-Process ($Downloaddir+"\chrome_installer.exe") '/silent /install' -Wait -Passthru).ExitCode
if ($ChromeInstallResult -eq 0) {
    Log("Install Chrome Success")
}

Log("##########################")
Log("# Installing NodeJS")
Log("##########################")
Invoke-WebRequest 'https://nodejs.org/dist/v10.16.3/node-v10.16.3-x64.msi' -OutFile ($Downloaddir+"\node-v10.16.3-x64.msi")
Unblock-File ($Downloaddir+"\node-v10.16.3-x64.msi")
$NodeJSInstallResult = (Start-Process "msiexec.exe" '/i node-v10.16.3-x64.msi /qn' -Wait -Passthru).ExitCode
if ($NodeJSInstallResult -eq 0) {
    Log("Install Python Success")
}
Add-SystemPaths "C:\Program Files\nodejs"

Log("##########################")
Log("# Installing Python")
Log("##########################")
Invoke-WebRequest 'https://www.python.org/ftp/python/3.7.4/python-3.7.4-amd64.exe' -OutFile ($Downloaddir+"\python-3.7.4-amd64.exe")
Unblock-File ($Downloaddir+"\python-3.7.4-amd64.exe")
$PythonInstallResult = (Start-Process ($Downloaddir+"\python-3.7.4-amd64.exe") '/quiet InstallAllUsers=1 PrependPath=1 Include_test=0' -Wait -Passthru).ExitCode
if ($PythonInstallResult -eq 0) {
    Log("Install Python Success")
}
Add-SystemPaths "C:\Program Files\Python37"
Add-SystemPaths "C:\Program Files\Python37\Scripts"

Log("##########################")
Log("# Installing Java Zulu JRE")
Log("##########################")
#Invoke-WebRequest https://github.com/Welasco/labtest/raw/master/jre-8u221-windows-x64.exe -OutFile ($Downloaddir+"\jre-8u221-windows-x64.exe")
Invoke-WebRequest http://repos.azul.com/azure-only/zulu/packages/zulu-13/13/zulu-13-azure-jre_13.27.9-13-win_x64.msi -OutFile ($Downloaddir+"\zulu-13-azure-jre_13.27.9-13-win_x64.msi")
Unblock-File ($Downloaddir+"\zulu-13-azure-jre_13.27.9-13-win_x64.msi")
$JavaInstallResult = (Start-Process ($Downloaddir+"\zulu-13-azure-jre_13.27.9-13-win_x64.msi") '/qn' -Wait -Passthru).ExitCode
if ($JavaInstallResult -eq 0) {
    Log("Install Java Zulu JRE Success")
}
Add-SystemPaths "C:\Program Files\Zulu\zulu-13-jre\bin"

Log("##########################")
Log("# Installing IIS and PHP")
Log("##########################")
Log("Installing IIS")
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI

#Creating PHP installation folder
New-Item -Path "C:\Program Files" -Name "PHP" -ItemType "directory"

Log("Downloading php and unzipping in C:\Program Files")
$php_dir="C:\Program Files\PHP"
$phpURL="https://windows.php.net/downloads/releases/php-7.3.10-nts-Win32-VC15-x86.zip"
$phpzip= ($Downloaddir+"\php-download.zip")
Invoke-WebRequest -Uri $phpURL -OutFile $phpzip
Expand-Archive -LiteralPath $phpzip -DestinationPath $php_dir
Add-SystemPaths "C:\Program Files\PHP"
#Remove-Item $phpzip

Log("Downloading and installing Visual C++ for PHP")
$vcURL="https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe"
$vc_exe=($Downloaddir+"\vc.exe")
Invoke-WebRequest -Uri $vcURL -OutFile $vc_exe
$vcInstallResult = (Start-Process $vc_exe '/s' -Wait -Passthru).ExitCode
if ($vcInstallResult -eq 0) {
    Log("Install VC Success")
}

#Downloading Rewrite 2.1 for web.config
$rewrite_module="https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$rewrite_module_msi=($Downloaddir+"\rewrite.msi")
Invoke-WebRequest -Uri $rewrite_module -OutFile $rewrite_module_msi
$rewriteInstallResult =  (Start-Process $rewrite_module_msi '/qn' -Wait -Passthru).ExitCode
if ($rewriteInstallResult -eq 0) {
    Log("Install VC Success")
}
# cd 'C:/Program Files/Microsoft/Web Platform Installer'; .\WebpiCmd.exe /Install /Products:'UrlRewrite2' /AcceptEula /OptInMU /SuppressPostFinish

#Creating web app inside IIS and add php/fastcgi handlers.
New-WebSite -Name PHPApp -Port 8088 -PhysicalPath "C:\InstallDir\apps\PHPApp"
Start-Process -FilePath "C:\Windows\System32\inetsrv\appcmd.exe" -ArgumentList "unlock config -section:system.webServer/handlers" -Wait -Passthru
Start-Process -FilePath "C:\Windows\System32\inetsrv\appcmd.exe" -ArgumentList ("set config -section:system.webServer/handlers /+`"[name='PHP-FastCGI',path='*.php',verb='GET,HEAD,POST',modules='FastCgiModule',scriptProcessor='" + $php_dir + "\php-cgi.exe',resourceType='Either',requireAccess='Script']`" /commit:apphost") -Wait -Passthru
Start-Process -FilePath "C:\Windows\System32\inetsrv\appcmd.exe" -ArgumentList ("set config -section:system.webServer/fastCgi /+`"[fullPath='" + $php_dir + "\php-cgi.exe']`" /commit:apphost") -Wait -Passthru

#Restarting IIS
iisreset

cd $Downloaddir\apps\MainApp
Copy-Item * C:\inetpub\wwwroot\ -Recurse

Log("##########################")
Log("# Preparing Code")
Log("##########################")
cd $Downloaddir
Log("Reloading System Path for current session")
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Log("Preparing NodeJS App (npm install)")
cd $Downloaddir\apps\NodeJSApp
npm install

Log("Preparing Python App (pip install)")
cd $Downloaddir\apps\PythonApp
pip install -r requirements.txt

Log("Preparing Java App")

Log("##########################")
Log("# Loading App Services")
Log("##########################")
Log("Download nssm and unblock the file")
cd $Downloaddir
Invoke-WebRequest -Uri https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip -OutFile ($Downloaddir+"\nssm-2.24-101-g897c7ad.zip")
Expand-Archive -Path ($Downloaddir+"\nssm-2.24-101-g897c7ad.zip") -DestinationPath $Downloaddir
Copy-Item ($Downloaddir+"\nssm-2.24-101-g897c7ad\win64\nssm.exe") $Downloaddir
Unblock-File ($Downloaddir+"\nssm.exe")

Log("Adding NodeJSApp Service")
.\nssm.exe install NodeJSApp 'C:\Program Files\nodejs\node.exe' C:\InstallDir\apps\NodeJSApp\bin\www
.\nssm.exe set NodeJSApp AppDirectory C:\InstallDir\apps\NodeJSApp
Start-Service NodeJSApp

Log("Adding PythonApp Service")
.\nssm.exe install PythonApp 'C:\Program Files\Python37\python.exe' C:\InstallDir\apps\PythonApp\app.py
.\nssm.exe set PythonApp AppDirectory C:\InstallDir\apps\PythonApp
Start-Service PythonApp

Log("Adding JavaApp Service")
.\nssm.exe install JavaApp 'C:\Program Files\Zulu\zulu-13-jre\bin\java.exe' -jar C:\InstallDir\apps\JavaApp\javaapp.jar
.\nssm.exe set JavaApp AppDirectory C:\InstallDir\apps\JavaApp
Start-Service JavaApp

Log("##########################")
Log("# Setting Windows Features")
Log("##########################")
Log("Disable IE ESC")
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

Disable-InternetExplorerESC

Log("Windows Firewall Allow Ping")
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
netsh advfirewall firewall add rule name="Allow NodeJS App" protocol=TCP dir=in action=allow localport=3000
netsh advfirewall firewall add rule name="Allow Python App" protocol=TCP dir=in action=allow localport=5000
netsh advfirewall firewall add rule name="Allow Java App" protocol=TCP dir=in action=allow localport=8080
netsh advfirewall firewall add rule name="Allow PHP App" protocol=TCP dir=in action=allow localport=8088
netsh advfirewall firewall add rule name="Allow Mail App" protocol=TCP dir=in action=allow localport=80