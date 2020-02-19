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
#    reading 10 gps transactions
#
#
rm -f /root/*.tmp


     bash -c '/usr/bin/gpspipe -w -n 10 | sed -e "s/,/\n/g" | grep lat | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e"s/lat//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read lat < /home/sand/coords.tmp
     bash -c '/usr/bin/gpspipe -w -n 10 | sed -e "s/,/\n/g" | grep lon | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e "s/lo//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read lon < /home/sand/coords.tmp
     bash -c '/usr/bin/gpspipe -w -n 10 | sed -e "s/,/\n/g" | grep alt | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e "s/alt//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read alt < /home/sand/coords.tmp
     echo $lat $lon $alt
     # /bin/echo "GPS is connected, reading lat lon data. Longitude:" $lon
     if [ -z "${lon}" ]
     then let lon=0
          let lat=0
          let alt=0
     fi 
     /bin/echo "GPS gives Latitude:" $lat ", Longitude:" $lon "and Altitude:" $alt
}
#
# ==================================
# main
# activate gps option 0=off 1=on
gpsf=1
gpsport="ttyACM0"
nobs=9999   # number of images to acquire; if 9999 then infinity
count=1
#
# main loop
#
# wait for the gps startup
echo "Waiting 15 seconds for the gps & camera startup"
/bin/sleep 15
gphoto2 --auto-detect
# reset the gps
killall gpsd
echo "Reset the gps"
gpsctl -D 5 -x "\xB5\x62\x06\x04\x04\x00\xFF\x87\x00\x00\x94\xF5" /dev/$gpsport
# set the gps to airborne < 1g mode
echo "Set gps in airborne mode"
gpsctl -D 5 -x "\xB5\x62\x06\x24\x24\x00\xFF\xFF\x06\x03\x00\x00\x00\x00\x10\x27\x00\x00\x05\x00\xFA\x00\xFA\x00\x64\x00\x2C\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x16\xDC" /dev/$gpsport
echo "Start gpsd service"
service gpsd start
#
# trouver les ports sur lesquels les cameras sont connectes
echo "Looking for camera port"
gphoto2 --auto-detect > camera-list.tmp
camconnected=`grep -c "" camera-list.tmp`
# "3" = une caméra connectée, "4" = deux caméras connectées
if [ $camconnected -ne "3" ]
then echo "No camera attached" $camconnected
     echo "Please check cables"
     exit 2
fi
head -3 camera-list.tmp | tail -1 > bidon.tmp
read bidon bidon bidon port1 bidon < bidon.tmp

echo $port1

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

   echo "======================================="
   echo "Start image acquisition #" $count
   if [  $nobs != 9999 ] 
   then let i=i+1 #   never ending loop
   fi
   n=0
   y=`date +%Y`
   mo=`date +%m`
   d=`date +%d`
   H=`date +%H`
   M=`date +%M`
   S=`date +%S`
   nomfich=$y"-"$mo"-"$d
   time=$y"-"$mo"-"$d" "$H":"$M":"$S
   datetime=$y"-"$mo"-"$d"_"$H"-"$M"-"$S
   datetime1=$y"-"$mo"-"$d
   nomfich=$datetime"_8mm.arw"

   if [ ! -d /var/www/html/data/$y ]
   then mkdir /var/www/html/data/$y
   fi
   if [ ! -d /var/www/html/data/$y/$mo ]
   then /bin/mkdir /var/www/html/data/$y/$mo
   fi
   if [ ! -d /var/www/html/data/$y/$mo/$d ]
   then /bin/mkdir /var/www/html/data/$y/$mo/$d
   fi
   if [ ! -d /home/sand/Pictures/$datetime1]
   then /bin/mkdir /home/sand/Pictures/$datetime1
   fi
   # writing into log file
   echo $time $lat $lon $alt $nomfich >> /var/www/html/data/$y/$mo/$d/$nomfich.log
   /bin/sleep 0.25
   echo "Taking shot"
   gphoto2 --port $port1 --capture-image-and-download --filename $nomfich &
   /bin/sleep 8
   mv -f $nomfich /home/sand/Pictures
   let count+=1

   time2=`date +%s`
   let idle=20-$time2+$time1  # one measurement every 20 sec
   echo $idle $time1 $time2
   if [ $idle -lt 0 ]
   then let idle=0
   fi
   echo "Wait " $idle "s before next acquisition."
   /bin/sleep $idle
done
echo "End of drone.bash"
exit 0
