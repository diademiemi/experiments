use serde::{Deserialize, Serialize};
use serde_yaml::{self};
use std::io::{self, Write};
use serialport::SerialPort;

#[derive(Debug, Serialize, Deserialize)]
struct SerialDevice {
    dev: String,
    baud_rate: u32,
}

#[derive(Debug, Serialize, Deserialize)]
struct Config {
    serial_devices: Vec<SerialDevice>,
}

struct OpenDevice {
    port: Box<dyn serialport::SerialPort>,
    dev: String,
    baud_rate: u32,
}

fn read_config() -> Config {
    let file = std::fs::File::open("config.yaml").expect("Could not open file.");
    let scrape_config: Config = serde_yaml::from_reader(file).expect("Could not read values.");
    return scrape_config;
}

fn tail_serial_devices(config: Config) {

    let mut ports = vec![];

    for device in config.serial_devices {
        for _ in 0..5 {
            match serialport::new(&device.dev, device.baud_rate)
                .timeout(std::time::Duration::from_millis(1000))
                .open() {
                    Ok(p) => {
                        let open_device = OpenDevice { port: p, dev: device.dev, baud_rate: device.baud_rate };
                        ports.push(open_device);
                        break;
                    },
                    Err(ref e) if e.kind() == serialport::ErrorKind::Io(std::io::ErrorKind::NotFound) => {
                        println!("Serial port not found. Retrying in 1 second.");
                        std::thread::sleep(std::time::Duration::from_millis(1000));
                        continue
                    },
                    _ => panic!("Failed to open serial port {0}", device.dev),
                };
        }



    }

    let mut serial_buf: Vec<u8> = vec![0; 1000];

    loop {
        for device in &mut ports {
            match device.port.read(serial_buf.as_mut_slice()) {
                Ok(t) => {
                    io::stdout().write_all(&serial_buf[..t]).unwrap()
                },
                Err(ref e) if e.kind() == std::io::ErrorKind::BrokenPipe => {
                    device.port = match serialport::new(&device.dev, device.baud_rate)
                        .timeout(std::time::Duration::from_millis(10))
                        .open() {
                            Ok(p) => p,
                            Err(ref e) if e.kind() == serialport::ErrorKind::Io(std::io::ErrorKind::NotFound) => continue,
                            _ => panic!("Failed to open serial port {0}", device.dev),
                        };
                    },
                Err(ref e) if e.kind() == std::io::ErrorKind::TimedOut => (),
                Err(e) => eprintln!("{:?}", e),
            }
        }
    }

}

fn main() {

    let config = read_config();

    println!("{:?}", config.serial_devices);

    tail_serial_devices(config);

}
