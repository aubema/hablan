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
     /usr/bin/gpspipe -w -n 10 > /root/coords.tmp &
     sleep 1
     killall -s SIGINT gpspipe 
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
# ==================================
# main
# activate gps option 0=off 1=on
gpsf=1
gpsport="ttyACM0"
nobs=9999  		# number of images to acquire; if 9999 then infinity
#
# main loop
#
# wait for the gps startup
echo "Waiting 10 seconds for the gps startup"
/bin/sleep 10
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
echo "Looking for cameras ports"
gphoto2 --auto-detect > camera-list.tmp
camconnected=`grep -c "" camera-list.tmp`
if [ $camconnected -ne "4" ]
then echo "Not enough cameras attached" $camconnected
     echo "Please check cables"
     exit 2
fi
head -3 camera-list.tmp | tail -1 > bidon.tmp
read bidon port1 bidon < bidon.tmp
head -4 camera-list.tmp | tail -1 > bidon.tmp
read bidon port2 bidon < bidon.tmp

echo $port1 $port2

# identifier le port de la 8mm
if [ gphoto2 --port $port1 --list-folders | grep fisheye ]
then port8mm=$port2
     port50mm=$port1
else port8mm=$port1
     port50mm=$port2
fi


i=0
while [ $i -lt $nobs ]
do time1=`date +%s` # initial time
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
   n=0
   nomfich=`date -u +"%Y-%m-%d"`
   nomfich=$nomfich".txt"
   time=`date +%Y-%m-%d" "%H:%M:%S`
   datetime=`date +%Y-%m-%d-%H-%M-%S`
   nomfich50=$datetime_50mm.arw  # CHANGER .raw par la bonne extension
   nomfich8=$datetime_8mm.arw    # CHANGER .raw par la bonne extension
   y=`date +%Y`
   mo=`date +%m`
   d=`date +%d`
   if [ ! -d /var/www/html/data/$y ]
   then mkdir /var/www/html/data/$y
   fi
   if [ ! -d /var/www/html/data/$y/$mo ]
   then /bin/mkdir /var/www/html/data/$y/$mo
   fi
   # writing into log file
   echo $time $lat $lon $alt $nomfich50 $nomfich8 >> /var/www/html/data/$y/$mo/$nomfich.log
   # acquisition de l'image 50mm
   echo "Taking 50mm shot"
   gphoto2 --port $port50mm --capture-image-and-download --filename $nomfich50
   # rename image 50mm

exit 1

   mv NOMINCONNU $nomfich50

   # acquisition de l'image 8mm
   echo "Taking 8mm shot"
   gphoto2 --port $port8mm --capture-image-and-download --filename $nomfich8
   # rename image 8mm
   


   mv NOMINCONNU $nomfich8

   # backup images
   cp -f $nomfich50 /var/www/html/data/$y/$mo/$nomfich50
   mv -f $nomfich50 /home/sand/backup/$nomfich50
   cp -f $nomfich8 /var/www/html/data/$y/$mo/$nomfich8
   mv -f $nomfich8 /home/sand/backup/$nomfich8

   time2=`date +%s`
   let idle=20-time2+time1  # one measurement every 20 sec
   echo $idle $time1 $time2
   if [ $idle -lt 0 ]
   then let idle=0
   fi
   echo "Wait " $idle "s before next acquisition."
   /bin/sleep $idle
done
echo "End of hablan.bash"
exit 0
