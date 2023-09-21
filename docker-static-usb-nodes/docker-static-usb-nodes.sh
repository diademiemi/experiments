#!/bin/bash

if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME="serial-devices-test"
fi

function exec_in_container() {
    printf "Executing command in container $1: $2\n" >> /var/log/docker-static-usb-nodes.log
    # Redirect output to /var/log/docker-static-usb-nodes.log
    docker exec $1 /bin/sh -c "$2" >> /var/log/docker-static-usb-nodes.log 2>&1
    exit_code=$?
    printf "Command exit code: $exit_code\n\n" >> /var/log/docker-static-usb-nodes.log
    return $exit_code

}

if [ -z "$1" ]; then
    echo "Action not given."
    exit 11
fi


if [ -z "$2" ]; then
    echo "Device name not given."
    exit 12
fi

if [ -z "$3" ]; then
    echo "Device major not given."
    exit 13
fi

if [ -z "$4" ]; then
    echo "Device minor not given."
    exit 14
fi

command=""

if [ "$1" == "add" ]; then
    # Test if device already exists in container
    if exec_in_container "$CONTAINER_NAME" "test -e $2"; then # If not exists
        printf "Device $2 already exists in container $CONTAINER_NAME\n" >> /var/log/docker-static-usb-nodes.log
        exit 2
    fi

    command="mknod $2 c $3 $4"
fi

if [ "$1" == "remove" ]; then
    # Test if device exists in container
    if ! exec_in_container "$CONTAINER_NAME" "test -e $2"; then # If exists
        printf "Device $2 does not exist in container $CONTAINER_NAME\n"  >> /var/log/docker-static-usb-nodes.log
        exit 3
    fi
    command="rm $2"
fi

exec_in_container "$CONTAINER_NAME" "$command"

# Check if log file is over 50MB
if [ $(stat -c%s /var/log/docker-static-usb-nodes.log) -gt 52428800 ]; then
    # Truncate log file
    truncate -s 0 /var/log/docker-static-usb-nodes.log
    printf "Truncated log file\n" >> /var/log/docker-static-usb-nodes.log
fi
