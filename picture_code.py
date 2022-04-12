#Code to automatically take picture from raspberry pi with the sony starvis imx462 ultra-low light camera.
#A picture is taken every 15 seconds to make sure the process finishes before taking another picture.
#The raspberry pi zeros w, being slower than a raspberry pi 3, have difficulty taking pictures so the function called 'call'
#makes sure that the picture acquisition process does not take longer than 30 seconds and reboot the raspbrry pi 5 failed attempts. 
from datetime import datetime as dt, timedelta
import os
import subprocess as sub
import time
import pause

def call(cmd,timeout):
    out = sub.run(cmd.split(), stdout=sub.PIPE, stderr=sub.PIPE, timeout=timeout)
    return out.stdout.decode(), out.stderr.decode()

def capture(shutter, gain, timeout=30, trys=5):
    for i in range(trys):
        now = dt.now()
        date_now = str(now.date())
        time_now = str(now.time())
        global fname
        fname = (date_now+'_'+time_now+'_'+f"{shutter}{gain}").replace(':','_')
        path = f'/home/pi/camera/captures/{fname[:4]}/{fname[5:7]}/{fname[8:10]}/'
        os.makedirs(path, exist_ok=True)
        cmd = (
            "libcamera-still "
            f"-o {path}{fname}.jpg "
            f"--analoggain {gain} "
            f"--shutter {shutter} "
            "--flush "
            "--denoise off "
            "--rawfull "
            "--raw "
            "--autofocus off "
            "--awbgains 1,1 "
            "--nopreview"
                )
        try:
            return call(cmd,timeout)
        except sub.TimeoutExpired:
            continue
    call("sudo reboot")

if __name__ == "__main__":
    #pause.until(dt(2022, 3, 11, 16, 40))
    print('start')
    while True:
        gains = [1, 5, 10]
        shutters = [30000, 50000, 100000]
        for gain in gains:
            for shutter in shutters:
                print (shutter, gain)
                t1 = int(time.time())
                capture(shutter,gain)
                print('picture_saved')
                t2 = int(time.time())
                if t2-t1 < 15:
                    print('sleep')
                    time.sleep(15-(t2-t1))
                else:
                    print('no sleep')
                    continue