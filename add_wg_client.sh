#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Install WireGuard if not already installed
if ! command -v wg &> /dev/null; then
    echo "Installing WireGuard..."
    apt update
    apt install -y wireguard
fi

# Generate WireGuard key pair for the client
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Get server's public IP address
SERVER_PUBLIC_IP=$(curl -s ifconfig.me)

# Configure WireGuard server
SERVER_CONFIG_FILE="/etc/wireguard/wg0.conf"

# Add client peer to the server configuration file
cat << EOF >> "$SERVER_CONFIG_FILE"
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF

# Reload the WireGuard interface to apply the changes
wg-quick down wg0
wg-quick up wg0

# Retrieve SERVER_PUBLIC_KEY
SERVER_PRIVATE_KEY=$(sudo awk -F'PrivateKey = ' '/^PrivateKey = /{print $2}' /etc/wireguard/wg0.conf)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# Create the client configuration file
CLIENT_CONFIG_FILE="client-wg0.conf"
cat << EOF > "$CLIENT_CONFIG_FILE"
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = $SERVER_PUBLIC_IP:51820
PersistentKeepalive = 30
EOF

# Replace <SERVER_PUBLIC_KEY> with the server's public key.

echo "WireGuard server has been updated and client configuration file has been generated."
echo "Client configuration saved to: $CLIENT_CONFIG_FILE"
