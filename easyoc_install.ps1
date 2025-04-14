# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
    Write-Warning "Please run this script as administrator"
    exit
}

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if(Get-Command $command){ return $true }
    } Catch {
        return $false
    } Finally {
        $ErrorActionPreference=$oldPreference
    }
}

# Check and install Chocolatey
if (-not (Test-CommandExists choco)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install required packages
if (-not (Test-CommandExists openconnect)) {
    Write-Host "Installing OpenConnect..."
    choco install openconnect -y
}

if (-not (Test-CommandExists oathtool)) {
    Write-Host "Installing OATH Toolkit..."
    choco install oath-toolkit -y
}

# Get user input
$alias_name = Read-Host "Enter alias for VPN command (e.g., 'work')"
if ([string]::IsNullOrEmpty($alias_name)) {
    Write-Error "Error: Alias cannot be empty"
    exit 1
}

$vpn_username = Read-Host "Enter VPN username"
if ([string]::IsNullOrEmpty($vpn_username)) {
    Write-Error "Error: Username cannot be empty"
    exit 1
}

$vpn_url = Read-Host "Enter VPN server URL"
if ([string]::IsNullOrEmpty($vpn_url)) {
    Write-Error "Error: Server URL cannot be empty"
    exit 1
}

# Check for existing files
$totp_file = "$env:USERPROFILE\.${alias_name}_easyoc_totp_google"
$domain_file = "$env:USERPROFILE\.${alias_name}_easyoc_domain"

if (Test-Path $totp_file) {
    $overwrite = Read-Host "Warning: TOTP file already exists. Overwrite? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Installation aborted"
        exit 1
    }
}

if (Test-Path $domain_file) {
    $overwrite = Read-Host "Warning: Domain file already exists. Overwrite? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Installation aborted"
        exit 1
    }
}

# Create files
New-Item -Path $totp_file -ItemType File -Force | Out-Null
New-Item -Path $domain_file -ItemType File -Force | Out-Null

# Create VPN function
$vpn_function = @"
function global:${alias_name}_vpn {
    `$securePassword = Read-Host "Enter password" -AsSecureString
    `$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(`$securePassword))
    `$otp = Get-Content "$env:USERPROFILE\.${alias_name}_easyoc_totp_google" | oathtool --totp -b
    `$domain = Get-Content "$env:USERPROFILE\.${alias_name}_easyoc_domain"
    
    `$password + "`n" + `$otp | openconnect --useragent=AnyConnect --user ${vpn_username} --syslog --passwd-on-stdin --script "vpn-slice `$domain" ${vpn_url}
}
"@

# Add function to PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}
Add-Content -Path $profilePath -Value $vpn_function

Write-Host "Installation completed successfully!"
Write-Host "Please add your Google Authenticator token to $totp_file"
Write-Host "Restart PowerShell and run '${alias_name}_vpn' to connect to VPN"
Write-Host "Example command: Set-Content -Path '$totp_file' -Value 'YOUR_GOOGLE_AUTH_TOKEN'" 