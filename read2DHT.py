#!/usr/bin/python3
import time
import board
import adafruit_dht

# Initial the dht device, with data pin connected to:
# dhtDevice = adafruit_dht.DHT22(board.D4)
 
# you can pass DHT22 use_pulseio=False if you wouldn't like to use pulseio.
# This may be necessary on a Linux single board computer like the Raspberry Pi,
# but it will not work in CircuitPython.
dhtDevice = adafruit_dht.DHT22(board.D7, use_pulseio=False)
try:
    # Print the values to the serial port
    temperature1_c = dhtDevice.temperature
    humidity1 = dhtDevice.humidity
    errorflag=0
except RuntimeError as error:
    # Errors happen fairly often, DHT's are hard to read, just keep going
    print(error.args[0])
    time.sleep(2.0)
except Exception as error:
    dhtDevice.exit()
    raise error
dhtDevice = adafruit_dht.DHT22(board.D1, use_pulseio=False)

try:
    # Print the values to the serial port
    temperature2_c = dhtDevice.temperature
    humidity2 = dhtDevice.humidity
except RuntimeError as error:
    # Errors happen fairly often, DHT's are hard to read, just keep going
    print(error.args[0])
    time.sleep(2.0)
except Exception as error:
    dhtDevice.exit()
    raise error
print(temperature1_c, temperature2_c, humidity_1, humidity_2)
