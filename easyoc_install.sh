#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this script as root"
    exit 1
fi

# Function to validate input
validate_input() {
    if [ -z "$1" ]; then
        echo "Error: Input cannot be empty"
        exit 1
    fi
}

# Check for required commands and install if necessary
if ! command_exists openconnect; then
    echo "Installing openconnect..."
    if command_exists brew; then
        brew install openconnect
    elif command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y openconnect
    elif command_exists yum; then
        sudo yum install -y openconnect
    else
        echo "Error: Could not install openconnect. Please install it manually."
        exit 1
    fi
fi

if ! command_exists oathtool; then
    echo "Installing oathtool..."
    if command_exists brew; then
        brew install oath-toolkit
    elif command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y oathtool
    elif command_exists yum; then
        sudo yum install -y oathtool
    else
        echo "Error: Could not install oathtool. Please install it manually."
        exit 1
    fi
fi

# Get user input with validation
read -p "Enter alias for the VPN command (e.g., 'work'): " alias_name
validate_input "$alias_name"

read -p "Enter your VPN username: " vpn_username
validate_input "$vpn_username"

read -p "Enter VPN server URL: " vpn_url
validate_input "$vpn_url"

read -p "Do you use zsh? (y/n): " use_zsh
validate_input "$use_zsh"

# Check if config files already exist
totp_file="$HOME/.${alias_name}_easyoc_totp_google"
domain_file="$HOME/.${alias_name}_easyoc_domain"

if [ -f "$totp_file" ]; then
    echo "Warning: TOTP file already exists. Do you want to overwrite it? (y/n)"
    read -r overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Installation aborted"
        exit 1
    fi
fi

if [ -f "$domain_file" ]; then
    echo "Warning: Domain file already exists. Do you want to overwrite it? (y/n)"
    read -r overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Installation aborted"
        exit 1
    fi
fi

# Create necessary files with secure permissions
touch "$totp_file"
touch "$domain_file"
chmod 600 "$totp_file" "$domain_file"

# Create the VPN function
if [ "$use_zsh" = "y" ]; then
    vpn_function="function ${alias_name}_vpn() {
    read -s 'password?Enter password: '
    local otp=\$(cat ~/.${alias_name}_easyoc_totp_google | xargs oathtool --totp -b)
    local domains=\$(cat ~/.${alias_name}_easyoc_domain | tr '\n' ' ')
    echo -e \"\$password\n\$otp\" | sudo openconnect --useragent=AnyConnect --user ${vpn_username} --syslog --passwd-on-stdin --script 'vpn-slice \$domains' ${vpn_url}
}"
    # Add the function to .zshrc
    echo "$vpn_function" >> ~/.zshrc
    chmod 644 ~/.zshrc
else
    vpn_function="function ${alias_name}_vpn() {
    read -s -p 'Enter password: ' password
    echo
    local otp=\$(cat ~/.${alias_name}_easyoc_totp_google | xargs oathtool --totp -b)
    local domains=\$(cat ~/.${alias_name}_easyoc_domain | tr '\n' ' ')
    echo -e \"\$password\n\$otp\" | sudo openconnect --useragent=AnyConnect --user ${vpn_username} --syslog --passwd-on-stdin --script 'vpn-slice \$domains' ${vpn_url}
}"
    # Add the function to .bash_profile
    echo "$vpn_function" >> ~/.bash_profile
    chmod 644 ~/.bash_profile
fi

echo "Installation completed successfully!"
echo "Please add your Google Authenticator token to ~/.${alias_name}_easyoc_totp_google"
echo "Restart your terminal and run '${alias_name}_vpn' to connect to the VPN"
echo "Use command example: echo \"YOUR_TOKEN_GOOGLE_AUTH\" > '~/.${alias_name}_easyoc_totp_google'"

# Clean up variables
unset alias_name
unset vpn_username
unset vpn_url
unset vpn_function
unset use_zsh
unset totp_file
unset domain_file
unset overwrite
