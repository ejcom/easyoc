# EasyOC - Simple VPN Connection Script for OpenConnect

EasyOC is a simple script that simplifies the process of connecting to a VPN via OpenConnect with two-factor authentication (2FA) support. Available for both Unix-like systems (Linux, macOS) and Windows.

## Features

- Automatic installation of required dependencies (openconnect, oathtool)
- Two-factor authentication support via Google Authenticator
- Support for bash, zsh, and PowerShell
- Secure configuration storage
- Simple VPN domain management
- Cross-platform support (Linux, macOS, Windows)

## Requirements

### Unix-like systems (Linux, macOS, WSL)
- Sudo access for package installation
- Internet connection

### Windows
- PowerShell 5.1 or later
- Administrator privileges
- Internet connection

## Installation

### Unix-like systems (Linux, macOS, WSL)

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/easyoc/main/easyoc_install.sh
```

2. Make the script executable:
```bash
chmod +x easyoc_install.sh
```

3. Run the installation:
```bash
./easyoc_install.sh
```

4. Follow the installer instructions

### Windows

1. Download the script:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/easyoc/main/easyoc_install.ps1" -OutFile "easyoc_install.ps1"
```

2. Run PowerShell as Administrator and execute:
```powershell
.\easyoc_install.ps1
```

3. Follow the installer instructions

## Usage

### Unix-like systems
After installation, you can connect to the VPN using the created command:
```bash
your_alias_vpn
```

### Windows
After installation, you can connect to the VPN using the created command in PowerShell:
```powershell
your_alias_vpn
```

## Security

- Script does not run as root user (Unix) / requires admin privileges (Windows)
- Configuration files have strict permissions
- Sensitive data is stored in protected files
- Password input is handled securely

## License

MIT License

## Author

EJCOM

## Support

If you encounter any issues or have questions, please create an issue in the repository. 