#!/usr/bin/python3
import time
import board
import adafruit_dht
import sys

if len(sys.argv) == 2 :
    pin = sys.argv[1]
    print(pin)
else:
    print('Usage: sudo ./Adafruit_DHT.py  <GPIO pin number>')
    print('Example: sudo ./Adafruit_DHT.py  4 - DHT22 connected to GPIO pin #4')
    sys.exit(1)
gpio_pin="board.D"+pin
# Initial the dht device, with data pin connected to:
# dhtDevice = adafruit_dht.DHT22(board.D4)
 
# you can pass DHT22 use_pulseio=False if you wouldn't like to use pulseio.
# This may be necessary on a Linux single board computer like the Raspberry Pi,
# but it will not work in CircuitPython.
dhtDevice = adafruit_dht.DHT22(gpio_pin, use_pulseio=False)
 
while True:
    try:
        # Print the values to the serial port
        temperature_c = dhtDevice.temperature
        humidity = dhtDevice.humidity
        print(temperature_c, humidity)
    except RuntimeError as error:
        # Errors happen fairly often, DHT's are hard to read, just keep going
        print(error.args[0])
        time.sleep(2.0)
        continue
    except Exception as error:
        dhtDevice.exit()
        raise error
    time.sleep(2.0)
