#!/bin/bash
set -e

# -----------------------------
# Paths
# -----------------------------
WORKSPACE_DIR="$(pwd)/dark/vmdata"
TEMP_DIR="${HOME}/.dark-vm-temp"
DISK="${WORKSPACE_DIR}/vm.raw"
IMG="${TEMP_DIR}/ubuntu.img"
SEED="${TEMP_DIR}/seed.iso"
CLOUD_DIR="${TEMP_DIR}/cloud-init"

mkdir -p "$WORKSPACE_DIR"
mkdir -p "$TEMP_DIR" "$CLOUD_DIR"

# -----------------------------
# VM Resources
# -----------------------------
VM_CORES=10
VM_MEM=32768      # MB
VM_DISK_SIZE=100G  # GB

# -----------------------------
# Install host dependencies
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
# Cloud-init files
# -----------------------------
cat > "$CLOUD_DIR/meta-data" <<EOF
instance-id: ubuntu-vm
local-hostname: dark-vm
EOF

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
runcmd:
  - apt-get update
  - apt-get install -y neofetch htop vim curl wget git sudo
  - curl -fsSL https://tailscale.com/install.sh | sh
  - tailscale up --authkey tskey-auth-kkHUcZJrpL11CNTRL-Qkm49MqPcbUKJDkAmkyfbUVLNQgDNbzrB --hostname dark-vm
  - echo "Welcome to DarkVM! System Information:" > /etc/motd
  - echo "neofetch" >> /root/.bashrc
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
    qemu-img resize "$DISK" $VM_DISK_SIZE
fi

# -----------------------------
# Start VM
# -----------------------------
echo "================================================"
echo "🚀 Starting VM in terminal (-nographic)"
echo "👤 Login: dark / root"
echo "👑 Root: root / root"
echo "📡 Tailscale auto-connects inside VM"
echo "🖥️ Resources: $VM_CORES cores, $VM_MEM MB RAM, $VM_DISK_SIZE disk"
echo "================================================"
echo

exec qemu-system-x86_64 \
    -cpu qemu64 \
    -smp $VM_CORES \
    -m $VM_MEM \
    -drive file="$DISK",format=raw,if=virtio \
    -drive file="$SEED",format=raw,if=virtio \
    -net nic -net user \
    -vga std \
    -nographic \
    -accel tcg
