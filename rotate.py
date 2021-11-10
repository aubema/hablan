#!/usr/bin/python
# move the camera assembly
# 
# usage: rotate.py steps slow_level
# steps = number of steps (200 for a complete rotation motor only)
#         with the 60-16 teeth gears and strap (factor of 3.75)
#          so that 200x3.75 = 750 steps for 360deg
# slow_level 1=fastest n=max_speed/n
import RPi.GPIO as GPIO
import time
import sys
import math

# Variables
reverse=0
steps = int(sys.argv[1])
if steps<0:
   steps=-1*steps
   reverse=1
steps=steps-1
delaym = float(sys.argv[2]) * 0.0075

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

# Function for step sequence
def setStep(w1, w2, w3, w4):
  time.sleep(delay)
  GPIO.output(coil_A_1_pin, w1)
  GPIO.output(coil_A_2_pin, w2)
  GPIO.output(coil_B_1_pin, w3)
  GPIO.output(coil_B_2_pin, w4)

# loop through step sequence based on number of steps
j=0
if reverse==0:
    for i in range(0, steps):
        delay=10*delaym*(1-(math.sin(math.pi*i/steps))**2)+delaym
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
#    setStep(0,0,0,0)
else:
    for i in range(0, steps):
        delay=10*delaym*(1-(math.sin(math.pi*i/steps))**2)+delaym    
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
#    setStep(0,0,0,0)
