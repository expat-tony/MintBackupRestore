#!/bin/bash
#############################################################################
# Backup_Linux_Settings V.3.0: Makes a zip file of you Linux Mint settings	#
#                                                                         	#
# Copyright (C) 2014 Bastian Noller                                       	#
# email: bastian.noller[-A.T.-]web.de                                     	#
#                                         								  	#
#                                                                         	#
#    This program is free software: you can redistribute it and/or modify	#
#    it under the terms of the GNU General Public License as published by	#
#    the Free Software Foundation, either version 3 of the License, or		#
#    (at your option) any later version.									#
#																			#
#    This program is distributed in the hope that it will be useful,		#
#    but WITHOUT ANY WARRANTY; without even the implied warranty of			#
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the			#
#    GNU General Public License for more details.							#
#																			#
#    You should have received a copy of the GNU General Public License		#
#    along with this program.  If not, see <http://www.gnu.org/licenses/> 	#
#                                                                         	#
#############################################################################


# Use this script to backup your current Linux settings (You can later on restore them with the >>Restore_Linux_Settings<< script).
#This script is intended for Linux Mint. Most likely it will also work for Ubuntu. Please tell the script were to store your backups
#(backup *.zip files will be stored there), by editing the destination variable below:
##############################################################################################################################################
##############################################################################################################################################

destination="/media/Daten/Linux_Backup/" 	# determines the destination folder were the backup will be stored. This is the only variable you should edit if you are not a advanced user.
											# Please don't make the mistake to backup into the same partition you will install the new Linux version later on.
##############################################################################################################################################
##############################################################################################################################################
# fetch the Linux version you are about to back up:
version=$(lsb_release -d | sed -n 's/Description:[\t]//p' | tr " " _)
Date="_"`date +"%Y%m%d"`
echo "Detected Linux Version:"
echo $version
sleep 1
echo "PLEASE BE SURE TO START SCRIPT WITH SUDO COMMAND!"
sleep 1
echo "Backing up home folder of current Linux distribution"
sleep 1
mkdir -p $destination
zip -r -y -u "$destination$version$Date" /home/
echo "Backed up your home folder of Linux. This can become important when installing a new release of Linux Mint (restore personal settings)"
sleep 1
echo "Now backing up your etc-settings (all of them (including files owned by root)...that's why we are now encrypting)"
sleep 1
zip -r -y -u -e "$destination$version$Date" /etc/
echo "Backed up your etc folder of Linux. This can become important when installing a new release of Linux Mint (restore some further program settings)"
sleep 1
echo "Making a list of all of the programs you have installed with package manager"
sleep 1
mkdir -p /Installed_Programs # creating the temporary folder for storing software lists.
dpkg --list | grep -v -e '-dev' -e 'ii  lib' >/Installed_Programs/packages.list
dpkg --get-selections > /Installed_Programs/Package.txt
echo "Making a list of all of the programs you have installed from source or binaries"
sleep 1
ls -1 /opt >/Installed_Programs/binary_packages.txt
ls -1 /usr/local/bin >/Installed_Programs/source_packages.txt
cp -R /etc/apt/sources.list* /Installed_Programs/
echo "Getting your Repro Key (public key)"
sleep 1
apt-key exportall > /Installed_Programs/Repo.keys
echo "Adding new files to zip"
sleep 1
zip -r -y -u "$destination$version$Date" /Installed_Programs/
rm -R /Installed_Programs # deleting the temporary folder for storing software lists.
echo "Backup script has finished."
echo "If there were no errors, you can now find a zip-file in the folder $destination that includes all your backed up information."
echo "Have a nice day." 
read -p "Press any key to continue... " -n1 -s

################################################################################################################
################################################################################################################
#echo "backing up the >>Daten drive<< to the >>Backup drive<<"
#rsync -auv --log-file=/home/user/$(date +%Y%m%d)_rsync.log --progress /media/Daten/ /media/Backup
#echo "Backup script has finished. Have a nice day."
#read -p "Press any key to continue... " -n1 -s


