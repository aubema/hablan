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
gpioTCam=15
gpioTHub=14
TlimCam=5   # minimum temperature in camera assembly
TlimHub=5   # minimum temperature in the hub

nobs=9999  		# number of images to acquire; if 9999 then infinity
serialnadir="00000000000000003282741003379044"
#
#
# wait for the gps startup
echo "Waiting 15 seconds for the gps & camera startup"
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
#
# trouver les ports sur lesquels les cameras sont connectes
echo "Looking for cameras ports"
gphoto2 --auto-detect > camera-list.tmp
camconnected=`grep -c "" camera-list.tmp`
if [ $camconnected -ne "4" ]
then echo "Not enough cameras attached" $camconnected
     echo "Please check cables"
#     exit 2
fi
head -3 camera-list.tmp | tail -1 > bidon.tmp
read bidon bidon bidon port1 bidon < bidon.tmp
head -4 camera-list.tmp | tail -1 > bidon.tmp
read bidon bidon bidon port2 bidon < bidon.tmp

echo $port1 $port2

# identifier le port de la nadir grace au serial number
gphoto2 --port $port1 --summary | grep Serial > bidon.tmp
read bidon bidon serial bidon < bidon.tmp
if [ $serial == $serialnadir ]
then portnadir=$port1
     port60deg=$port2
else portnadir=$port2
     port60deg=$port1
fi
# set iso to 6400 for both cameras
gphoto2 --port $portnadir --set-config iso=20
gphoto2 --port $port60deg --set-config iso=20
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
   # reading temperatures in cam assembly and hub
   # and start heater if required
   # camera assembly sensor connected to gpio1 and hub sensor in gpio7
   python3 /usr/local/bin/read2DHT.py > bidon.tmp
   read stateT THub HHub TCam HCam bidon < /root/bidon.tmp
   # error detection
   if [ $stateT != "OK" ]
   then let Thub=9999
        let Hhub=9999
        let TCam=9999
        let HCam=9999
   fi
   if [ $THub -lt $TlimHub ]
   then /usr/local/bin/relay.py $gpioTHub 1
   else /usr/local/bin/relay.py $gpioTHub 0
   fi
   if [ $TCam -lt $TlimCam ]
   then /usr/local/bin/relay.py $gpioTCam 1
   else /usr/local/bin/relay.py $gpioTCam 0
   fi   
   echo "=========================="
   echo "Start image acquisition #" $count
   if [  $nobs != 9999 ] 
   then let i=i+1 #   never ending loop
   fi

   # loop over angles (5 values)
   targetazim=" -144 -72 0 72 144 "
   for a in $targetazim
   do n=0
     y=`date +%Y`
     mo=`date +%m`
     d=`date +%d`
     H=`date +%H`
     M=`date +%M`
     S=`date +%S`
     nomfich=$y"-"$mo"-"$d
     time=$y"-"$mo"-"$d" "$H":"$M":"$S  

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
     # writing into log file
     echo $time $lat $lon $alt $THub $HHub $TCam $HCam $nomfich60deg $nomfichnadir >> /var/www/html/data/$y/$mo/$d/$nomfich.log
     echo $time $lat $lon $alt $THub $HHub $TCam $HCam $nomfich60deg $nomfichnadir >> /home/sand/backup/$y/$mo/$d/$nomfich.log
     echo "try to go to " $a
      # goto zero position
      /usr/local/bin/zero_pos.py
      /usr/local/bin/heading_angle.py > bidon1.tmp
      read bidon azim0 bidon < bidon1.tmp
      echo "azim0 " $azim0
      let 'angle=(a-azim0)*750/360'
      echo "angle " $angle 
      # goto target azimuth - rotate the camera assembly
      /usr/local/bin/rotate.py $angle 1
   
      
     
     # acquiring images at nominal shutterspeed 1/100 s
     y=`date +%Y`
     mo=`date +%m`
     d=`date +%d`
     H=`date +%H`
     M=`date +%M`
     S=`date +%S`
     datetime=$y"-"$mo"-"$d"_"$H"-"$M"-"$S
     tint=35 # 1/100th of a second
     tinteg="_t100"
     nomfich60deg=$datetime"_60deg_"$a$tinteg".arw"
     nomfichnadir=$datetime"_nadir_"$a$tinteg".arw" 
     # acquisition de l'image 60deg  
     echo "Taking 60deg shot"
     gphoto2 --port $port60deg --set-config shutterspeed=$tint
     gphoto2 --port $port60deg --capture-image-and-download --filename $nomfich60deg
     # acquisition de l'image nadir
     /bin/sleep 0.25
     echo "Taking nadir shot"
     gphoto2 --port $portnadir --set-config shutterspeed=$tint
     gphoto2 --port $portnadir --capture-image-and-download --filename $nomfichnadir
     # backup images
     cp -f $nomfich60deg /var/www/html/data/$y/$mo/$d/$nomfich60deg
     mv -f $nomfich60deg /home/sand/backup/$y/$mo/$d/$nomfich60deg
     cp -f $nomfichnadir /var/www/html/data/$y/$mo/$d/$nomfichnadir
     mv -f $nomfichnadir /home/sand/backup/$y/$mo/$d/$nomfichnadir
     #
     #
     #
     #
     echo "try to go to " $a
      # goto zero position
      /usr/local/bin/zero_pos.py
      /usr/local/bin/heading_angle.py > bidon1.tmp
      read bidon azim0 bidon < bidon1.tmp
      echo "azim0 " $azim0
      let 'angle=(a-azim0)*750/360'
      echo "angle " $angle 
      # goto target azimuth - rotate the camera assembly
      /usr/local/bin/rotate.py $angle 1     
     # acquiring images at higher shutterspeed 1/400 s for intense sources
     y=`date +%Y`
     mo=`date +%m`
     d=`date +%d`
     H=`date +%H`
     M=`date +%M`
     S=`date +%S`
     datetime=$y"-"$mo"-"$d"_"$H"-"$M"-"$S
     tint=41 # 1/100th of a second
     tinteg="_t400"
     nomfich60deg=$datetime"_60deg_"$a$tinteg".arw"
     nomfichnadir=$datetime"_nadir_"$a$tinteg".arw" 
     # acquisition de l'image 60deg  
     echo "Taking 60deg shot"
     gphoto2 --port $port60deg --set-config shutterspeed=$tint
     gphoto2 --port $port60deg --capture-image-and-download --filename $nomfich60deg
     # acquisition de l'image nadir
     /bin/sleep 0.25
     echo "Taking nadir shot"
     gphoto2 --port $portnadir --set-config shutterspeed=$tint
     gphoto2 --port $portnadir --capture-image-and-download --filename $nomfichnadir
#     /bin/sleep 1
     # backup images
     cp -f $nomfich60deg /var/www/html/data/$y/$mo/$d/$nomfich60deg
     mv -f $nomfich60deg /home/sand/backup/$y/$mo/$d/$nomfich60deg
     cp -f $nomfichnadir /var/www/html/data/$y/$mo/$d/$nomfichnadir
     mv -f $nomfichnadir /home/sand/backup/$y/$mo/$d/$nomfichnadir
     
     
     # Choice: 0 30
     # Choice: 1 25
     # Choice: 2 20
     # Choice: 3 15
     # Choice: 4 13
     # Choice: 5 10
     # Choice: 6 8
     # Choice: 7 6
     # Choice: 8 5
     # Choice: 9 4
     # Choice: 10 32/10
     # Choice: 11 25/10
     # Choice: 12 2
     # Choice: 13 16/10
     # Choice: 14 13/10
     # Choice: 15 1
     # Choice: 16 8/10
     # Choice: 17 6/10
     # Choice: 18 5/10
     # Choice: 19 4/10
     # Choice: 20 1/3
     # Choice: 21 1/4
     # Choice: 22 1/5
     # Choice: 23 1/6
     # Choice: 24 1/8
     # Choice: 25 1/10
     # Choice: 26 1/13
     # Choice: 27 1/15
     # Choice: 28 1/20
     # Choice: 29 1/25
     # Choice: 30 1/30
     # Choice: 31 1/40
     # Choice: 32 1/50
     # Choice: 33 1/60
     # Choice: 34 1/80
     # Choice: 35 1/100
     # Choice: 36 1/125
     # Choice: 37 1/160
     # Choice: 38 1/200
     # Choice: 39 1/250
     # Choice: 40 1/320
     # Choice: 41 1/400
     # Choice: 42 1/500
     # Choice: 43 1/640
     # Choice: 44 1/800
     # Choice: 45 1/1000
     # Choice: 46 1/1250
     # Choice: 47 1/1600
     # Choice: 48 1/2000
     # Choice: 49 1/2500
     # Choice: 50 1/3200
     # Choice: 51 1/4000
     # Choice: 52 Bulb
     


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
