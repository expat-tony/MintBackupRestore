#!/bin/bash
#########################################################################################################
# Restore_Linux_Settings V.23beta: Restore Linux Mint settings from >>Backup_Linux_Settings<< script.	#                                          	
#                                                                         								#
# Copyright (C) 2014 Bastian Noller                                       								#
# email: bastian.noller[-A.T.-]web.de                                     								#
#                                         								  								#
#                                                                   									#
#    This program is free software: you can redistribute it and/or modify								#
#    it under the terms of the GNU General Public License as published by								#
#    the Free Software Foundation, either version 3 of the License, or									#
#    (at your option) any later version.																#
#																										#
#    This program is distributed in the hope that it will be useful,									#
#    but WITHOUT ANY WARRANTY; without even the implied warranty of										#
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the										#
#    GNU General Public License for more details.														#
#																										#
#    You should have received a copy of the GNU General Public License									#
#    along with this program.  If not, see <http://www.gnu.org/licenses/> 								#
#                                                                         								#
#########################################################################################################


# Use this script to restore Linux settings from your backups generated with the >>Backup_Linux_Settings<< script.
#This script is intended for Linux Mint. Most likely it will also work for Ubuntu. Please tell the script were it can find your backups
#(folder were the *tar.7zip files are), by editing the source variable below:
# >>> For the advanced users: Lines 345-374 in this script could be interesting for fine tuning as well.<<<
##############################################################################################################################################
##############################################################################################################################################

source="/media/Daten/Linux_Backup/" # determines the locations of the backups. This is the only variable you should edit if you are not an advanced user.

##############################################################################################################################################
##############################################################################################################################################
## make sure you are sudo:
if [[ $EUID -ne 0 ]]; then
	echo "Please run this script with sudo privileges (enter password below:)"
	exec sudo bash "$0" "$@" #run script as sudo or su
else
	echo ""
fi

##check if all packages are available to run this script:
echo "Checking if necessary packages are available on your PC to run this script:"

dpkg -l apt > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED == '0' ]; then
		echo "+ apt is installed on your system (can use apt to restore packages) --> OK"
else
		echo ""
 		echo "The script has detected that >>apt<< is NOT installed on your system."
  		echo "However, apt is needed for this script to work."
		echo "Apt can not be automatically installed using this script. Please use your package manager (e.g., Synaptic) to install apt."
  		read -p "Press any key to exit, goodbye." -n1 -s
		exit
fi

dpkg -l p7zip > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED == '0' ]; then
		echo "+ 7zip compression is installed on your system (7za command available) --> OK"
else
		echo ""
 		echo "The script has detected that 7za is NOT installed on your system."
  		echo "However, 7za compression is needed for this script to work."
		echo ""
		echo "Press any key to install the required package (recommended) or close the terminal to aboard."
  		read -p "If the automatic installation fails, please install >>p7zip<< package by hand using your package manager. " -n1 -s
  		apt-get install p7zip
fi

dpkg -l tar > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED == '0' ]; then
		echo "+ tar container format is installed on your system (tar command available) --> OK"
else
		echo ""
 		echo "The script has detected that >>tar<< is NOT installed on your system."
  		echo "However, the tar container format is needed for this script to work."
		echo ""
		echo "Press any key to install the required package (recommended) or close the terminal to aboard."
  		read -p "If the automatic installation fails, please install >>tar<< package by hand using your package manager. " -n1 -s
  		apt-get install tar
fi

dpkg -l e2fsprogs > /dev/null 2>&1
INSTALLED=$?
if [ $INSTALLED == '0' ]; then
		echo "+ blkid is installed on your system (can fetch UUIDs) --> OK"
else
		echo ""
 		echo "The script has detected that blkid is NOT installed on your system."
  		echo "However, blkid is needed for this script to work."
		echo ""
		echo "Press any key to install the required package (recommended) or close the terminal to aboard."
  		read -p "If the automatic installation fails, please install >>e2fsprogs<< package by hand using your package manager. " -n1 -s
  		apt-get install e2fsprogs
fi

dpkg -l xdg-utils > /dev/null 2>&1 #xdg-utils contains the xdg-open command, which opens your standard editor.
INSTALLED=$?
if [ $INSTALLED == '0' ]; then
		echo "+ A text editor is installed on your system (can open fstab) --> OK"
else
		echo ""
 		echo "The script has detected that xdg-open is NOT installed on your system."
  		echo "However, xdg-open is needed for this script to work (open standard text editor)."
		echo ""
		echo "Press any key to install the required package (recommended) or close the terminal to aboard."
  		read -p "If the automatic installation fails, please install >>xdg-utils<< package by hand using your package manager. " -n1 -s
  		apt-get install xdg-utils
fi
echo ""


## fetch linux version and start interactive restore process
current_version=$(lsb_release -d | sed -n 's/Description:[\t]//p' | tr " " _)
echo "#########################################################"
echo "This is Version 23beta of the Restore Script"
echo "#########################################################"
echo "Detected Linux Version:"
echo $current_version
echo "#########################################################"
echo "#########################################################"
echo "${bold}CAUTION:${normal} Please be sure to make a backup copy of your current Linux settings first before you use this script!" 
echo "You can use the complimentary backup script called: >>Backup_Linux_Settings<< to perform this task." 
echo "Note that version 10 and above of the restore script is only compatible with version 10 and higher"
echo "of the backup script (e.g., you can not restore a backup made with version 3 or 9 using this script)."  
echo "#########################################################"
echo "#########################################################"
echo "Detected backups of settings in $source."
echo "Please select Distribution to import settings from:"
echo ""

zip_files=$(find "$source" -mindepth 1 -maxdepth 1 -type f -name "*.tar.7zip") # make array of zip files stored in source
options=($zip_files Quit) ## adding quit as additional option
temp_dir="/tmp_dir_4_restore" #we have to make a temp folder, because we don't just want to overwrite all files with tar x but restore selectively.
bold=`tput bold`
normal=`tput sgr0`
saveIFS=$IFS #if we want to restore IFS later one (tells bash what we want to use as separator in arrays)
####
restore_methods=("Complete (${bold}not${normal} recommended)" "Complete, but without /home directory (${bold}not${normal} recommended)" "Preselected setting files and former packages (recommended)" "Preselected setting files and former packages but without /home directory" "Only reinstall former packages" "Only restore Firefox and Thunderbird settings" "Only restore Thunderbird settings" "Only restore Firefox settings" "Only restore fstab" "Only restore desktop links" "Quit") ## array of restoring options
PS3="Please enter selection: "
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
			IFS="" #this tells the shell to recognize that "" separates the different options in the restore_methods array
			select method in ${restore_methods[@]};
			do 
				case $method in
#################################################################################
					"Complete (${bold}not${normal} recommended)") # here we restore everything, this might make problems with incompatible files between distributions
						echo ""
						echo "Will now restore all of Linux old setting files (not recommended)."
						echo "PLEASE CLOSE ALL RUNNING PROGRAMS (such as, e.g., Firefox) !"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 2
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						apt-key add $temp_dir/Installed_Programs/Repo.keys
						cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						apt-get update
						# apt-get install dselect # can activate front end for advanced selections
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get -y update
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring all former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/home/ /
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/ /
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
						echo "Please also note that your fstab has been set back to its former state. If you have meanwhile formated your hard drive be sure to update the UUID in /etc/fstab file."
						echo ""
						###### fstab help
						until [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ] || [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; do
    						read -p "Do you want help with updating the UUID's in old fstab? y=yes, n=no [y/n]:" help_user
							if  [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ]; then
  								echo ""
							elif [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; then
								echo ""
								echo "Please visit https://wiki.archlinux.org/index.php/fstab for detailed help."
								echo ""
  								echo "Here are the UUID's of the currently installed hard drives:"
								echo "================================================================="
								echo ""
								blkid
								sleep 2
								echo ""
								echo "================================================================="
								echo "Opening your /etc/fstab file (please edit accordingly and save the file.)"
								echo "Make sure the UUID's match in your fstab file with the UUID's shown in the terminal."
								sleep 4
								xdg-open /etc/fstab
							else
  								echo -n "Sorry, I do not understand the command $help_user. Please only choose '"'y'"' or '"'n'"'. "
								echo ""
  							fi
						done
						echo ""
						echo "Your former fstab should now be back the way you like it. Please reboot."
						echo ""
						###### end fstab help
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Complete, but without /home directory (${bold}not${normal} recommended)") # here we restore everything, this might make problems with incompatible files between distributions
						echo ""
						echo "Will now restore all of Linux old setting files but not the /home directory (not recommended)."
						echo "PLEASE CLOSE ALL RUNNING PROGRAMS (such as, e.g., Firefox) !"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 2
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						apt-key add $temp_dir/Installed_Programs/Repo.keys
						cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						apt-get update
						# apt-get install dselect # can activate front end for advanced selections
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get -y update
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring all former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/home/ /
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/ /
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
						echo "Please also note that your fstab has been set back to its former state. If you have meanwhile formated your hard drive be sure to update the UUID in /etc/fstab file."
						echo ""
						###### fstab help
						until [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ] || [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; do
    						read -p "Do you want help with updating the UUID's in old fstab? y=yes, n=no [y/n]:" help_user
							if  [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ]; then
  								echo ""
							elif [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; then
								echo ""
								echo "Please visit https://wiki.archlinux.org/index.php/fstab for detailed help."
								echo ""
  								echo "Here are the UUID's of the currently installed hard drives:"
								echo "================================================================="
								echo ""
								blkid
								sleep 2
								echo ""
								echo "================================================================="
								echo "Opening your /etc/fstab file (please edit accordingly and save the file.)"
								echo "Make sure the UUID's match in your fstab file with the UUID's shown in the terminal."
								sleep 4
								xdg-open /etc/fstab
							else
  								echo -n "Sorry, I do not understand the command $help_user. Please only choose '"'y'"' or '"'n'"'. "
								echo ""
  							fi
						done
						echo ""
						echo "Your former fstab should now be back the way you like it. Please reboot."
						echo ""
						###### end fstab help
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Preselected setting files and former packages (recommended)") # here we don't restore everything, just the most important things
						echo ""
						echo "Will now restore only selected setting files (the most important ones)."
						echo "PLEASE CLOSE ALL RUNNING PROGRAMS (such as, e.g., Firefox) !"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 3
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						#apt-key add $temp_dir/Installed_Programs/Repo.keys
						#cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						# apt-get install dselect # can activate front end for advanced selections
						apt-get update
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get -y update
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring only selected former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/home/ /
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.hourly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.daily/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.weekly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.monthly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/cups/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/fonts/ /etc/ # activate if you want to restore fonts settings
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/gnome/ /etc/ # restore file associations
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/opt/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/udisks2/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/bash.bashrc /etc/bash.bashrc #restore old bashrc if edited
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/crontab /etc/crontab
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/fstab /etc/fstab # VERY IMPORTANT LINE USUALLY
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/apt/sources.list /etc/apt/sources.list # some people write this is important (never had impact for me)
						#apt-get update
						#sudo apt-get --yes upgrade # upgrade all packages 
						echo ""
						echo "Preselected settings of your former Linux version have been imported to current distribution."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Now please reboot or restart your X-Server and your former Linux setting should be back to the way you like it."
						echo "Please also note that your fstab has been set back to its former state. If you have meanwhile formated your hard drive be sure to update the UUID in /etc/fstab file."
						echo ""
						###### fstab help
						until [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ] || [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; do
    						read -p "Do you want help with updating the UUID's in old fstab? y=yes, n=no [y/n]:" help_user
							if  [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ]; then
  								echo ""
							elif [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; then
								echo ""
								echo "Please visit https://wiki.archlinux.org/index.php/fstab for detailed help."
								echo ""
  								echo "Here are the UUID's of the currently installed hard drives:"
								echo "================================================================="
								echo ""
								blkid
								sleep 2
								echo ""
								echo "================================================================="
								echo "Opening your /etc/fstab file (please edit accordingly and save the file.)"
								echo "Make sure the UUID's match in your fstab file with the UUID's shown in the terminal."
								sleep 4
								xdg-open /etc/fstab
							else
  								echo -n "Sorry, I do not understand the command $help_user. Please only choose '"'y'"' or '"'n'"'. "
								echo ""
  							fi
						done
						echo ""
						echo "Your former fstab should now be back the way you like it. Please reboot."
						echo ""
						###### end fstab help
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Preselected setting files and former packages but without /home directory") # here we don't restore everything, just the most important things
						echo ""
						echo "Will now restore only selected setting files (the most important ones) but without the /home directory."
						echo ""						
						echo "PLEASE CLOSE ALL RUNNING PROGRAMS (such as, e.g., Firefox) !"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 3
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir "Installed_Programs/" "etc/"
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						#apt-key add $temp_dir/Installed_Programs/Repo.keys
						#cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/
						# apt-get install dselect # can activate front end for advanced selections
						apt-get update
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get -y update
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo "Now transferring only selected former settings to currently installed Linux distribution."
						echo "Note that the owners and rights of the files will be adapted to current files in $current_version."
						sleep 3
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/home/ /
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.hourly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.daily/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.weekly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						cp -rvu --preserve=ownership,timestamps,mode $temp_dir/etc/cron.monthly/ /etc/	#restores old anachron scripts. remove the -u option if you want to overwrte the files that are already there.
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/cups/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/fonts/ /etc/ # activate if you want to restore fonts settings
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/gnome/ /etc/ # restore file associations
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/opt/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/udisks2/ /etc/
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/bash.bashrc /etc/bash.bashrc #restore old bashrc if edited
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/crontab /etc/crontab
						cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/fstab /etc/fstab # VERY IMPORTANT LINE USUALLY
						#cp -rv --preserve=ownership,timestamps,mode $temp_dir/etc/apt/sources.list /etc/apt/sources.list # some people write this is important (never had impact for me)
						#apt-get update
						#sudo apt-get --yes upgrade # upgrade all packages 
						echo ""
						echo "Preselected settings of your former Linux version have been imported to current distribution."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Now please reboot or restart your X-Server and your former Linux setting should be back to the way you like it."
						echo "Please also note that your fstab has been set back to its former state. If you have meanwhile formated your hard drive be sure to update the UUID in /etc/fstab file."
						###### fstab help
						until [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ] || [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; do
    						read -p "Do you want help with updating the UUID's in old fstab? y=yes, n=no [y/n]:" help_user
							if  [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ]; then
  								echo ""
							elif [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; then
								echo ""
								echo "Please visit https://wiki.archlinux.org/index.php/fstab for detailed help."
								echo ""
  								echo "Here are the UUID's of the currently installed hard drives:"
								echo "================================================================="
								echo ""
								blkid
								sleep 2
								echo ""
								echo "================================================================="
								echo "Opening your /etc/fstab file (please edit accordingly and save the file.)"
								echo "Make sure the UUID's match in your fstab file with the UUID's shown in the terminal."
								sleep 4
								xdg-open /etc/fstab
							else
  								echo -n "Sorry, I do not understand the command $help_user. Please only choose '"'y'"' or '"'n'"'. "
								echo ""
  							fi
						done
						echo ""
						echo "Your former fstab should now be back the way you like it. Please reboot."
						echo ""
						###### end fstab help
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Only reinstall former packages") # here we don't restore everything, just reinstall former packages
						echo ""
						echo "Will now restore only former packages."
						echo ""						
						echo "PLEASE CLOSE ALL RUNNING PROGRAMS (such as, e.g., Firefox) !"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						mkdir -p $temp_dir
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						echo ""	
						sleep 3
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir "Installed_Programs/"
						echo "Unzipping complete!"
						echo "Getting back your former software packages."
						sleep 3
						# PUT SCRIPT HERE TO RESTORE PACKAGES
						apt-key add $temp_dir/Installed_Programs/Repo.keys
						#cp -R $temp_dir/Installed_Programs/sources.list* /etc/apt/ #activate to go back to former package repositories
						apt-get update
						# apt-get install dselect # can activate front-end for advanced selections
						dpkg --set-selections < $temp_dir/Installed_Programs/Package.txt
						apt-get -y update
						apt-get dselect-upgrade -y
						#dselect # offers more advanced settings
						echo "...package restore complete"
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Now please reboot or restart your X-Server and your former packages should be back to the way you like it."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Only restore Firefox and Thunderbird settings") # here we don't restore everything, just all settings of Thunderbird (emails and accounts...) and Firefox (bookmarks...) 
						echo ""
						echo "Will now only restore Firefox and Thunderbird settings."
						echo ""
						echo "PLEASE BE SURE THAT BOTH PROGRAMS ARE NOT RUNNING!"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						echo ""	
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						mkdir -p $temp_dir
						echo ""	
						sleep 1
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo ""
						echo "${bold} After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient: ${normal}"
						sleep 1
						7za e $FILENAME -o$temp_dir
						#checking tar file for thunderbird and firefox settings:
						tar_archive_with_backup_path=${FILENAME%.7zip} #strip off the 7zip at the end (%.7zip).
						tar_archive_name=${tar_archive_with_backup_path##*/} #strip off the path from the file
						thunderbird_dirs=$(tar -tvf ""$temp_dir"/"$tar_archive_name"" | grep -Po 'home/.*/.thunderbird/$') #since --wildcards in tar is not implemented correctly (will not keep owners despite -p option), we have to use this trick.
						# tar -tvf --> lists all files and folders in the tar archive
						# grep -Po 'home/.*/.thunderbird/$' --> extracts all lines starting with home and ending with .thunderbird/ (-Po cuts out things infront of home and behind thunderbird/, $ makes sure the line ends with .thunderbird/)
						
						firefox_dirs=$(tar -tvf ""$temp_dir"/"$tar_archive_name"" | grep -Po 'home/.*/.mozilla/$')

						if [ -z "${thunderbird_dirs-unset}" ] && [ -z "${firefox_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Thunderbird nor Firefox settings!"
								echo "Script will now exit, goodbye."
								read -p "Press any key to delete temporary folder and exit." -n1 -s
								rm -R $temp_dir
								exit
					    else
								echo ""
						fi


						if [ -z "${thunderbird_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Thunderbird settings!"
								echo "Will continue but only restore Firefox settings."
								sleep 4
					    else
								echo ""
						fi


						if [ -z "${firefox_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Firefox settings!"
								echo "Will continue but only restore Thunderbird settings."
								sleep 4
					    else
								echo ""
						fi

						##replace spaces with "\ " and End of line with space:
						thunderbird_dirs_NEW=${thunderbird_dirs/" "/"\ "}
						firefox_dirs_NEW=${firefox_dirs/" "/"\ "}
						
						#extracting all of tar, restoring only selection:
						tar xpf ""$temp_dir"/"$tar_archive_name"" -C $temp_dir #we have to extract everything, because extracting selectively does not preserve all owners (bug in tar?)	
						echo "Unzipping complete!"
						echo "Putting your former Thunderbird and Firefox settings back in place."
						sleep 2
						IFS=$'\n'

						for directory in $thunderbird_dirs_NEW ; do # we will use a for loop in case there are multiple users present on the backed up PC.
							echo "Restoring $directory"
							source_path="$temp_dir/$directory" 
							target_path="/${directory%.thunderbird/}"
							echo "source path: $source_path"
							echo "target path: $target_path"
							cp -rv --preserve=timestamps,mode,ownership $source_path $target_path
						done


						for directory in $firefox_dirs_NEW ; do # we will use a for loop in case there are multiple users present on the backed up PC.
							echo "Restoring $directory"
							source_path="$temp_dir/$directory" 
							target_path="/${directory%.mozilla/}"
							echo "source path: $source_path"
							echo "target path: $target_path"
							cp -rv --preserve=timestamps,mode,ownership $source_path $target_path
						done

						IFS=$saveIFS
						echo "...Firefox and Thunderbird settings restore complete."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 2
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Your former Firefox and Thunderbird settings should now be back to the way you like them, if not try rebooting."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
					"Only restore Thunderbird settings") # here we don't restore everything, just all settings of Thunderbird (emails and accounts...)
						echo ""
						echo "Will now only restore Thunderbird settings."
						echo ""
						echo "PLEASE MAKE SURE THAT THUNDERBIRD IS NOT RUNNING!"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						echo ""	
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						mkdir -p $temp_dir
						echo ""	
						sleep 1
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo ""
						echo "${bold} After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient: ${normal}"
						sleep 1
						7za e $FILENAME -o$temp_dir
						#checking tar file for thunderbird settings:
						tar_archive_with_backup_path=${FILENAME%.7zip} #strip off the 7zip at the end (%.7zip).
						tar_archive_name=${tar_archive_with_backup_path##*/} #strip off the path from the file
						thunderbird_dirs=$(tar -tvf ""$temp_dir"/"$tar_archive_name"" | grep -Po 'home/.*/.thunderbird/$') #since --wildcards in tar is not implemented correctly (will not keep owners despite -p option), we have to use this trick.
						# tar -tvf --> lists all files and folders in the tar archive
						# grep -Po 'home/.*/.thunderbird/$' --> extracts all lines starting with home and ending with .thunderbird/ (-Po cuts out things infront of home and behind thunderbird/, $ makes sure the line ends with .thunderbird/)
	
						if [ -z "${thunderbird_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Thunderbird settings!"
								echo "Script will now exit, goodbye."
								read -p "Press any key to delete temporary folder and exit." -n1 -s
								rm -R $temp_dir
								exit
					    else
								echo ""
						fi

						##replace spaces with "\ " and End of line with space:
						thunderbird_dirs_NEW=${thunderbird_dirs/" "/"\ "}
						
						#extracting all of tar, restoring only selection:
						tar xpf ""$temp_dir"/"$tar_archive_name"" -C $temp_dir #we have to extract everything, because extracting selectively does not preserve all owners (bug in tar?)	
						echo "Unzipping complete!"
						echo "Putting your former Thunderbird settings back in place."
						sleep 2
						IFS=$'\n'
						for directory in $thunderbird_dirs_NEW ; do # we will use a for loop in case there are multiple users present on the backed up PC.
							echo "Restoring $directory"
							source_path="$temp_dir/$directory" 
							target_path="/${directory%.thunderbird/}"
							echo "source path: $source_path"
							echo "target path: $target_path"
							cp -rv --preserve=timestamps,mode,ownership $source_path $target_path
						done
						IFS=$saveIFS
						echo "...Thunderbird settings restore complete"
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 2
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Your former Thunderbird settings should now be back to the way you like them, if not try rebooting."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
################################################################################
					"Only restore Firefox settings") # here we don't restore everything, just all settings of Firefox (bookmarks...) 
						echo ""
						echo "Will now only restore Firefox settings."
						echo ""
						echo "PLEASE BE SURE THAT FIREFOX IS NOT RUNNING!"
						echo ""
						read -p "Press any key to continue or close shell to aboard." -n1 -s
						echo ""
						echo ""	
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						mkdir -p $temp_dir
						echo ""	
						sleep 1
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo ""
						echo "${bold} After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient: ${normal}"
						sleep 1
						7za e $FILENAME -o$temp_dir
						#checking tar file for firefox settings:
						tar_archive_with_backup_path=${FILENAME%.7zip} #strip off the 7zip at the end (%.7zip).
						tar_archive_name=${tar_archive_with_backup_path##*/} #strip off the path from the file
						
						firefox_dirs=$(tar -tvf ""$temp_dir"/"$tar_archive_name"" | grep -Po 'home/.*/.mozilla/$') #since --wildcards in tar is not implemented correctly (will not keep owners despite -p option), we have to use this trick.
						# tar -tvf --> lists all files and folders in the tar archive
						# grep -Po 'home/.*/.mozilla/$' --> extracts all lines starting with home and ending with .mozilla/ (-Po cuts out things infront of home and behind mozilla/, $ makes sure the line ends with .mozilla/)


						if [ -z "${firefox_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Firefox settings!"
								read -p "Press any key to delete temporary folder and exit." -n1 -s
								rm -R $temp_dir
								exit
					    else
								echo ""
						fi

						##replace spaces with "\ " and End of line with space:
						firefox_dirs_NEW=${firefox_dirs/" "/"\ "}
						
						#extracting all of tar, restoring only selection:
						tar xpf ""$temp_dir"/"$tar_archive_name"" -C $temp_dir #we have to extract everything, because extracting selectively does not preserve all owners (bug in tar?)	
						echo "Unzipping complete!"
						echo "Putting your former Firefox settings back in place."
						sleep 2

						IFS=$'\n'
						for directory in $firefox_dirs_NEW ; do # we will use a for loop in case there are multiple users present on the backed up PC.
							echo "Restoring $directory"
							source_path="$temp_dir/$directory" 
							target_path="/${directory%.mozilla/}"
							echo "source path: $source_path"
							echo "target path: $target_path"
							cp -rv --preserve=timestamps,mode,ownership $source_path $target_path
						done

						IFS=$saveIFS
						echo "...Firefox settings restore complete."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 2
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Your former Firefox settings should now be back to the way you like them, if not try rebooting."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
################################################################################
					"Only restore fstab") # here we don't restore everything, just the fstab.
						echo ""
						echo "Will now only restore former fstab file."
						echo ""
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						mkdir -p $temp_dir
						echo ""	
						sleep 3
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo "After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient:"
						sleep 3
						7za x -so $FILENAME | tar xpf - -C $temp_dir "etc/fstab"
						echo "Unzipping complete!"
						echo "Putting your former fstab back to /etc folder."
						sleep 3
						#dont worry: we have extracted only the fstab file to $temp_dir. Hence we can restore the complete temporary /etc.
						cp -rv --no-preserve=ownership --preserve=timestamps,mode $temp_dir/etc/ /
						echo "fstab restore complete"
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 3
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "fstab has been set back to its former state. If you have meanwhile formated your hard drive be sure to update the UUID in /etc/fstab file."	
						echo ""					
						###### fstab help
						until [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ] || [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; do
    						read -p "Do you want help with updating the UUID's in old fstab? y=yes, n=no [y/n]:" help_user
							if  [ "$help_user" == "n" ] || [ "$help_user" == "N" ] || [ "$help_user" == "No" ] || [ "$help_user" == "no" ]; then
  								echo ""
							elif [ "$help_user" == "y" ] || [ "$help_user" == "Y" ] || [ "$help_user" == "Yes" ] || [ "$help_user" == "yes" ]; then
								echo ""
								echo "Please visit https://wiki.archlinux.org/index.php/fstab for detailed help."
								echo ""
  								echo "Here are the UUID's of the currently installed hard drives:"
								echo "================================================================="
								echo ""
								blkid
								sleep 2
								echo ""
								echo "================================================================="
								echo "Opening your /etc/fstab file (please edit accordingly and save the file.)"
								echo "Make sure the UUID's match in your fstab file with the UUID's shown in the terminal."
								sleep 4
								xdg-open /etc/fstab
							else
  								echo -n "Sorry, I do not understand the command $help_user. Please only choose '"'y'"' or '"'n'"'. "
								echo ""
  							fi
						done
						echo ""
						echo "Your former fstab should now be back the way you like it. Please reboot."
						echo ""
						###### end fstab help
						read -p "Press any key to continue... " -n1 -s
						echo ""
						;;
################################################################################
					"Only restore desktop links") # here we don't restore everything, just the links of the old desktop.
						echo ""
						echo "Will now only restore desktop links."
						echo ""	
						echo "Generating temporary directory ($temp_dir) for extraction (will be deleted afterwards)"
						mkdir -p $temp_dir
						echo ""	
						sleep 1
						# PUT SCRIPT HERE TO DECOMPRESS
						echo "Unzipping files into that directory." 
						echo ""
						echo "${bold} After entering your password, with which you have encrypted your backup, unzipping can take some time, please be patient: ${normal}"
						sleep 1
						7za e $FILENAME -o$temp_dir
						#checking tar file for desktop settings:
						tar_archive_with_backup_path=${FILENAME%.7zip} #strip off the 7zip at the end (%.7zip).
						tar_archive_name=${tar_archive_with_backup_path##*/} #strip off the path from the file
						desktop_dirs=$(tar -tvf ""$temp_dir"/"$tar_archive_name"" | grep -Po 'home/.*/Desktop/$') #since --wildcards in tar is not implemented correctly (will not keep owners despite -p option), we have to use this trick.
						# tar -tvf --> lists all files and folders in the tar archive
						# grep -Po 'home/.*/Desktop/$' --> extracts all lines starting with home and ending with Desktop/ (-Po cuts out things infront of home and behind Desktop/, $ makes sure the line ends with Desktop/)
	
						if [ -z "${desktop_dirs-unset}" ]; then
								echo ""
								echo "CAUTION: Your backup file >>$tar_archive_name<< does not seem to contain Desktop settings!"
								echo "Script will now exit, goodbye."
								read -p "Press any key to delete temporary folder and exit." -n1 -s
								rm -R $temp_dir
								exit
					    else
								echo ""
						fi

						##replace spaces with "\ " and End of line with space:
						desktop_dirs_NEW=${desktop_dirs/" "/"\ "}
						
						#extracting all of tar, restoring only selection:
						tar xpf ""$temp_dir"/"$tar_archive_name"" -C $temp_dir #we have to extract everything, because extracting selectively does not preserve all owners (bug in tar?)	
						echo "Unzipping complete!"
						echo "Putting your former Desktop settings back in place."
						sleep 2
						IFS=$'\n'
						for directory in $desktop_dirs_NEW ; do # we will use a for loop in case there are multiple users present on the backed up PC.
							echo "Restoring $directory"
							source_path="$temp_dir/$directory" 
							target_path="/${directory%Desktop/}"
							echo "source path: $source_path"
							echo "target path: $target_path"
							cp -rv --preserve=timestamps,mode,ownership $source_path $target_path
						done
						IFS=$saveIFS
						echo "...desktop links restore complete."
						echo ""
						echo "Deleting temporary directory:"
						echo ""
						sleep 2
						rm -R $temp_dir
						echo "Temporary directory ($temp_dir) deleted."
						echo "######################################################################################"
						echo "Your former desktop links should now be back to the way you like them, if not try rebooting."
						echo ""
						read -p "Press any key to continue... " -n1 -s
						echo ""
						exit
						;;
#################################################################################
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
#################################################################################################################
