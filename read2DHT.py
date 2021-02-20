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
temperature1_c = dhtDevice.temperature
dhtDevice = adafruit_dht.DHT22(board.D1, use_pulseio=False)
temperature2_c = dhtDevice.temperature
print("OK", temperature1_c, temperature2_c2)
