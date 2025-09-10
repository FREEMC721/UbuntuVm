#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
DATA_DIR="${HOME}/dark-vm-data"
DISK="${DATA_DIR}/vm.raw"
IMG="${DATA_DIR}/ubuntu.img"
SEED="${DATA_DIR}/seed.iso"
CLOUD_DIR="${DATA_DIR}/cloud-init"

mkdir -p "$DATA_DIR" "$CLOUD_DIR"

# -----------------------------
# Install dependencies if missing
# -----------------------------
if ! command -v qemu-system-x86_64 >/dev/null; then
    echo "📦 Installing QEMU + tools..."
    sudo apt-get update
    sudo apt-get install -y qemu-system-x86 qemu-utils cloud-image-utils genisoimage curl
fi

# -----------------------------
# Download Ubuntu cloud image
# -----------------------------
if [ ! -f "$IMG" ]; then
    echo "⬇️ Downloading Ubuntu 22.04 cloud image..."
    curl -L https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -o "$IMG"
fi

# -----------------------------
# Cloud-init meta-data
# -----------------------------
cat > "$CLOUD_DIR/meta-data" <<EOF
instance-id: ubuntu-vm
local-hostname: dark-vm
EOF

# -----------------------------
# Cloud-init user-data (login: dark/root)
# -----------------------------
cat > "$CLOUD_DIR/user-data" <<EOF
#cloud-config
hostname: dark-vm
users:
  - name: dark
    gecos: root
    shell: /bin/bash
    lock_passwd: false
    passwd: \$6\$abcd1234\$W6wzBuvyE.D1mBGAgQw2uvUO/honRrnAGjFhMXSk0LUbZosYtoHy1tUtYhKlALqIldOGPrYnhSrOfAknpm91i0
    sudo: ALL=(ALL) NOPASSWD:ALL
disable_root: false
ssh_pwauth: true
chpasswd:
  list: |
    root:root
  expire: false
EOF

# -----------------------------
# Create cloud-init ISO
# -----------------------------
if [ ! -f "$SEED" ]; then
    echo "💿 Creating cloud-init ISO..."
    genisoimage -output "$SEED" -volid cidata -joliet -rock \
        "$CLOUD_DIR/user-data" "$CLOUD_DIR/meta-data" >/dev/null 2>&1
fi

# -----------------------------
# Create VM disk
# -----------------------------
if [ ! -f "$DISK" ]; then
    echo "🔄 Creating VM disk..."
    qemu-img convert -f qcow2 -O raw "$IMG" "$DISK"
    qemu-img resize "$DISK" 20G
fi

# -----------------------------
# Start VM (Codespaces compatible)
# -----------------------------
echo "================================================"
echo "🚀 Starting VM in terminal (no KVM, Ctrl+A then X to quit)"
echo "👤 Login: dark / root"
echo "👑 Root:  root / root"
echo "================================================"
echo

exec qemu-system-x86_64 \
    -cpu qemu64 \
    -smp 2 \
    -m 2048 \
    -drive file="$DISK",format=raw,if=virtio \
    -drive file="$SEED",format=raw,if=virtio \
    -net nic -net user \
    -vga std \
    -nographic
