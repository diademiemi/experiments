# Udev Symlinks Passthrough
This was a test for whether I could get udev created symlinks to be passed through to a container. Stretching the definition of a symlink a bit, it works!

- [Udev Symlinks Passthrough](#udev-symlinks-passthrough)
  - [The Problem](#the-problem)
  - [The Solution](#the-solution)
  - [Making the Solution work in Docker](#making-the-solution-work-in-docker)
- [Testing](#testing)
- [Conclusion](#conclusion)

## The Problem
We want TTY devices to be accessible on paths that are consistent across reboots. This is so that we can use them in an application. We can't simply pass through the device node as this would not be hot-pluggable. We also can't use the device node (`/dev/ttyUSBx`) directly as it will change across or even when the device is unplugged and plugged back in.  

## The Solution
We want to achieve this with udev rules, we can use the `KERNELS` field to create a rule for a specific physical USB port. This allows us to predict which location a device will be mounted at. This can be done quite easily on the host by creating a udev rule that looks like this:
```
ACTION=="add|change", KERNELS=="1-1.2", SYMLINK+="ttyESP32"
```
When a USB device is inserted in the `1-1.2` port, it will be given a semi-random address like `/dev/ttyUSB2`. While this address is usually consistent, it isn't guaranteed to be. Just like block devices which aren't always at the same location (Like `/dev/sda`). This is why we create a symlink to the device node. This symlink will be created at `/dev/ttyESP32` and will point to the device node, whatever that may be. This symlink will be consistent across reboots and even when the device is unplugged and plugged back in. This means we can use the symlink in our application and it will always point to the correct device.

## Making the Solution work in Docker
The application needs to run in a Docker container. We have the following criteria for this:
 - The application needs to be able to access the device at a consistent location.
 - The USB device must be hot-pluggable.
 - It must be transparent to the user, they should not have to do anything special to get it to work. 
 - It should work the same as if they were running the application on the host with the previous udev solution.

The solution I went with here is to create a script that runs on the host (which knows of the USB devices & has udev). This script is ran when a USB device is connected to the host with the following udev rule:
```
ACTION=="add|change", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", KERNELS=="1-1.2", RUN+="/usr/local/bin/docker-static-usb-nodes.sh add /dev/ttyESP32 %M %m"
ACTION=="remove", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", KERNELS=="1-1.2", RUN+="/usr/local/bin/docker-static-usb-nodes.sh remove /dev/ttyESP32 %M %m"
```

The script takes the following arguments
```
docker-static-usb-nodes.sh add <symlink> <major> <minor>
                            |   |         |       |
                            |   |         |       +-- Minor number of the device node. This is %m in the udev rule.
                            |   |         +---------- Major number of the device node. This is %M in the udev rule.
                            |   +-------------------- Symlink to create. This is the static path that the application will use.
                            +------------------------ Action to perform (add or remove). The script will create or remove the symlink.
```

The script will create a the device node in the container. It does this by using the `mknod` command, an example of this is `mknod /dev/ttyESP32 c 180 0`. This will create a device node accessible at `/dev/ttyESP32` for the USB device with the address `180 0` (Note that this address is not the same as the KERNELS field. The address is unimportant to us, udev handles this). When the device is removed, it deletes this node with a simple `rm -f`. These nodes aren't symlinks, but they do function as one. This is because the application will access the device node at `/dev/ttyESP32`, which will point to the correct device. This is the same as if we were using the symlink created by udev on the host.

For this to work the container must be privileged and have `/dev/bus/usb` forwarded to it as a volume. This is because the container still needs access to the underlying devices. This is a security risk, as it means the container can access all USB devices on the host. This is not a problem in this deployment, as containerisation was chosen for ease of deployment, not security. However, it is something to be aware of.

One downside this has is that this script only gets triggered when a device is plugged in. This means that the first time the container is started, the script will not run and the symlinks will not be created. We solve this by creating a cronjob that runs ever minute if the container is running. This cronjob will just run `udevadm trigger`, which will trigger the udev rules and run the script. This means that the symlinks will be created on the first startup after at most a minute. Not ideal, and I'm sure there are better solutions that work instantly, but this is enough for us and has low complexity.
```cron
CONTAINER_NAME=serial-devices-test

* * * * * if [ $(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME) = "true" ]; then udevadm trigger; fi
```

In the script and in the crontab, the container with the name `serial-devices-test` is used, you can override this by editing the code or setting the `CONTAINER_NAME` environment variable.

# Testing
I wrote a quick and dirty Rust project to monitor TTY device symlinks and return their output. This allows me to plug in some ESP32s and press the reset button to see if the output still works after plugging and unplugging devices in different orders.  

I use the `docker-compose.yml` file to build the image and run the container. An Ansible playbook is provided to install the script and udev rule on localhost. You'll want to edit the KERNELS for the USB devices on line 38. This is used to template the udev rule. You can find the KERNELS field by watching `dmesg` while plugging in a device, it will look like the following:
```
[18989.612594] usb 1-5.4.1.1: new full-speed USB device number 99 using xhci_hcd
[18989.884586] usb 1-5.4.1.1: Product: CP2102 USB to UART Bridge Controller
```
The KERNELS field in this case is `1-5.4.1.1`, some may be much shorter or much longer, it depends on the hardware.  

After editing the playbook, you can run this with the following command:
```bash
ansible-playbook install-requirements -K
```

It will prompt you for your sudo password, this is because it needs to install the script and udev rule on the host.  
It does not install a cronjob, you will need to run `udevadm trigger` manually after first starting the container.  

When you are done, you can run the playbook with the `cleanup` tag to remove the script and udev rule:
```bash
ansible-playbook install-requirements -K --tags cleanup
```

# Conclusion
I think this is a pretty good solution, it is simple and works well. It is also transparent to the user, they don't need to do anything special to get it to work.  
I've seen this problem get asked on forums and StackOverflow a lot, but I've never seen a solution. Every reply has always been pointing out that you can pass through the device node, but that isn't hot-pluggable. I hope this helps someone out there.  

