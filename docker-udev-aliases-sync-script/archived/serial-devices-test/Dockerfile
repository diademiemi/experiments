FROM rust:1-buster as builder

WORKDIR /usr/src/serial-devices-test

RUN apt update && apt install -y libudev-dev

COPY ../../serial-devices-test .

RUN cargo build --release

FROM ubuntu:22.04

COPY --from=builder /usr/src/serial-devices-test/target/release/serial-devices-test /usr/local/bin/serial-devices-test

WORKDIR /config

VOLUME /config

CMD ["/usr/local/bin/serial-devices-test"]
