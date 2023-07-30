#!/bin/bash

export DEBUG="${DEBUG:-0}"

export ROOTFS="${ROOTFS:-/}"
export DEV_ROOT="${DEV_ROOT:-${ROOTFS}dev}"

export CONTAINER_NAME="${CONTAINER_NAME:-serial-devices-test}"
export UDEV_RULES_FILE="${UDEV_RULES_FILE:-${ROOTFS}etc/udev/rules.d/99-docker-test.rules}"

function exec_in_container() {
    docker exec "$CONTAINER_NAME" "$@"
}

function remove_alias() {
    local alias=$1
    if [[ $DEBUG -eq 1 ]]; then
        echo "Removing alias: $alias"
    fi
    exec_in_container rm "$DEV_ROOT/$alias"
}

function add_alias() {
    local alias=$1
    local device=$2
    if [[ $DEBUG -eq 1 ]]; then
        echo "Adding alias: $alias -> $device"
    fi
    exec_in_container ln -sf "$device" "$DEV_ROOT/$alias"
}

function find_device_directory() {
    local kernels=$1
    local device_directory=""
    local device_name=""
    
    # Iterate over each kernel value
    IFS=', ' read -ra kernel_array <<< "$kernels"
    for kernel in "${kernel_array[@]}"; do
        # Find the corresponding device directory in /sys/devices
        device_directory=$(find "/sys/devices" -name "$kernel" | head -n 1)
        if [[ -n "$device_directory" ]]; then
            # Traverse further to find the directory named ttyUSB#
            device_name=$(find "$device_directory" -name "ttyUSB*" -type d -printf "%f\n" | head -n 1)
            if [[ -n "$device_name" ]]; then
                break
            fi
        fi
    done
    
    echo "$device_name"
}

function sync_device_aliases() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "Synchronizing device aliases..."
    fi
    
    # Read the udev rules file and look for device aliases
    while IFS= read -r line; do
        # Check if the line contains the SYMLINK directive
        if [[ $line == *SYMLINK* ]]; then
            if [[ $DEBUG -eq 1 ]]; then
                echo "Processing udev rule: $line"
            fi
            
            # Extract the alias name and kernels from the line
            local alias=$(echo "$line" | awk -F'"' '{ print $6 }')
            local kernels=$(echo "$line" | awk -F'"' '{ print $4 }')
            if [[ $DEBUG -eq 1 ]]; then
                echo "Found alias: $alias"
                echo "Kernels: $kernels"
            fi
            
            # Check if the device alias exists in $DEV_ROOT on the host
            if [[ ! -L "$DEV_ROOT/$alias" ]]; then
                if [[ $DEBUG -eq 1 ]]; then
                    echo "Alias $alias doesn't exist on the host. Removing from the container."
                fi
                
                # Remove the device alias from the container
                remove_alias "$alias"
                continue
            fi
            
            # Find the device directory based on the kernels
            local device_name=$(find_device_directory "$kernels")
            if [[ -z "$device_name" ]]; then
                if [[ $DEBUG -eq 1 ]]; then
                    echo "Failed to find the device directory for kernels: $kernels"
                fi
                continue
            fi
            
            # Create the symlink using the device name
            add_alias "$alias" "$DEV_ROOT/$device_name"
        fi
    done < "$UDEV_RULES_FILE"
    
    if [[ $DEBUG -eq 1 ]]; then
        echo "Device alias synchronization completed."
    fi
}

# Synchronize device aliases
sync_device_aliases
