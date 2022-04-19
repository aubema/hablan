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
i=0
delta=75  # correspond to 36 deg steps
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
while [ $i -le 750 ]
do let angle=i*360/750
   /usr/local/bin/heading_angle.py > /home/sand/bidon1.tmp
   read bidon azim bidon < /home/sand/bidon1.tmp
   if [ $i -eq 0 ]
   then echo $angle $azim > /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt"
   else
        echo $angle $azim >> /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt"
   fi
   /usr/local/bin/rotate.py $delta 1
   /bin/sleep 2
   let i=i+delta
done
/usr/local/bin/rotate.py -750 1
cp -f /var/www/html/data/$y/$mo/$d/$datetime"_heading_calib.txt" /home/sand/backup/$y/$mo/$d/$datetime"_heading_calib.txt"
