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
# ==================================
# main
# activate gps option 0=off 1=on
serial8mm="00000000000000003282741003386996"
gpsf=1
gpsport="ttyACM0"
nobs=9999  		# number of images to acquire; if 9999 then infinity
#
# main loop
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
read bidon bidon bidon port1 bidon < bidon.tmp
head -4 camera-list.tmp | tail -1 > bidon.tmp
read bidon bidon bidon port2 bidon < bidon.tmp

echo $port1 $port2

# identifier le port de la 8mm grace au serial number
gphoto2 --port $port1 --summary | grep Serial > bidon.tmp
read bidon bidon serial bidon < bidon.tmp
if [ $serial == $serial8mm ]
then port8mm=$port1
     port50mm=$port1
else port8mm=$port2
     port50mm=$port1
fi


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
   # lecture de la temperature et de l humidite
   AdafruitDHT.py 22 4 > bidon.tmp
   /usr/bin/tail -1 bidon.tmp | sed 's/=/ /g' | sed 's/*//g' | sed 's/%//g'> /root/bidon1.tmp
   read bidon Temp bidon Humidity bidon < /root/bidon1.tmp
   if [ -z "${Temp}" ]
     then let Temp=9999
          let Humidity=9999
   fi 
   echo "=========================="
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
   nomfich50=$datetime"_50mm.arw"
   nomfich8=$datetime"_8mm.arw"   

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
   echo $time $lat $lon $alt $Temp $Humidity $nomfich50 $nomfich8 >> /var/www/html/data/$y/$mo/$d/$nomfich.log
   echo $time $lat $lon $alt $Temp $Humidity $nomfich50 $nomfich8 >> /home/sand/backup/$y/$mo/$d/$nomfich.log
   # acquisition de l'image 50mm
   echo "Taking 50mm shot"
   gphoto2 --port $port50mm --capture-image-and-download --filename $nomfich50 &
   # acquisition de l'image 8mm
   /bin/sleep 0.25
   echo "Taking 8mm shot"
   gphoto2 --port $port8mm --capture-image-and-download --filename $nomfich8 &
   /bin/sleep 8
   # backup images
   cp -f $nomfich50 /var/www/html/data/$y/$mo/$d/$nomfich50
   mv -f $nomfich50 /home/sand/backup/$y/$mo/$d/$nomfich50
   cp -f $nomfich8 /var/www/html/data/$y/$mo/$d/$nomfich8
   mv -f $nomfich8 /home/sand/backup/$y/$mo/$d/$nomfich8

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
