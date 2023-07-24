#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Define variables
CONFIG_DIR="/etc/wireguard"
CONFIG_FILE="$CONFIG_DIR/wg0.conf"
PRIVATE_KEY_FILE="$CONFIG_DIR/private.key"
PUBLIC_KEY_FILE="$CONFIG_DIR/public.key"
SERVER_IP="10.0.0.1"
LISTEN_PORT="51820"
VPN_SUBNET="10.0.0.0/24"

# Function to install WireGuard if not already installed
install_wireguard() {
    if ! command -v wg &> /dev/null; then
        echo "Installing WireGuard..."
        apt update
        apt install -y wireguard
    fi
}

# Function to generate WireGuard key pair for the server
generate_key_pair() {
    echo "Generating WireGuard key pair..."
    umask 077
    wg genkey | tee "$PRIVATE_KEY_FILE" | wg pubkey > "$PUBLIC_KEY_FILE"
}

# Function to create WireGuard configuration file
create_config_file() {
    echo "Creating WireGuard configuration file..."
    cat << EOF > "$CONFIG_FILE"
[Interface]
PrivateKey = $(cat "$PRIVATE_KEY_FILE")
Address = $SERVER_IP/24
ListenPort = $LISTEN_PORT
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF
}

# Function to enable IP forwarding
enable_ip_forwarding() {
    echo "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
}

# Function to set proper permissions and restrict access to configuration files
secure_config_files() {
    echo "Securing configuration files..."
    chown root:root "$CONFIG_FILE" "$PRIVATE_KEY_FILE" "$PUBLIC_KEY_FILE"
    chmod 600 "$CONFIG_FILE" "$PRIVATE_KEY_FILE" "$PUBLIC_KEY_FILE"
}

# Main script execution
install_wireguard
generate_key_pair
create_config_file
enable_ip_forwarding
secure_config_files

# Enable the WireGuard interface
systemctl enable wg-quick@wg0.service

echo "WireGuard VPN has been configured and started successfully!"
