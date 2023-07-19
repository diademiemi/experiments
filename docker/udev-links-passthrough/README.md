# Udev Symlinks Passthrough
This was a test for whether I could get udev created symlinks to be passed through to a container. The answer is yes, but with too many asterisks to be useful.

## The Problem
We want TTY devices to be accessible on paths that are consistent across reboots. This is so that we can use them in an application. We can't simply pass through the device node as this would not be hot-pluggable. We also can't use the device node directly as it will change across or even when the device is unplugged and plugged back in.  

## The Solution (sort of)
I created a script (`alias-sync/sync-devices.sh`) that checks the udev rules for a given device and creates a symlink to the device node in the container. It will also remove the link if the device is unplugged. This acts like a semi-udev process in the container.

## The Problem with the Solution
The big problem is that device names across the host and container are not consistent. This means that the symlink will not always point to the correct device. This is because the device name is based on the order in which the device is plugged in. I'm not sure what causes a desync between the host and container, but it seems to happen when I rapidly plug and unplug devices. Whether this is a problem in practice depends on the use case. It might be perfectly fine for some, but it didn't inspire confidence in me, so I resorted to passing through all of `/dev` to the container as solution.  

## The Problem with the Solution to the Problem with the Solution
Passing through all of `/dev` is a security risk. It means the block devices are accessible to the container, meaning any data is accessible to the container. This was not a problem in this deployment, as containerisation was chosen for ease of deployment, not security. However, it is something to be aware of.

# Conclusion
I would consider this failed, as it is not a solution I would use in practice, even passing through all of `/dev` is preferable to the script. However, it was a fun experiment and a good excuse to relearn some Rust and brush up on my shell scripting.

# Testing
I wrote a quick and dirty Rust project to monitor TTY device symlinks and return their output. This allows me to plug in some ESP32s and press the reset button to see if the output still works after plugging and unplugging devices in different orders.  

I use the `docker-compose.yml` file to build the image and run the container. The script is also ran by this file as a "container" that executes the command on the host (or else it wouldn't be able to access the devices). This is not how I would do it in practice, but this is a portable way to test it.