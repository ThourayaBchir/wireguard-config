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

# Generate WireGuard key pair for the server
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# Define VPN subnet and IP addresses
VPN_SUBNET="10.0.0.0/24"
SERVER_IP="10.0.0.1"

# Create WireGuard configuration file
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_IP/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Start the WireGuard interface
# wg-quick up wg0
systemctl enable wg-quick@wg0.service

echo "WireGuard VPN has been configured and started successfully!"
