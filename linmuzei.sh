#!/usr/bin/env bash

# linmuzei is a Muzei port for the GNU/Linux operating
# system. linmuzei is a fork of Muzei-Bash by the
# Feminist Software Foundation. You can see the original code at
# <http://github.com/Feminist-Software-Foundation/Muzei-Bash>
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

######Initial stuff######
muzeiDir=~/Pictures/Muzei
mkdir -p $muzeiDir/Wallpaper
cd $muzeiDir

######Needed packages part 1 and OS control######
case "$OSTYPE" in
  linux* | *BSD* | darwin*) echo "OS is compatible." ;;
  *) echo "Get a proper OS, kid." && exit ;;
esac

pack=(jq sed curl)
for p in $pack
do
  if ! [ "$(which $p)" ]
  then
    echo "You need $p to use this."
    exit
  fi
done

######Checking for updates######
if ! [ -f ./muzeich.json ]
then
  curl -o muzeich.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
else
  curl -o muzeich2.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
  if [ "$(cmp muzeich.json muzeich2.json)" ]
  then
    mv muzeich2.json muzeich.json
  else
    rm muzeich2.json
    echo "No wallpaper update. Exiting."
    exit
  fi
fi

######Deleting old .xinitrc line for feh/hsetroot/nitrogen if it exists######
if [ -f ~/.xinitrc ]
then
  echo "Deleting old .xinitrc line..."
  if [ "$(cat ~/.xinitrc | grep '^hsetroot -cover')" ]
  then
    sed -i "/^hsetroot -cover/d" ~/.xinitrc
  elif [ "$(cat ~/.xinitrc | grep '^sh ~/.fehbg')" ]
  then
    sed -i "/^sh ~\/.fehbg/d" ~/.xinitrc
  elif [ "$(cat ~/.xinitrc | grep '^nitrogen --restore')" ]
  then
    sed -i "/^nitrogen --restore/d" ~/.xinitrc
  fi
fi

######Parse the Muzei JSON######
imageUri=`jq '.imageUri' $muzeiDir/muzeich.json | sed s/\"//g`
imageFile=`basename $imageUri`
title=`jq '.title' $muzeiDir/muzeich.json | sed s/\"//g`
byline=`jq '.byline' $muzeiDir/muzeich.json | sed s/\"//g`

######Clean up old wallpapers######
cd Wallpaper
if [ "$(ls)" ]
then
  echo "Cleaning up old files..."
  rm *
fi

######Get the latest wallpaper######
if [ -f $imageFile ]
then
  echo "File $imageFile exists."
else
  echo "File $imageFile does not exist, downloading..."
  curl -O $imageUri
fi

######Functions for autostarting feh, hsetroot and nitrogen######
function feh_xinitSet(){
  if ! [ -f ~/.xinitrc ] || ! [ "$(cat ~/.xinitrc | grep ^exec)" ]
  then
    echo "sh ~/.fehbg &" >> ~/.xinitrc
  else
    sed -i "s#^exec #sh ~/.fehbg \&\nexec #" ~/.xinitrc
  fi
}
function hsetroot_xinitSet(){
  if ! [ -f ~/.xinitrc ] || ! [ "$(cat ~/.xinitrc | grep ^exec)" ]
  then
    echo "hsetroot -cover $muzeiDir/Wallpaper/$imageFile &" >> ~/.xinitrc
  else
    sed -i "s#^exec #hsetroot -cover $muzeiDir/Wallpaper/$imageFile \&\nexec #" ~/.xinitrc
  fi
}
function nitrogen_xinitSet(){
  if ! [ -f ~/.xinitrc ] || ! [ "$(cat ~/.xinitrc | grep ^exec)" ]
  then
    echo "nitrogen --restore &" >> ~/.xinitrc
  else
    sed -i "s#^exec #nitrogen --restore \&\nexec #" ~/.xinitrc
  fi
}

######Set the wallpaper######
function setWallpaperLinux(){
	if [ "$(pidof gnome-settings-daemon)" ] || [ "$(which gsettings)" ]
  then
    echo "Gnome-settings-daemons detected, setting wallpaper with gsettings..."
    gsettings set org.gnome.desktop.background picture-uri file://$muzeiDir/Wallpaper/$imageFile
  elif [ "$(pidof cinnamon-settings-daemon)" ]
  then
     echo "Cinnamon-settings-daemons detected, setting wallpaper with gsettings..."
     gsettings set org.cinnamon.desktop.background picture-uri file://$muzeiDir/Wallpaper/$imageFile
  else
    if [ -f ~/.xinitrc ]
    then
      if [ "$(which feh)" ]
      then
        echo "Gnome-settings-daemons not running, setting wallpaper with feh..."
        feh $imageFile
        feh_xinitSet
      elif [ "$(which hsetroot)" ]
      then
        echo "Gnome-settings-daemons not running, setting wallpaper with hsetroot..."
        hsetroot -cover $imageFile
        hsetroot_xinitSet
      elif [ "$(which nitrogen)" ]
      then
        echo "Gnome-settings-daemons not running, setting wallpaper with nitrogen..."
        nitrogen $imageFile
        nitrogen_xinitSet
      else
        echo "You need to have either feh, hsetroot or nitrogen, bruhbruh."
        exit
      fi
    else
      echo "You should have a ~/.xinitrc file."
      exit
    fi
  fi
}
function setWallpaperOSX(){
  osascript -- - "$muzeiDir/WallPaper/$imageFile" <<'EOD'
    on run(argv)
      set theFile to item 1 of argv
      tell application "System Events"
        set theDesktops to a reference to every desktop
        repeat with aDesktop in theDesktops
          set the picture of aDesktop to theFile
        end repeat
      end tell
      return "Set OSX desktop(s) to " & theFile
   end
EOD
}
case "$OSTYPE" in
  linux* | *BSD*) setWallpaperLinux ;;
  darwin*)        setWallpaperOSX ;;
esac

######Send a notification / Needed packages part 2######
cd $muzeiDir
if [ -f MuzeiLogo.png ];
then
  echo "Logo already exists."
else
  echo "Logo doesn't exist, downloading..."
  curl -O "https://raw.github.com/aepirli/Muzei-Bash/master/MuzeiLogo.png"
fi

case "$OSTYPE" in
  linux* | *BSD*)
    if ! [ "$(which notify-send)" ]
    then
      echo "Please install a notification server if you want to see a notification."
    else
      notify-send "New wallpaper: '$title'" "$byline" -i $muzeiDir/MuzeiLogo.png
    fi
    ;;
  darwin*)
    if ! [ "$(which terminal-notifier)" ]
    then
      echo "Please install terminal-notifier for a better experience."
    else
      terminal-notifier -appIcon $muzeiDir/MuzeiLogo.png -title "Muzei-Bash" -message "New wallpaper: '$title'" "$byline"
    fi
    ;;
esac
