#!/bin/sh

exec "$@" &

wait $!

exit $?