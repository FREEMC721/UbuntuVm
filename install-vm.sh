#!/bin/bash

# Clone the repo if not already cloned
if [ ! -d "UbuntuVm" ]; then
  echo "Cloning repository..."
  git clone https://github.com/FREEMC721/UbuntuVm || { echo "Failed to clone repo"; exit 1; }
fi

cd UbuntuVm || { echo "Failed to cd into UbuntuVm"; exit 1; }

# Build the Docker image
echo "Building Docker image..."
docker build -t dark-vm . || { echo "Failed to build Docker image"; exit 1; }

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^dark-vm-container$"; then
  echo "Container already exists. Starting interactive session..."
  docker start -ai dark-vm-container
else
  echo "Creating and starting new container interactively..."
  docker run --name dark-vm-container --privileged \
    -v "$PWD/vmdata:/data" \
    -it dark-vm /bin/bash
fi
