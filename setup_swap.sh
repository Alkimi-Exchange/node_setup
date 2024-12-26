#!/bin/bash

# Set swap size (8GB)
SWAP_SIZE=8G
SWAP_FILE=/swapfile

# Check if swap is already active
if sudo swapon --show | grep -q "$SWAP_FILE"; then
    echo "Swap is already set up at $SWAP_FILE. Exiting..."
    exit 0
fi

# Check if any swap is active
if sudo swapon --show | grep -q "swap"; then
    echo "Swap is already active. Exiting..."
    exit 0
fi

echo "Creating a $SWAP_SIZE swap file..."

# Attempt to use fallocate
if command -v fallocate &> /dev/null; then
    echo "Using fallocate to create swap file..."
    sudo fallocate -l $SWAP_SIZE $SWAP_FILE
else
    echo "fallocate not available, using dd to create swap file..."
    sudo dd if=/dev/zero of=$SWAP_FILE bs=1M count=$((8 * 1024))
fi

# Set the correct permissions
echo "Setting permissions on swap file..."
sudo chmod 600 $SWAP_FILE

# Format the file as swap
echo "Formatting swap file..."
sudo mkswap $SWAP_FILE

# Enable the swap file
echo "Enabling swap file..."
sudo swapon $SWAP_FILE

# Make swap file permanent
echo "Updating /etc/fstab..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# Set swappiness
echo "Setting swappiness to 10..."
sudo sysctl vm.swappiness=10

# Make swappiness setting persistent
echo "Updating /etc/sysctl.conf..."
if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi

echo "Swap setup completed successfully!"
