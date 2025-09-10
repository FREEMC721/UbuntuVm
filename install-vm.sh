#!/bin/bash

if [ ! -d "UbuntuVm" ]; then
  git clone https://github.com/FREEMC721/UbuntuVm || exit 1
fi

cd UbuntuVm || exit 1

docker build -t dark-vm .

if docker ps -a --format '{{.Names}}' | grep -q "^dark-vm-container$"; then
  echo "Container already exists. Starting it..."
  docker start dark-vm-container
else
  echo "Creating and starting new container..."
  docker run --name dark-vm-container --privileged \
    -p 6080:6080 -p 2221:2222 \
    -v "$PWD/vmdata:/data" \
    -d dark-vm
fi

echo "Done. Access it via http://localhost:6080"
