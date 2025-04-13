# EasyOC - Simple VPN Connection Script for OpenConnect

EasyOC is a simple bash script that simplifies the process of connecting to a VPN via OpenConnect with two-factor authentication (2FA) support.

## Features

- Automatic installation of required dependencies (openconnect, oathtool)
- Two-factor authentication support via Google Authenticator
- Support for both bash and zsh
- Secure configuration storage
- Simple VPN domain management

## Requirements

- Linux, macOS or WSL
- Sudo access for package installation
- Internet connection

## Installation

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

## Usage

After installation, you can connect to the VPN using the created command:
```bash
your_alias_vpn
```

## Security

- Script does not run as root user
- Configuration files have strict permissions
- Sensitive data is stored in protected files

## License

MIT License

## Author

[Your Name]

## Support

If you encounter any issues or have questions, please create an issue in the repository. 