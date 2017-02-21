#!/usr/bin/env bash

# Install script for linmuzei.
# Copyright (C) 2014 Alp Pirli

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. 

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://gnu.org/licenses/>.

pack=(jq sed curl)
for p in $pack
do
  if [ ! "$(which $p)" ]
  then
    echo "You need to install $p to use linmuzei."
    exit
  fi
done

if [ "$(id -u)" == "0" ]
then
  echo "WARNING: If you run the install script as root the cronjob will probably not work for your user."
fi
  
mkdir -p ~/Pictures/Muzei
cp ./MuzeiLogo.png ~/Pictures/Muzei

read -r -p "Install linmuzei? [Y/n] " y_or_n
case $y_or_n in
  [nN][oO]|[nN])      echo "Exiting." ; exit ;;
esac

[ $({ crontab -l; echo "0 * * * * DISPLAY=:0 linmuzei"; } | crontab -) ]

sudo bash << EOF
  cp ./linmuzei.sh /usr/bin/linmuzei
  chmod +x /usr/bin/linmuzei
  echo "linmuzei installed."
EOF
