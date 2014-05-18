#!/bin/bash
#####################################################################################################
# Restore_Linux_Settings V.4.0: Restore Linux Mint settings from >>Backup_Linux_Settings<< script.	#                                          	
#                                                                         							#
# Copyright (C) 2014 Bastian Noller                                       							#
# email: bastian.noller[-A.T.-]web.de                                     							#
#                                         								  							#
#                                                                   								#
#    This program is free software: you can redistribute it and/or modify							#
#    it under the terms of the GNU General Public License as published by							#
#    the Free Software Foundation, either version 3 of the License, or								#
#    (at your option) any later version.															#
#																									#
#    This program is distributed in the hope that it will be useful,								#
#    but WITHOUT ANY WARRANTY; without even the implied warranty of									#
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the									#
#    GNU General Public License for more details.													#
#																									#
#    You should have received a copy of the GNU General Public License								#
#    along with this program.  If not, see <http://www.gnu.org/licenses/> 							#
#                                                                         							#
#####################################################################################################


# Use this script to restore Linux settings from your backups generated with the >>Backup_Linux_Settings<< script.
#This script is intended for Linux Mint. Most likely it will also work for Ubuntu. Please tell the script were it can find your backups
#(folder were the *.zip files are), by editing the source variable below:
# >>> For the advanced users: Lines 123-140 in this script could be interesting for fine tuning as well.<<<
##############################################################################################################################################
##############################################################################################################################################

source="/media/Daten/Linux_Backup/" # determines the locations of the backups. This is the only variable you should edit if you are not an advanced user.

##############################################################################################################################################
##############################################################################################################################################
current_version=$(lsb_release -d | sed -n 's/Description:[\t]//p' | tr " " _)
zip_files=$(find "$source" -mindepth 1 -maxdepth 1 -type f) # make array of zip files stored in source
#echo $zip_files
temp_dir=/tmp_dir_4_restore #we have to make a temp folder, because we don't just want ot overwrite the files with unzip but keep their attributes and owners.
bold=`tput bold`
normal=`tput sgr0`
echo "Detected Linux Version:"
echo $current_version
echo "#########################################################"
echo "#########################################################"
echo "${bold}CAUTION:${normal} Please be sure to make a backup copy of your current Linux settings first before you use this script!" 
echo "You can use the complimentary backup script called: >>Backup_Linux_Settings<< to perform this task." 
echo "PLEASE BE SURE TO START SCRIPT WITH SUDO COMMAND!"
echo "#########################################################"
echo "#########################################################"
echo "Detected backups of settings in $source."
echo "Please select Distribution to import settings from:"
echo ""
restore_methods=("complete (${bold}not${normal} recommended)" "selected setting-files only" "Quit") ## array of restoring options
options=($zip_files Quit) ## adding quit as additional option
PS3="Please enter selection: "
QUIT="QUIT THIS PROGRAM"

select FILENAME in ${options[@]};
do
  case $FILENAME in
		"Quit")
            exit
            ;;
        *)
			echo ""
			echo "#########################################################"        	
			echo "You picked $FILENAME ($REPLY)"
			echo "#########################################################"
		  	echo "Now please select with which method you would like to restore your Linux settings"
			echo ""
			IFS=""
			select method in ${restore_methods[@]};
			do 
				case $method in
					"complete (${bold}not${normal} recommended)") # here we restore everything, this might make problems with incompatible files between distributions
						echo "Will now restore all of Linux old setting files (not recommended)."
						echo ""
						sleep 3
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	sleep 3
						echo "Unzipping files into that directory...."
						sleep 3
						unzip -o $FILENAME -d $temp_dir
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						apt-key add $temp_dir/Installed_Programs/Repo.keys
						cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						apt-get update
						apt-get install dselect
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring all former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/home/ /
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/ /
						echo ""
						echo "All settings of your former Linux version have been imported to current distribution."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Now please reboot or restart your X-Server and pray that we did not overwrite settings with obsolete files that are no longer supported in the old format by the new distribution."
						echo "This might be the case since you selected to restore ${bold}all${normal} of the settings."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						exit
						;;
					"selected setting-files only") # here we don't restore everything, just the most important things
						echo "Will now restore only selected setting files (the most important ones)."
						echo ""
						sleep 3
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 3
						echo "Unzipping files into that directory...."
						sleep 3
						unzip -o $FILENAME -d $temp_dir
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						apt-key add $temp_dir/Installed_Programs/Repo.keys
						cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						apt-get update
						apt-get install dselect
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring only selected former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/home/ /
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/cron.hourly/ /etc/
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/cron.daily/ /etc/
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/cron.weekly/ /etc/
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/cron.monthly/ /etc/
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/cups/ /etc/
						#cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/fonts/ /etc/ # activate if you want to restore fonts settings
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/gnome/ /etc/ # restore file associations
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/opt /etc/
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/udisks2/ /etc/
						#cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/bash.bashrc /etc/bash.bashrc #restore old bashrc if edited
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/crontab /etc/crontab
						cp -rv --no-preserve=all --preserve=timestamps $temp_dir/etc/fstab /etc/fstab # VERY IMPORTANT LINE USUALLY
						echo ""
						echo "All settings of your former Linux version have been imported to current distribution."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Now please reboot or restart your X-Server and your former Linux setting should be back to the way you like it."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						exit
						;;
					"Quit")
						#break
						exit
						;;
					*)
						echo "Selection not in list above. Please try again."
						;;
  				esac
			done
          	;;
  esac
done



fi
exit
################################################################################################################
################################################################################################################




