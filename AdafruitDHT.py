#!/usr/bin/python

2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
import time
import board
import adafruit_dht
import sys

if len(sys.argv) == 2 :
    pin = sys.argv[2]
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
