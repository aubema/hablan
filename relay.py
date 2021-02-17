#!/usr/bin/python
# usage relay.py gpio_pin state
# possible states 1 = on 2 = off
import RPi.GPIO as GPIO
import sys
GPIO.setmode(GPIO.BCM) # GPIO Numbers instead of board numbers
RELAY_GPIO = int(sys.argv[1])
STATE = int(sys.argv[2])
if STATE==1:
    mode="GPIO.HIGH"
else:
    mode="GPIO.LOW"
GPIO.setup(RELAY_GPIO, GPIO.OUT) # GPIO Assign mode
GPIO.output(RELAIS_1_GPIO, mode) # out
