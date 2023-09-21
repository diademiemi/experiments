FROM rust:1-buster as builder

WORKDIR /usr/src/serial-devices-test

RUN apt-get update && apt-get install --no-install-recommends -y \
    libudev-dev

COPY . .

RUN cargo build --release

FROM ubuntu:22.04

COPY --from=builder /usr/src/serial-devices-test/target/release/serial-devices-test /usr/local/bin/serial-devices-test

WORKDIR /config

VOLUME /config

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/local/bin/serial-devices-test"]
