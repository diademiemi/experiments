# Archived
Parts of this experiment that didn't work out, but might be useful for future reference.

# Udev Symlinks Passthrough
This was a test for whether I could get udev created symlinks to be passed through to a container. The answer is yes, but with too many asterisks to be useful.

- [Archived](#archived)
- [Udev Symlinks Passthrough](#udev-symlinks-passthrough)
  - [The Problem](#the-problem)
  - [The Solution (sort of)](#the-solution-sort-of)
  - [The Problem with the Solution](#the-problem-with-the-solution)
  - [The Problem with the Solution to the Problem with the Solution](#the-problem-with-the-solution-to-the-problem-with-the-solution)
  - [The Solution to the Problem with the Solution to the Problem with the Solution](#the-solution-to-the-problem-with-the-solution-to-the-problem-with-the-solution)
- [Testing](#testing)
- [Conclusion](#conclusion)
  - [Alternative Solution](#alternative-solution)
- [WARNING!](#warning)


## The Problem
We want TTY devices to be accessible on paths that are consistent across reboots. This is so that we can use them in an application. We can't simply pass through the device node as this would not be hot-pluggable. We also can't use the device node directly as it will change across or even when the device is unplugged and plugged back in.  

## The Solution (sort of)
I created a script (`alias-sync/sync-devices.sh`) that checks the udev rules for a given device and creates a symlink to the device node in the container. It will also remove the link if the device is unplugged. This acts like a semi-udev process in the container.

## The Problem with the Solution
The big problem is that device names across the host and container are not consistent. This means that the symlink will not always point to the correct device. This is because the device name is based on the order in which the device is plugged in. I'm not sure what causes a desync between the host and container, but it seems to happen when I rapidly plug and unplug devices. Whether this is a problem in practice depends on the use case. It might be perfectly fine for some, but it didn't inspire confidence in me, so I resorted to passing through all of `/dev` to the container as solution.  

## The Problem with the Solution to the Problem with the Solution
Passing through all of `/dev` is a security risk. It means the block devices are accessible to the container, meaning any data is accessible to the container. This was not a problem in this deployment, as containerisation was chosen for ease of deployment, not security. However, it is something to be aware of.


## The Solution to the Problem with the Solution to the Problem with the Solution
I made a new script which creates new device nodes based on udev rules set on the host. This seems to be much more reliable, check out the [upper directory README](../README.md) for more info.

# Testing
I wrote a quick and dirty Rust project to monitor TTY device symlinks and return their output. This allows me to plug in some ESP32s and press the reset button to see if the output still works after plugging and unplugging devices in different orders.  

I use the `docker-compose.yml` file to build the image and run the container. The script is also ran by this file as a "container" that executes the command on the host (or else it wouldn't be able to access the devices). This is not how I would do it in practice, but this is a portable way to test it.

# Conclusion
I would consider this failed, as it is not a solution I would use in practice, even passing through all of `/dev` is preferable to the script. However, it was a fun experiment and a good excuse to relearn some Rust and brush up on my shell scripting.

## Alternative Solution
I have attempted to run udev in the container too, as this seemed like it would be simpler. However I ran into issues with hot-plugging, it doesn't seem like the container gets all the information. My host was also not particularly happy with running two udev processes, even unrelated USB devices like my headset would stop working on the host. 
This might work fine in some setups, it also didn't have the problem of the first startup not working. However, I decided to go with the solution mentioned in the upper directory as it seemed much more reliable.

# WARNING!
This solution is incredibly dodgy! Don't use this in production, or anywhere! This is just for some inspiration for a better solution.