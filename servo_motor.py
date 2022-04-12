GPIO.setup(31, GPIO.OUT)

p=GPIO.PWM(31, 50)

p.start(2)
cycle=2
while True:
    try:
        if ser.in_waiting > 0:
            x=ser.readline().decode('utf-8').rstrip()
            pressure = x.split(",")[-1]
            print(pressure)
            if float(pressure) <= 981.49:
                while cycle <= 6:
                    p.ChangeDutyCycle(cycle)
                    print(cycle)
                    print("done")
                    time.sleep(0.3)
                    cycle+=0.2
    except KeyboardInterrupt:
        break

p.stop()
print("interrupted")
GPIO.cleanup()