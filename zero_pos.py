#!/usr/bin/python
# usage: zero_filter.py
# find the clear filter and stop there
#
import RPi.GPIO as GPIO
import time
import sys
import math

# Variables steps is half a turn
half = 375
delay = 0.0075
full=2*half
destination=0
delaym=0.007

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Enable pins for IN1-4 to control step sequence
coil_A_1_pin = 16
coil_A_2_pin = 12
coil_B_1_pin = 20
coil_B_2_pin = 21

# Set pin states
GPIO.setup(coil_A_1_pin, GPIO.OUT)
GPIO.setup(coil_A_2_pin, GPIO.OUT)
GPIO.setup(coil_B_1_pin, GPIO.OUT)
GPIO.setup(coil_B_2_pin, GPIO.OUT)

# set the sensor pin
sensor_gpio=25
GPIO.setup(sensor_gpio, GPIO.IN)

# Function for step sequence
def setStep(w1, w2, w3, w4):
  time.sleep(delay)
  GPIO.output(coil_A_1_pin, w1)
  GPIO.output(coil_A_2_pin, w2)
  GPIO.output(coil_B_1_pin, w3)
  GPIO.output(coil_B_2_pin, w4)

# loop through step sequence based on number of steps 
# move forward half turn until sensor activated
j=0
for i in range(0, half):
    delay=(3*half/375)*delaym*(1-math.sin(math.pi*i/half))+delaym
    # stop when encoder found
    code=GPIO.input(sensor_gpio)
    if GPIO.input(sensor_gpio)==0:
        destination=1
        break
        j=j+1
        if j==1:
            setStep(1,0,0,1)
        if j==2:
            setStep(0,1,0,1)
        if j==3:
            setStep(0,1,1,0)
        if j==4:
            setStep(1,0,1,0)
            j=0

# move reverse direction complete turn until sensor activated  
time.sleep(0.5)   		
if destination==0:
    j=0
    for i in range(0, full):
        delay=(3*full/375)*delaym*(1-math.sin(math.pi*i/full))+delaym
        # stop when encoder found
        if GPIO.input(sensor_gpio)==0:
            destination=1
            break
        j=j+1
        if j==1:
            setStep(1,0,1,0)
        if j==2:
            setStep(0,1,1,0)
        if j==3:
            setStep(0,1,0,1)
        if j==4:
            setStep(1,0,0,1)
            j=0
# setStep(0,0,0,0)
