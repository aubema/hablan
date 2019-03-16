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
/bin/sleep 20
# reset the gps
gpsctl -D 5 -x "\xB5\x62\x06\x04\x04\x00\xFF\x87\x00\x00\x94\xF5" /dev/$gpsport
# set the gps to airborne < 1g mode
gpsctl -D 5 -x "\xB5\x62\x06\x24\x24\x00\xFF\xFF\x06\x03\x00\x00\x00\x00\x10\x27\x00\x00\x05\x00\xFA\x00\xFA\x00\x64\x00\x2C\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x16\xDC" /dev/$gpsport
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
   nomfich50=$datetime_50mm.raw  # CHANGER .raw par la bonne extension
   nomfich8=$datetime_8mm.raw    # CHANGER .raw par la bonne extension
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
   gphoto2 --capture-image-and-download --filename %Y-%m-%d-%H-%M-%S(50mm).arw
   # rename image 50mm
   mv NOMINCONNU $nomfich50

   # acquisition de l'image 8mm
   gphoto2 --capture-image-and-download --filename %Y-%m-%d-%H-%M-%S(8mm).arw
   # rename image 8mm
   mv NOMINCONNU $nomfich8

   # backup images
   cp -f $nomfich50 /var/www/html/data/$y/$mo/$nomfich50
   mv -f $nomfich50 /mnt/QQPART/$nomfich50
   cp -f $nomfich8 /var/www/html/data/$y/$mo/$nomfich8
   mv -f $nomfich8 /mnt/QQPART/$nomfich8

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
