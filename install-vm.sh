#!/bin/bash
set -e

DATA_DIR="${HOME}/dark-vm-data"
DISK="${DATA_DIR}/vm.raw"
IMG="${DATA_DIR}/ubuntu.img"
SEED="${DATA_DIR}/seed.iso"
CLOUD_DIR="${DATA_DIR}/cloud-init"

mkdir -p "$DATA_DIR" "$CLOUD_DIR"

echo "🔎 Checking dependencies..."
if ! command -v qemu-system-x86_64 >/dev/null; then
  echo "📦 Installing QEMU + tools..."
  sudo apt-get update
  sudo apt-get install -y qemu-system-x86 qemu-utils cloud-image-utils genisoimage curl
fi

# Download Ubuntu cloud image if missing
if [ ! -f "$IMG" ]; then
    echo "⬇️ Downloading Ubuntu 22.04 cloud image..."
    curl -L https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -o "$IMG"
fi

# Write meta-data
cat > "$CLOUD_DIR/meta-data" <<EOF
instance-id: ubuntu-vm
local-hostname: dark-vm
EOF

# Write user-data with login: dark/root
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

# Create seed ISO
if [ ! -f "$SEED" ]; then
  echo "💿 Creating cloud-init ISO..."
  genisoimage -output "$SEED" -volid cidata -joliet -rock \
    "$CLOUD_DIR/user-data" "$CLOUD_DIR/meta-data" >/dev/null 2>&1
fi

# Create VM disk if missing
if [ ! -f "$DISK" ]; then
    echo "🔄 Creating VM disk..."
    qemu-img convert -f qcow2 -O raw "$IMG" "$DISK"
    qemu-img resize "$DISK" 20G
fi

echo "================================================"
echo "🚀 Starting VM (Ctrl+A then X to quit)"
echo "👤 Login: dark / root"
echo "👑 Root:  root / root"
echo "================================================"
echo

exec qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 2 \
    -m 4096 \
    -drive file="$DISK",format=raw,if=virtio \
    -drive file="$SEED",format=raw,if=virtio \
    -nographic
