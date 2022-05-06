#!/bin/bash 
#
#   
#    Copyright (C) 2019  Martin Aube
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
# Calibrate heading sensor
#
y=`date +%Y`
mo=`date +%m`
d=`date +%d`
H=`date +%H`
M=`date +%M`
S=`date +%S`
# making directory tree
if [ ! -d /var/www/html/data ]
then mkdir /var/www/html/data
fi         
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
datetime=$y"-"$mo"-"$d"_"$H"-"$M"-"$S
echo "Angle Azimuth Bx By Bz" > /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt"
for i in {-17..18}
do let angle=i*10
   let delta=angle*750/360
   /usr/local/bin/zero_pos.py
   /usr/local/bin/rotate.py $delta 1
   /bin/sleep 2   
   /usr/local/bin/heading_angle.py > /home/sand/bidon1.tmp
   read bidon azim xx yy zz bidon < /home/sand/bidon1.tmp
   echo $angle $azim $xx $yy $zz >> /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt"
   let delta=-delta
   /usr/local/bin/rotate.py $delta 1
done
cp -f /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt" /home/sand/backup/$y/$mo/$d/$datetime"_heading_calib.txt"
