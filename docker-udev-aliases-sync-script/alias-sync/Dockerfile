FROM ubuntu:22.04

ENTRYPOINT ["chroot", "/host", "/bin/bash", "-c", "while true; do /usr/local/bin/sync-devices; sleep 1; done"]
