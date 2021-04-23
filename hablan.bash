#!/bin/bash 
#
#   
#    Copyright (C) 2019  Martin Aube Mikael Labrecque Vincent 
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Contact: martin.aube@cegepsherbrooke.qc.ca
#
# =============================
# 
# global positioning system
globalpos () {
#
#    reading 5 gps transactions
#
#
     /usr/bin/gpspipe -w -n 5 > /root/coords.tmp
     /usr/bin/tail -2 /root/coords.tmp | sed 's/,/\n/g' | sed 's/"//g' | sed 's/:/ /g'> /root/bidon.tmp
     grep lat /root/bidon.tmp > /root/bidon1.tmp
     read bidon lat bidon1 < /root/bidon1.tmp
     grep lon /root/bidon.tmp > /root/bidon1.tmp
     read bidon lon bidon1 < /root/bidon1.tmp
     grep alt /root/bidon.tmp > /root/bidon1.tmp
     read bidon alt bidon1 < /root/bidon1.tmp
     # /bin/echo "GPS is connected, reading lat lon data. Longitude:" $lon
     if [ -z "${lon}" ]
     then let lon=0
          let lat=0
          let alt=0
     fi 
     /bin/echo "GPS gives Latitude:" $lat ", Longitude:" $lon "and Altitude:" $alt
}
#
#
#
#
# ===========================================================================
# ===========================================================================
#
#
#
#
# main
# activate gps option 0=off 1=on
gpsf=1
gpsport="ttyACM0"
gpioTCam=14
gpioTHub=15
TlimCam=25   # minimum temperature in camera assembly
TlimHub=25   # minimum temperature in the hub
# number of images to acquire; if 9999 then infinity
nobs=9999
serialnadir="00000000000000003282741003379044"  # nadir view camera serial number
targetshutter=" 35 41 "
# Choices: 0 30; 1 25; 2 20; 3 15; 4 13; 5 10; 6 8; 7 6; 8 5; 9 4; 10 32/10; 11 25/10; 12 2; 13 16/10
# 14 13/10; 15 1; 16 8/10; 17 6/10; 18 5/10; 19 4/10; 20 1/3; 21 1/4; 22 1/5; 23 1/6; 24 1/8; 25 1/10
# 26 1/13; 27 1/15; 28 1/20; 29 1/25; 30 1/30; 31 1/40; 32 1/50; 33 1/60; 34 1/80; 35 1/100; 36 1/125
# 37 1/160; 38 1/200; 39 1/250; 40 1/320; 41 1/400; 42 1/500; 43 1/640; 44 1/800; 45 1/1000; 46 1/1250
# 47 1/1600; 48 1/2000; 49 1/2500; 50 1/3200; 51 1/4000; 52 Bulb
targetazim=" -144 -72 0 72 144 "
#
#
# wait for the gps startup
echo "Waiting 15 seconds for the gps & cameras startup"
/bin/sleep 15
gphoto2 --auto-detect
# reset the gps
killall -9 gpsd
# set the gps to airborne < 1g mode
echo "Set gps in airborne mode"
# config string obtained from u-blox ucenter app on windows message window, UBX, CFG, NAV5
gpsctl -D 5 -x "\xB5\x62\x06\x24\x24\x00\xFF\xFF\x06\x03\x00\x00\x00\x00\x10\x27\x00\x00\x05\x00\xFA\x00\xFA\x00\x64\x00\x2C\x01\x00\x3C\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x52\xE8" /dev/$gpsport
# gpsd will automatically restart after a few seconds
/bin/sleep 10
# find ports to the cameras
echo "Looking for cameras ports"
gphoto2 --auto-detect > camera-list.tmp
camconnected=`grep -c "" camera-list.tmp`
if [ $camconnected -ne "4" ]
then echo "Not enough cameras attached" $camconnected
     echo "Please check cables"
     exit 2
fi
head -3 camera-list.tmp | tail -1 > /home/sand/bidon.tmp
read bidon bidon bidon port1 bidon < /home/sand/bidon.tmp
head -4 camera-list.tmp | tail -1 > /home/sand/bidon.tmp
read bidon bidon bidon port2 bidon < /home/sand/bidon.tmp
# find the port of the nadir view camera
gphoto2 --port $port1 --summary | grep Serial > /home/sand/bidon.tmp
read bidon bidon serial bidon < /home/sand/bidon.tmp
if [ $serial == $serialnadir ]
then portnadir=$port1
     port60deg=$port2
else portnadir=$port2
     port60deg=$port1
fi
# set iso to 6400 for both cameras
gphoto2 --port $portnadir --set-config iso=20
gphoto2 --port $port60deg --set-config iso=20
gphoto2 --port $portnadir --set-config imagequality=3
gphoto2 --port $port60deg --set-config imagequality=3
gphoto2 --port $portnadir --set-config aspectratio=0
gphoto2 --port $port60deg --set-config aspectratio=0
gphoto2 --port $portnadir --set-config capturemode=0
gphoto2 --port $port60deg --set-config capturemode=0
gphoto2 --port $portnadir --set-config flashmode=0
gphoto2 --port $port60deg --set-config flashmode=0
gphoto2 --port $portnadir --set-config exposurecompensation=0
gphoto2 --port $port60deg --set-config exposurecompensation=0
gphoto2 --port $portnadir --set-config whitebalance=1
gphoto2 --port $port60deg --set-config whitebalance=1
#
# main loop
#
i=0
while [ $i -lt $nobs ]
do time1=`date +%s` # initial time
   rm -f capt*.arw
   #
   #  searching for gps
   #
   if [ $gpsf -eq 1 ] 
   then echo "GPS mode activated"
        if [ `ls /dev | grep $gpsport`  ] 
        then echo "GPS look present."
             globalpos
        fi
   else  echo "GPS mode off"
   fi
   echo "=========================="
   echo "Start image acquisition #" $count
   if [  $nobs != 9999 ] 
   then let i=i+1 #   never ending loop
   fi
   # loop over angles in degrees (5 values to fill half of a sphere)
   for a in $targetazim
   do for tint in $targetshutter
      do # reading temperatures in cam assembly and hub
         # and start heater if required
         # camera assembly sensor connected to gpio1 and hub sensor in gpio7
         python3 /usr/local/bin/read2DHT.py | sed 's/\./ /g' > /home/sand/bidon.tmp
         read stateT THub bidon TCam bidon < /home/sand/bidon.tmp
         # error detection
         if [ $stateT != "OK" ]
         then let THub=9999
              let TCam=9999
         fi
         echo "THub:" $THub "Tmin:" $TlimHub
         echo "TCam:" $TCam "Tmin:" $TlimCam
         if [ $THub -lt $TlimHub ]
         then echo "Hub heating on"
              /usr/local/bin/relay.py $gpioTHub 0
         else echo "Hub heating off"
              /usr/local/bin/relay.py $gpioTHub 1
         fi
         if [ $TCam -lt $TlimCam ]
         then echo "Cam heating on"
              /usr/local/bin/relay.py $gpioTCam 0
         else echo "Cam heating off"
              /usr/local/bin/relay.py $gpioTCam 1
         fi 
         echo "Move to " $a
         # goto zero position
         /usr/local/bin/zero_pos.py
         /usr/local/bin/heading_angle.py > /home/sand/bidon1.tmp
         read bidon azim0 bidon < /home/sand/bidon1.tmp
         let 'angle=(a-azim0)*750/360'
         # goto target azimuth - rotate the camera assembly
         /usr/local/bin/rotate.py $angle 1
         if [ $tint == 35 ]
         then tinteg="_t100"
         elif [ $tint == 41 ]
         then tinteg="_t400"
         fi
         # set cameras shutterspeed
         gphoto2 --port $port60deg --set-config shutterspeed=$tint
         gphoto2 --port $portnadir --set-config shutterspeed=$tint
         y=`date +%Y`
         mo=`date +%m`
         d=`date +%d`
         H=`date +%H`
         M=`date +%M`
         S=`date +%S`
         nomfich=$y"-"$mo"-"$d
         time=$y" "$mo" "$d" "$H" "$M" "$S
         datetime=$y"-"$mo"-"$d"_"$H"-"$M"-"$S
         # making directory tree
         if [ ! -d /var/www/html/data/$y ]
         then mkdir /var/www/html/data/$y
         fi
         if [ ! -d /var/www/html/data/$y/$mo ]
         then /bin/mkdir /var/www/html/data/$y/$mo
         fi
         if [ ! -d /var/www/html/data/$y/$mo/$d ]
         then /bin/mkdir /var/www/html/data/$y/$mo/$d
         fi
         if [ ! -d /home/sand/backup/$y ]
         then mkdir /home/sand/backup/$y
         fi
         if [ ! -d /home/sand/backup/$y/$mo ]
         then /bin/mkdir /home/sand/backup/$y/$mo
         fi
         if [ ! -d /home/sand/backup/$y/$mo/$d ]
         then /bin/mkdir /home/sand/backup/$y/$mo/$d
         fi
         # setting file names
         nomfich60deg=$datetime"_60deg_"$a$tinteg".arw"
         nomfichnadir=$datetime"_nadir_"$a$tinteg".arw"
         # writing into log file
         echo $time $lat $lon $alt $THub $TCam $nomfich60deg $nomfichnadir >> /var/www/html/data/$y/$mo/$d/$nomfich.log
         echo $time $lat $lon $alt $THub $TCam $nomfich60deg $nomfichnadir >> /home/sand/backup/$y/$mo/$d/$nomfich.log
         # acquisition de l'image 60deg  
     echo "Taking 60deg shot"
         gphoto2 --port $port60deg --capture-image-and-download --filename $nomfich60deg &
         # acquisition de l'image nadir
     echo "Taking nadir shot" 
         gphoto2 --port $portnadir --capture-image-and-download --filename $nomfichnadir &
         # waiting for the images to be saved
         /bin/sleep 1.0 
         let angle=-angle
         /usr/local/bin/rotate.py $angle 1
         /bin/sleep 8.0         
         # backup images
         cp -f $nomfich60deg /var/www/html/data/$y/$mo/$d/$nomfich60deg
         cp -f $nomfich60deg /home/sand/backup/$y/$mo/$d/$nomfich60deg
         cp -f $nomfichnadir /var/www/html/data/$y/$mo/$d/$nomfichnadir
         cp -f $nomfichnadir /home/sand/backup/$y/$mo/$d/$nomfichnadir
         rm -f $nomfich60deg
         rm -f $nomfichnadir
      done   
   done
   time2=`date +%s`
   let idle=20-$time2+$time1  # one measurement every 20 sec
   echo $idle $time1 $time2
   if [ $idle -lt 0 ]
   then let idle=0
   fi
   echo "Wait " $idle "s before next acquisition."
   /bin/sleep $idle
done
echo "End of hablan.bash"
exit 0
