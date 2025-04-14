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

# Function to generate TOTP
function Get-TOTP {
    param (
        [string]$Secret
    )
    
    # Convert secret to bytes
    $secretBytes = [System.Convert]::FromBase64String($Secret)
    
    # Get current Unix timestamp divided by 30 (TOTP time step)
    $timestamp = [math]::Floor([decimal](Get-Date -UFormat %s) / 30)
    
    # Convert timestamp to bytes
    $timestampBytes = [System.BitConverter]::GetBytes([int64]$timestamp)
    [array]::Reverse($timestampBytes)
    
    # Calculate HMAC-SHA1
    $hmac = New-Object System.Security.Cryptography.HMACSHA1
    $hmac.Key = $secretBytes
    $hash = $hmac.ComputeHash($timestampBytes)
    
    # Get offset from last 4 bits of hash
    $offset = $hash[$hash.Length - 1] -band 0xf
    
    # Get 4 bytes starting at offset
    $binary = (($hash[$offset] -band 0x7f) -shl 24) -bor
              (($hash[$offset + 1] -band 0xff) -shl 16) -bor
              (($hash[$offset + 2] -band 0xff) -shl 8) -bor
              ($hash[$offset + 3] -band 0xff)
    
    # Get 6-digit code
    $code = $binary % 1000000
    return "{0:D6}" -f $code
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

# Get OpenConnect installation path
$openconnectPath = (Get-Command openconnect).Source
$vpncScriptPath = Join-Path (Split-Path $openconnectPath -Parent) "vpnc-script-win.js"

# Create VPN function with Windows-specific parameters
$vpn_function = @"
function global:${alias_name}_vpn {
    `$securePassword = Read-Host "Enter password" -AsSecureString
    `$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(`$securePassword))
    `$secret = Get-Content "$env:USERPROFILE\.${alias_name}_easyoc_totp_google"
    `$otp = Get-TOTP -Secret `$secret
    `$domain = Get-Content "$env:USERPROFILE\.${alias_name}_easyoc_domain"
    
    try {
        `$password + "`n" + `$otp | openconnect `
            --useragent=AnyConnect `
            --user ${vpn_username} `
            --syslog `
            --passwd-on-stdin `
            --script "$vpncScriptPath" `
            --os=win `
            --no-dtls `
            ${vpn_url}
    }
    catch {
        Write-Error "Failed to connect to VPN: `$(`$_.Exception.Message)"
        exit 1
    }
}
"@

# Add function to PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}
Add-Content -Path $profilePath -Value $vpn_function

Write-Host "Installation completed successfully!"
Write-Host "Please add your Google Authenticator secret (base32 encoded) to $totp_file"
Write-Host "Restart PowerShell and run '${alias_name}_vpn' to connect to VPN"
Write-Host "Example command: Set-Content -Path '$totp_file' -Value 'YOUR_BASE32_ENCODED_SECRET'" 