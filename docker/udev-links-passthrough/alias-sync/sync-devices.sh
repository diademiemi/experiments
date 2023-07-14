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
            
            # Extract the alias name from the line
            local alias=$(echo "$line" | awk -F'"' '{ print $6 }')
            if [[ $DEBUG -eq 1 ]]; then
                echo "Found alias: $alias"
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
            
            # Get the linked device from the alias
            local device=$(readlink "$DEV_ROOT/$alias")
            if [[ $DEBUG -eq 1 ]]; then
                echo "Linked device for alias $alias: $device"
            fi
            
            # Add the device alias to the container
            add_alias "$alias" "$device"
        fi
    done < "$UDEV_RULES_FILE"
    
    if [[ $DEBUG -eq 1 ]]; then
        echo "Device alias synchronization completed."
    fi
}

# Synchronize device aliases
sync_device_aliases
