#!/bin/bash
set -e

# -----------------------------
# Update & install VPS tools
# -----------------------------
echo "📦 Updating system and installing VPS tools..."
sudo apt-get update
sudo apt-get install -y neofetch htop vim curl wget git sudo

# -----------------------------
# Clean MOTD and auto-run neofetch
# -----------------------------
echo "🖥️ Setting up VPS look..."
echo "Welcome to DarkVM! System Information:" | sudo tee /etc/motd
grep -qxF "neofetch" ~/.bashrc || echo "neofetch" >> ~/.bashrc

# -----------------------------
# Install Tailscale
# -----------------------------
echo "📡 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey tskey-auth-kkHUcZJrpL11CNTRL-Qkm49MqPcbUKJDkAmkyfbUVLNQgDNbzrB --hostname dark-vm

# -----------------------------
# Summary
# -----------------------------
echo "================================================"
echo "✅ VPS-like Ubuntu environment setup complete!"
echo "👤 Login: your Codespace user"
echo "🖥️ VPS tools installed: neofetch, htop, vim, curl, wget, git"
echo "📡 Tailscale is running; check your IP with: tailscale ip -4"
echo "================================================"
